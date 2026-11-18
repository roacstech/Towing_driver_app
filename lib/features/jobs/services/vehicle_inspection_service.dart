import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';

class VehicleInspectionService {
  static final VehicleInspectionService _instance = VehicleInspectionService._internal();
  factory VehicleInspectionService() => _instance;
  VehicleInspectionService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Required 4 inspection sides
  static const List<String> requiredSides = ['front', 'back', 'left', 'right'];

  static String getSideLabel(String side) {
    switch (side.toLowerCase()) {
      case 'front':
        return 'Front View';
      case 'back':
      case 'rear':
        return 'Rear View';
      case 'left':
        return 'Left (Driver)';
      case 'right':
        return 'Right (Passenger)';
      default:
        return side.toUpperCase();
    }
  }

  /// Get saved S3 photo URLs for a given job
  Future<Map<String, String>> getPhotosForJob(String jobId) async {
    final cleanId = jobId.replaceAll('#', '').trim();
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> photos = {};

    for (final side in requiredSides) {
      final key = 'inspection_${cleanId}_$side';
      final url = prefs.getString(key);
      if (url != null && url.isNotEmpty) {
        photos[side] = url;
      }
    }

    // If local storage is empty, attempt to restore from Cloud Backend Postgres
    if (photos.isEmpty) {
      try {
        final uri = Uri.parse('${ApiConfig.vehiclesEndpoint}?firebase_uid=INSP_$cleanId');
        final res = await http.get(uri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          final list = body['data'] as List?;
          if (list != null && list.isNotEmpty) {
            final v = list.first as Map<String, dynamic>;
            if (v['photo_url'] != null && (v['photo_url'] as String).isNotEmpty) {
              photos['front'] = v['photo_url'];
              await prefs.setString('inspection_${cleanId}_front', v['photo_url']);
            }
            if (v['plate_image_url'] != null && (v['plate_image_url'] as String).isNotEmpty) {
              photos['back'] = v['plate_image_url'];
              await prefs.setString('inspection_${cleanId}_back', v['plate_image_url']);
            }
            if (v['asset_path'] != null && (v['asset_path'] as String).isNotEmpty) {
              photos['left'] = v['asset_path'];
              await prefs.setString('inspection_${cleanId}_left', v['asset_path']);
            }
            if (v['nickname'] != null && (v['nickname'] as String).isNotEmpty) {
              photos['right'] = v['nickname'];
              await prefs.setString('inspection_${cleanId}_right', v['nickname']);
            }
          }
        }
      } catch (_) {}
    }

    return photos;
  }

  /// Check whether all 4 required sides are captured and uploaded
  Future<bool> isInspectionComplete(String jobId) async {
    final photos = await getPhotosForJob(jobId);
    return requiredSides.every((side) => photos.containsKey(side) && photos[side]!.isNotEmpty);
  }

  /// Capture image from camera, convert to base64, and upload directly to AWS S3
  Future<String?> captureAndUploadSide({
    required String jobId,
    required String side,
    ImageSource source = ImageSource.camera,
  }) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 960,
        imageQuality: 82,
      );

      if (picked == null) return null;

      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final cleanId = jobId.replaceAll('#', '').trim();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'inspection_${cleanId}_${side}_$timestamp.jpg';

      debugPrint('📸 [Inspection] Uploading $side photo to AWS S3 for Job $cleanId...');

      // 1. Upload to AWS S3 via backend S3 upload endpoint
      final uploadUri = Uri.parse(ApiConfig.vehicleUploadEndpoint);
      final response = await http
          .post(
            uploadUri,
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'base64': base64String,
              'filename': filename,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('❌ [Inspection] S3 upload returned status ${response.statusCode}: ${response.body}');
        return null;
      }

      final body = jsonDecode(response.body);
      final s3Url = body['s3_url'] as String? ?? body['path'] as String?;

      if (s3Url == null || s3Url.isEmpty) {
        debugPrint('❌ [Inspection] S3 upload succeeded but no s3_url returned: ${response.body}');
        return null;
      }

      debugPrint('✅ [Inspection] Successfully uploaded $side photo to S3: $s3Url');

      // 2. Persist locally on device
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('inspection_${cleanId}_$side', s3Url);

      // 3. Sync to Admin Order Details
      await syncInspectionPhotosToAdmin(jobId);

      return s3Url;
    } catch (e) {
      debugPrint('❌ [Inspection] Exception during photo capture/upload: $e');
      return null;
    }
  }

  /// Sync all 4 S3 URLs to the central admin portal and backend
  Future<void> syncInspectionPhotosToAdmin(String jobId) async {
    try {
      final cleanId = jobId.replaceAll('#', '').trim();
      final photos = await getPhotosForJob(jobId);

      // 1. Primary: Persist to Cloud Backend Postgres vehicles table
      try {
        final vehicleUri = Uri.parse(ApiConfig.vehiclesEndpoint);
        await http
            .post(
              vehicleUri,
              headers: {'content-type': 'application/json'},
              body: jsonEncode({
                'firebase_uid': 'INSP_$cleanId',
                'make': 'Pre-Tow Inspection',
                'model': cleanId,
                'year': 2026,
                'license_plate': cleanId,
                'photo_url': photos['front'] ?? '',
                'plate_image_url': photos['back'] ?? photos['rear'] ?? '',
                'asset_path': photos['left'] ?? '',
                'nickname': photos['right'] ?? '',
              }),
            )
            .timeout(const Duration(seconds: 5));
        debugPrint('✅ [Inspection] Successfully synced photos to Cloud Postgres for $cleanId');
      } catch (e) {
        debugPrint('⚠️ [Inspection] Cloud vehicles sync error: $e');
      }

      // 2. Secondary: Sync directly to Admin portal if reachable (LAN, Emulator, or Localhost)
      final payload = {
        'job_id': cleanId,
        'inspection_photos': photos,
        'uploaded_at': DateTime.now().toIso8601String(),
        'is_complete': requiredSides.every((s) => photos.containsKey(s)),
      };

      final adminUrls = [
        'http://192.168.1.35:3000/api/tows/$cleanId/inspection-photos',
        'http://10.0.2.2:3000/api/tows/$cleanId/inspection-photos',
        'http://localhost:3000/api/tows/$cleanId/inspection-photos',
      ];

      for (final url in adminUrls) {
        try {
          await http
              .post(
                Uri.parse(url),
                headers: {'content-type': 'application/json'},
                body: jsonEncode(payload),
              )
              .timeout(const Duration(seconds: 2));
        } catch (_) {}
      }
    } catch (_) {}
  }
}
