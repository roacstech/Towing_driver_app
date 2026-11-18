import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/driver_colors.dart';
import '../services/vehicle_inspection_service.dart';

class VehicleInspectionCard extends StatefulWidget {
  final String jobId;
  final ValueChanged<bool> onInspectionStatusChanged;

  const VehicleInspectionCard({
    super.key,
    required this.jobId,
    required this.onInspectionStatusChanged,
  });

  @override
  State<VehicleInspectionCard> createState() => _VehicleInspectionCardState();
}

class _VehicleInspectionCardState extends State<VehicleInspectionCard> {
  final Map<String, String> _uploadedPhotos = {};
  final Set<String> _uploadingSides = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingPhotos();
  }

  Future<void> _loadExistingPhotos() async {
    final photos = await VehicleInspectionService().getPhotosForJob(widget.jobId);
    if (mounted) {
      setState(() {
        _uploadedPhotos.addAll(photos);
        _isLoading = false;
      });
      _notifyStatus();
    }
  }

  void _notifyStatus() {
    final isComplete = VehicleInspectionService.requiredSides.every(
      (s) => _uploadedPhotos.containsKey(s) && _uploadedPhotos[s]!.isNotEmpty,
    );
    widget.onInspectionStatusChanged(isComplete);
  }

  Future<void> _handleCapture(String side) async {
    // Show option to take photo with camera or choose from gallery
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Capture ${VehicleInspectionService.getSideLabel(side)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DriverColors.navy900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ensure the car body, bumper, and panels are clearly visible.',
                style: TextStyle(fontSize: 12.5, color: DriverColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DriverColors.electricBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: DriverColors.electricBlue),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DriverColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: DriverColors.textSecondary),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    setState(() {
      _uploadingSides.add(side);
    });

    final s3Url = await VehicleInspectionService().captureAndUploadSide(
      jobId: widget.jobId,
      side: side,
      source: source,
    );

    if (mounted) {
      setState(() {
        _uploadingSides.remove(side);
        if (s3Url != null) {
          _uploadedPhotos[side] = s3Url;
        }
      });
      _notifyStatus();

      if (s3Url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${VehicleInspectionService.getSideLabel(side)} photo captured & uploaded!'),
                ),
              ],
            ),
            backgroundColor: DriverColors.emeraldDark,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final totalCount = VehicleInspectionService.requiredSides.length;
    final completedCount = VehicleInspectionService.requiredSides
        .where((s) => _uploadedPhotos.containsKey(s) && _uploadedPhotos[s]!.isNotEmpty)
        .length;
    final isAllDone = completedCount == totalCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAllDone ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAllDone ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAllDone
                      ? const Color(0xFFDCFCE7)
                      : DriverColors.electricBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAllDone ? Icons.check_circle_rounded : Icons.photo_camera_rounded,
                  color: isAllDone ? const Color(0xFF16A34A) : DriverColors.electricBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mandatory Vehicle Inspection',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: DriverColors.navy900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAllDone
                          ? 'All 4 sides verified. Ready to hook.'
                          : 'Photograph 4 sides of the car before hooking.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAllDone ? const Color(0xFF15803D) : DriverColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isAllDone ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount/$totalCount Done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2x2 Grid of 4 Sides
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              _buildSideTile('front', Icons.directions_car_rounded),
              _buildSideTile('back', Icons.car_crash_rounded),
              _buildSideTile('left', Icons.swap_horiz_rounded),
              _buildSideTile('right', Icons.compare_arrows_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideTile(String side, IconData icon) {
    final s3Url = _uploadedPhotos[side];
    final isUploading = _uploadingSides.contains(side);
    final hasPhoto = s3Url != null && s3Url.isNotEmpty;
    final label = VehicleInspectionService.getSideLabel(side);

    return InkWell(
      onTap: isUploading ? null : () => _handleCapture(side),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasPhoto ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasPhoto
                ? const Color(0xFF22C55E)
                : (isUploading ? DriverColors.electricBlue : const Color(0xFFCBD5E1)),
            width: hasPhoto ? 1.5 : 1.2,
          ),
        ),
        child: isUploading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Uploading...',
                      style: TextStyle(fontSize: 10.5, color: DriverColors.electricBlue, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            : hasPhoto
                ? Stack(
                    children: [
                      // Image Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          s3Url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey, size: 28),
                          ),
                        ),
                      ),
                      // Top Green Check Badge
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 10),
                              SizedBox(width: 3),
                              Text('Done', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      // Bottom Label Pill
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_a_photo_rounded, size: 18, color: DriverColors.textSecondary),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: DriverColors.navy900,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Tap to capture',
                        style: TextStyle(fontSize: 9.5, color: DriverColors.textMuted),
                      ),
                    ],
                  ),
      ),
    );
  }
}
