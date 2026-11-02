import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../profile/models/driver_profile.dart';
import '../models/tow_job.dart';

class DriverJobService {
  static final DriverJobService _instance = DriverJobService._internal();
  factory DriverJobService() => _instance;
  DriverJobService._internal();

  final ValueNotifier<DriverProfile> driverNotifier =
      ValueNotifier<DriverProfile>(DriverProfile.mockDriver);

  // Available list of requests for the card stack and 'See All' list (real requests from backend only)
  final ValueNotifier<List<TowJob>> availableRequestsNotifier =
      ValueNotifier<List<TowJob>>([]);

  // The currently focused/selected request card (syncs with the top map's route polyline)
  final ValueNotifier<TowJob?> selectedRequestNotifier =
      ValueNotifier<TowJob?>(null);

  final ValueNotifier<TowJob?> activeJobNotifier = ValueNotifier<TowJob?>(null);
  final ValueNotifier<TowJob?> pendingRequestNotifier = ValueNotifier<TowJob?>(null);
  final ValueNotifier<List<TowJob>> completedJobsNotifier =
      ValueNotifier<List<TowJob>>([]);

  // Driver live location notifier (defaults to Coimbatore hub: 11.1389, 77.0325)
  final ValueNotifier<LatLng> driverLocationNotifier =
      ValueNotifier<LatLng>(const LatLng(11.1389, 77.0325));
  double driverHeading = 45.0;

  DriverProfile get driver => driverNotifier.value;
  List<TowJob> get availableRequests => availableRequestsNotifier.value;
  TowJob? get selectedRequest => selectedRequestNotifier.value;
  TowJob? get activeJob => activeJobNotifier.value;
  TowJob? get pendingRequest => pendingRequestNotifier.value;
  List<TowJob> get completedJobs => completedJobsNotifier.value;
  LatLng get currentDriverLocation => driverLocationNotifier.value;

  Timer? _pollingTimer;
  Timer? _initialCheckTimer;
  Timer? _activeTrackingTimer;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isOnline = prefs.getBool('driver_is_online') ?? true;
      driverNotifier.value = driver.copyWith(isOnline: isOnline);
    } catch (_) {}

    await updateDriverGpsLocation();

    // Ensure selected request defaults to first available
    if (availableRequests.isNotEmpty) {
      selectedRequestNotifier.value = availableRequests.first;
    } else {
      selectedRequestNotifier.value = null;
    }

    if (driver.isOnline) {
      startDispatchPolling();
    }
  }

  /// Obtains current GPS coordinates of the tow truck driver
  Future<void> updateDriverGpsLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        ),
      );

      driverLocationNotifier.value = LatLng(position.latitude, position.longitude);
      if (position.heading != 0.0) {
        driverHeading = position.heading;
      }
    } catch (_) {
      // Retain current position if GPS call fails or running in headless/mock environment
    }
  }

  void selectRequest(TowJob job) {
    selectedRequestNotifier.value = job;
  }

  void toggleOnlineStatus(bool online) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('driver_is_online', online);
    } catch (_) {}

    driverNotifier.value = driver.copyWith(isOnline: online);

    if (online) {
      startDispatchPolling();
    } else {
      stopDispatchPolling();
      pendingRequestNotifier.value = null;
    }
  }

  void startDispatchPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (driver.isOnline && activeJob == null) {
        checkBackendForPendingJobs();
      }
    });

    if (activeJob == null) {
      _initialCheckTimer?.cancel();
      _initialCheckTimer = Timer(const Duration(milliseconds: 500), () {
        checkBackendForPendingJobs();
      });
    }
  }

  void stopDispatchPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _initialCheckTimer?.cancel();
    _initialCheckTimer = null;
  }

  /// Checks shared PostgreSQL / REST backend for new tows created by Customer App
  Future<void> checkBackendForPendingJobs() async {
    try {
      await updateDriverGpsLocation();
      final lat = driverLocationNotifier.value.latitude;
      final lng = driverLocationNotifier.value.longitude;

      final List<dynamic> rawJobsList = [];

      // 1. Primary driver dispatch query with driver credentials
      try {
        final uri = Uri.parse(
          '${ApiConfig.towsEndpoint}?for_drivers=true&role=driver&firebase_uid=DRV-${driver.id}&driver_id=DRV-${driver.id}&driver_lat=$lat&driver_lng=$lng',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['success'] == true && body['data'] is List) {
            rawJobsList.addAll(body['data']);
          }
        }
      } catch (_) {}

      // 2. Dispatch queue fallback query
      try {
        final dispatchUri = Uri.parse('${ApiConfig.towsEndpoint}?firebase_uid=dispatch_queue');
        final dispatchRes = await http.get(dispatchUri).timeout(const Duration(seconds: 3));
        if (dispatchRes.statusCode == 200) {
          final body = jsonDecode(dispatchRes.body);
          if (body['success'] == true && body['data'] is List) {
            for (final item in body['data']) {
              if (item is Map && !rawJobsList.any((x) => x['id'] == item['id'])) {
                rawJobsList.add(item);
              }
            }
          }
        }
      } catch (_) {}

      if (rawJobsList.isNotEmpty) {
        final activeOrPending = rawJobsList
            .map((j) => TowJob.fromJson(j as Map<String, dynamic>))
            .where((t) => t.status == JobStatus.pending || t.status == JobStatus.accepted)
            .toList();

        if (activeOrPending.isNotEmpty) {
          // Merge into available if not already present
          final current = List<TowJob>.from(availableRequestsNotifier.value);
          bool hasChange = false;
          for (final incoming in activeOrPending) {
            final idx = current.indexWhere((e) => e.id == incoming.id);
            if (idx == -1) {
              // New incoming customer request! Place at top of queue
              current.insert(0, incoming);
              hasChange = true;
            } else {
              // Update customer live location if updated
              if (current[idx].effectiveCustomerLat != incoming.effectiveCustomerLat ||
                  current[idx].effectiveCustomerLng != incoming.effectiveCustomerLng) {
                current[idx] = incoming;
                hasChange = true;
              }
            }
          }
          if (hasChange) {
            availableRequestsNotifier.value = current;
            if (selectedRequest == null && current.isNotEmpty) {
              selectedRequestNotifier.value = current.first;
            }
          }
        }
      }
    } catch (_) {
      // Backend is offline or network error
    }
  }

  /// Driver accepts a job request (via right-swipe or explicit Accept button)
  Future<void> acceptJob(TowJob job) async {
    await updateDriverGpsLocation();
    var currentPos = driverLocationNotifier.value;

    // Proximity check: If driver GPS is far from pickup (> 150 miles, e.g. simulator default in US),
    // set driver to ~0.8 miles from customer pickup so live map stays local and realistic.
    final distMiles = const Distance().as(LengthUnit.Mile, currentPos, LatLng(job.pickupLat, job.pickupLng));
    if (distMiles > 150) {
      currentPos = LatLng(job.pickupLat - 0.008, job.pickupLng - 0.006);
      driverLocationNotifier.value = currentPos;
    }

    final acceptedJob = job.copyWith(
      status: JobStatus.accepted,
      driverLat: currentPos.latitude,
      driverLng: currentPos.longitude,
      driverHeading: driverHeading,
    );
    activeJobNotifier.value = acceptedJob;
    pendingRequestNotifier.value = null;

    // Remove from available requests
    final updatedList = List<TowJob>.from(availableRequestsNotifier.value)
      ..removeWhere((j) => j.id == job.id);
    availableRequestsNotifier.value = updatedList;

    // Update selected request to next available
    if (updatedList.isNotEmpty) {
      selectedRequestNotifier.value = updatedList.first;
    } else {
      selectedRequestNotifier.value = null;
    }

    // Notify backend that driver accepted the job, sending driver live details & GPS
    final safeJobId = Uri.encodeComponent(job.id.trim());
    try {
      final uri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId/accept');
      final res = await http.put(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'driver_id': 'DRV-${driver.id}',
          'driver_name': driver.name,
          'driver_phone': driver.phone,
          'driver_rating': driver.rating,
          'tow_truck_info': '${driver.truckModel} (${driver.licensePlate})',
          'driver_lat': currentPos.latitude,
          'driver_lng': currentPos.longitude,
          'driver_heading': driverHeading,
          'eta_or_duration': acceptedJob.pickupEta,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode != 200) {
        // Fallback for deployed status endpoint
        final statusUri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId/status');
        await http.put(
          statusUri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'status': 'active',
            'driver_id': 'DRV-${driver.id}',
            'driver_name': driver.name,
            'driver_phone': driver.phone,
            'driver_rating': driver.rating,
            'tow_truck_info': '${driver.truckModel} (${driver.licensePlate})',
            'driver_lat': currentPos.latitude,
            'driver_lng': currentPos.longitude,
            'driver_heading': driverHeading,
          }),
        ).timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

    // Start live tracking synchronization loop
    _startActiveJobTracking(job.id);
  }

  /// Live tracking loop: broadcasts driver's real-time GPS and retrieves customer's live GPS
  void _startActiveJobTracking(String jobId) {
    _activeTrackingTimer?.cancel();
    final safeJobId = Uri.encodeComponent(jobId.trim());

    _activeTrackingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final current = activeJob;
      if (current == null || current.id != jobId) {
        _activeTrackingTimer?.cancel();
        return;
      }

      await updateDriverGpsLocation();
      var currentPos = driverLocationNotifier.value;
      final distMiles = const Distance().as(LengthUnit.Mile, currentPos, LatLng(current.pickupLat, current.pickupLng));
      if (distMiles > 150) {
        currentPos = LatLng(current.pickupLat - 0.008, current.pickupLng - 0.006);
        driverLocationNotifier.value = currentPos;
      }

      // 1. Push driver's live GPS location to backend
      try {
        final pushUri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId/driver-location');
        await http.put(
          pushUri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'driver_lat': currentPos.latitude,
            'driver_lng': currentPos.longitude,
            'driver_heading': driverHeading,
            'status': current.status.name,
          }),
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}

      // 2. Poll backend for customer's live location updates
      try {
        final getUri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId?for_drivers=true');
        final res = await http.get(getUri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['success'] == true && body['data'] is Map<String, dynamic>) {
            final towData = body['data'] as Map<String, dynamic>;
            final updatedFromBackend = TowJob.fromJson(towData);

            final custLat = (towData['customer_lat'] as num?)?.toDouble() ?? updatedFromBackend.pickupLat;
            final custLng = (towData['customer_lng'] as num?)?.toDouble() ?? updatedFromBackend.pickupLng;

            activeJobNotifier.value = current.copyWith(
              customerLat: custLat,
              customerLng: custLng,
              driverLat: currentPos.latitude,
              driverLng: currentPos.longitude,
              driverHeading: driverHeading,
            );
          }
        }
      } catch (_) {}
    });
  }

  /// Driver declines/rejects a job request (via left-swipe or explicit Decline button)
  void declineJob(TowJob job) {
    final updatedList = List<TowJob>.from(availableRequestsNotifier.value)
      ..removeWhere((j) => j.id == job.id);
    availableRequestsNotifier.value = updatedList;

    if (selectedRequest?.id == job.id) {
      selectedRequestNotifier.value = updatedList.isNotEmpty ? updatedList.first : null;
    }
  }

  /// Clears available requests
  void resetDemoRequests() {
    availableRequestsNotifier.value = [];
    selectedRequestNotifier.value = null;
  }

  Future<void> advanceJobStage() async {
    final current = activeJob;
    if (current == null) return;

    JobStatus nextStatus;
    switch (current.status) {
      case JobStatus.pending:
      case JobStatus.accepted:
        nextStatus = JobStatus.arrived;
        break;
      case JobStatus.arrived:
        nextStatus = JobStatus.towing;
        break;
      case JobStatus.towing:
        nextStatus = JobStatus.completed;
        break;
      case JobStatus.completed:
      case JobStatus.cancelled:
        return;
    }

    if (nextStatus == JobStatus.completed) {
      await _completeJob(current);
    } else {
      final updated = current.copyWith(status: nextStatus);
      activeJobNotifier.value = updated;

      try {
        final uri = Uri.parse('${ApiConfig.towsEndpoint}/${current.id}/status');
        await http.put(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'status': nextStatus.name}),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
  }

  Future<void> _completeJob(TowJob job) async {
    _activeTrackingTimer?.cancel();
    _activeTrackingTimer = null;

    final completed = job.copyWith(status: JobStatus.completed);
    final currentList = List<TowJob>.from(completedJobsNotifier.value);
    currentList.insert(0, completed);
    completedJobsNotifier.value = currentList;

    final earned = job.estimatedPayout;
    driverNotifier.value = driver.copyWith(
      todayEarnings: driver.todayEarnings + earned,
      totalTows: driver.totalTows + 1,
    );

    activeJobNotifier.value = null;

    try {
      final uri = Uri.parse('${ApiConfig.towsEndpoint}/${job.id}/status');
      await http.put(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'status': 'completed'}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }
}
