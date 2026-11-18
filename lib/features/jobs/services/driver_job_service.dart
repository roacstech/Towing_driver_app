import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/driver_sound_service.dart';
import '../../profile/models/driver_profile.dart';
import '../models/tow_job.dart';

class DriverJobService {
  static final DriverJobService _instance = DriverJobService._internal();
  factory DriverJobService() => _instance;
  DriverJobService._internal();

  final ValueNotifier<DriverProfile> driverNotifier =
      ValueNotifier<DriverProfile>(DriverProfile.mockDriver);

  // Available list of requests for the card stack (strictly one-by-one sequential offer)
  final ValueNotifier<List<TowJob>> availableRequestsNotifier =
      ValueNotifier<List<TowJob>>([]);

  // The currently focused/selected request card (syncs with the top map's route polyline)
  final ValueNotifier<TowJob?> selectedRequestNotifier =
      ValueNotifier<TowJob?>(null);

  // Active incoming offer with 10-second countdown and continuous alert ringing
  final ValueNotifier<TowJob?> currentIncomingOfferNotifier =
      ValueNotifier<TowJob?>(null);
  final ValueNotifier<int> offerCountdownSecondsNotifier =
      ValueNotifier<int>(10);
  final ValueNotifier<double> offerTimerProgressNotifier =
      ValueNotifier<double>(1.0);

  final ValueNotifier<TowJob?> activeJobNotifier = ValueNotifier<TowJob?>(null);
  final ValueNotifier<TowJob?> pendingRequestNotifier = ValueNotifier<TowJob?>(null);
  final ValueNotifier<List<TowJob>> completedJobsNotifier =
      ValueNotifier<List<TowJob>>([]);

  // Emits when a customer cancels an active or dispatched job
  final ValueNotifier<TowJob?> customerCancelledJobNotifier =
      ValueNotifier<TowJob?>(null);

  void clearCustomerCancellation() {
    customerCancelledJobNotifier.value = null;
  }

  // Driver live location notifier (defaults to Coimbatore hub: 11.1389, 77.0325)
  final ValueNotifier<LatLng> driverLocationNotifier =
      ValueNotifier<LatLng>(const LatLng(11.1389, 77.0325));
  double driverHeading = 45.0;

  DriverProfile get driver => driverNotifier.value;
  List<TowJob> get availableRequests => availableRequestsNotifier.value;
  TowJob? get selectedRequest => selectedRequestNotifier.value;
  TowJob? get currentIncomingOffer => currentIncomingOfferNotifier.value;
  TowJob? get activeJob => activeJobNotifier.value;
  TowJob? get pendingRequest => pendingRequestNotifier.value;
  List<TowJob> get completedJobs => completedJobsNotifier.value;
  LatLng get currentDriverLocation => driverLocationNotifier.value;

  Timer? _pollingTimer;
  Timer? _initialCheckTimer;
  Timer? _activeTrackingTimer;
  Timer? _offerCountdownTimer;
  Timer? _cooldownCheckTimer;
  int _remainingOfferMs = 10000;

  final Set<String> _cancelledJobIds = <String>{};
  final Set<String> _completedJobIds = <String>{};
  final Map<String, int> _jobPassCounts = <String, int>{};
  final Map<String, DateTime> _jobCooldownUntil = <String, DateTime>{};
  final Set<String> _declinedJobIds = <String>{};
  List<TowJob> _cachedPendingJobs = <TowJob>[];
  int _lastHeartbeatMs = 0;

  Future<void> _sendDriverHeartbeat(double lat, double lng, {bool isOnline = true}) async {
    try {
      final profileUri = Uri.parse(ApiConfig.profileEndpoint);
      await http.put(
        profileUri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': driver.email,
          'name': driver.name,
          'role': 'driver',
          'current_lat': lat,
          'current_lng': lng,
          'is_online': isOnline,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isOnline = prefs.getBool('driver_is_online') ?? true;
      final savedName = prefs.getString('driver_saved_name');
      final savedPhone = prefs.getString('driver_saved_phone');
      final savedTruck = prefs.getString('driver_saved_truck');
      final savedPlate = prefs.getString('driver_saved_plate');
      final savedEarnings = prefs.getDouble('driver_today_earnings');
      final savedTows = prefs.getInt('driver_total_tows');

      final savedCompleted = prefs.getStringList('driver_completed_job_ids');
      if (savedCompleted != null) {
        _completedJobIds.addAll(savedCompleted);
      }

      driverNotifier.value = driver.copyWith(
        name: (savedName != null && savedName.trim().isNotEmpty) ? savedName.trim() : driver.name,
        phone: (savedPhone != null && savedPhone.trim().isNotEmpty) ? savedPhone.trim() : driver.phone,
        truckModel: (savedTruck != null && savedTruck.trim().isNotEmpty) ? savedTruck.trim() : driver.truckModel,
        licensePlate: (savedPlate != null && savedPlate.trim().isNotEmpty) ? savedPlate.trim() : driver.licensePlate,
        todayEarnings: savedEarnings ?? driver.todayEarnings,
        totalTows: savedTows ?? driver.totalTows,
        isOnline: isOnline,
      );
    } catch (_) {}

    await updateDriverGpsLocation();

    // Ensure requests start strictly empty (no mock or stale data)
    availableRequestsNotifier.value = [];
    selectedRequestNotifier.value = null;
    currentIncomingOfferNotifier.value = null;
    activeJobNotifier.value = null;

    if (driver.isOnline) {
      startDispatchPolling();
    }
  }

  Future<void> _saveCompletedJobIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('driver_completed_job_ids', _completedJobIds.toList());
    } catch (_) {}
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

    // Broadcast online status to backend immediately
    final pos = driverLocationNotifier.value;
    _sendDriverHeartbeat(pos.latitude, pos.longitude, isOnline: online);

    if (online) {
      startDispatchPolling();
    } else {
      stopDispatchPolling();
      pendingRequestNotifier.value = null;
    }
  }

  void startDispatchPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (driver.isOnline && activeJob == null) {
        checkBackendForPendingJobs();
      }
    });

    if (activeJob == null) {
      _initialCheckTimer?.cancel();
      _initialCheckTimer = Timer(const Duration(milliseconds: 300), () {
        checkBackendForPendingJobs();
      });
    }
  }

  void stopDispatchPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _initialCheckTimer?.cancel();
    _initialCheckTimer = null;
    _cooldownCheckTimer?.cancel();
    _cooldownCheckTimer = null;
    _stopCurrentOffer();
  }

  /// Checks shared PostgreSQL / REST backend for new tows created by Customer App
  Future<void> checkBackendForPendingJobs() async {
    try {
      await updateDriverGpsLocation();
      final lat = driverLocationNotifier.value.latitude;
      final lng = driverLocationNotifier.value.longitude;

      // Broadcast periodic standby heartbeat (every 12s) to keep driver online and GPS live on Admin map
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - _lastHeartbeatMs > 12000) {
        _lastHeartbeatMs = nowMs;
        _sendDriverHeartbeat(lat, lng, isOnline: true);
      }

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
        final now = DateTime.now();
        final allJobs = rawJobsList
            .map((j) => TowJob.fromJson(j as Map<String, dynamic>))
            .toList();

        // 3. Check if current active job was completed or cancelled on backend
        if (activeJob != null) {
          final current = activeJob!;
          final cleanCurrentId = current.id.replaceAll('#', '').trim();
          final matchingJob = allJobs.cast<TowJob?>().firstWhere(
            (j) => j != null && j.id.replaceAll('#', '').trim() == cleanCurrentId,
            orElse: () => null,
          );

          if (matchingJob != null) {
            if (matchingJob.status == JobStatus.completed) {
              debugPrint('🏁 [DriverJobService] Active job $cleanCurrentId completed in backend. Clearing active job.');
              _activeTrackingTimer?.cancel();
              _activeTrackingTimer = null;
              _completedJobIds.add(cleanCurrentId);
              _completedJobIds.add(current.id);
              _completedJobIds.add('#$cleanCurrentId');
              _saveCompletedJobIds();

              final completedList = List<TowJob>.from(completedJobsNotifier.value);
              if (!completedList.any((c) => c.id.replaceAll('#', '').trim() == cleanCurrentId)) {
                completedList.insert(0, matchingJob);
                completedJobsNotifier.value = completedList;
              }

              activeJobNotifier.value = null;
            } else if (matchingJob.status == JobStatus.cancelled) {
              debugPrint('🚨 [DriverJobService] Active job $cleanCurrentId cancelled in backend.');
              _activeTrackingTimer?.cancel();
              _activeTrackingTimer = null;
              _cancelledJobIds.add(cleanCurrentId);
              _cancelledJobIds.add(current.id);
              _cancelledJobIds.add('#$cleanCurrentId');

              final cancelledJob = matchingJob.copyWith(
                status: JobStatus.cancelled,
                customerName: matchingJob.customerName.isNotEmpty
                    ? matchingJob.customerName
                    : current.customerName,
                vehicleName: matchingJob.vehicleName.isNotEmpty
                    ? matchingJob.vehicleName
                    : current.vehicleName,
              );
              customerCancelledJobNotifier.value = cancelledJob;
              activeJobNotifier.value = null;
            }
          }
        }

        // 4. Check if a recent fresh active job was assigned directly by admin to this driver
        if (activeJob == null && driver.isOnline) {
          final driverNameLower = driver.name.toLowerCase().trim();
          final adminAssignedMatch = allJobs.cast<TowJob?>().firstWhere(
            (j) {
              if (j == null) return false;
              final cleanId = j.id.replaceAll('#', '').trim();
              if (_completedJobIds.contains(cleanId) ||
                  _completedJobIds.contains(j.id) ||
                  _cancelledJobIds.contains(cleanId) ||
                  _declinedJobIds.contains(cleanId)) {
                return false;
              }
              // STRICT: Never pick up completed or cancelled orders!
              if (j.status == JobStatus.completed || j.status == JobStatus.cancelled) {
                return false;
              }
              // STRICT: Only consider fresh dispatches from the last 30 minutes
              if (now.difference(j.createdAt).inMinutes.abs() > 30) {
                return false;
              }
              if (j.driverName == null || j.driverName!.trim().isEmpty) {
                return false;
              }
              final matchDriver = j.driverName!.toLowerCase().contains(driverNameLower) ||
                  driverNameLower.contains(j.driverName!.toLowerCase());
              final isActiveStatus = j.status == JobStatus.accepted ||
                  j.status == JobStatus.arrived ||
                  j.status == JobStatus.towing;
              return matchDriver && isActiveStatus;
            },
            orElse: () => null,
          );

          if (adminAssignedMatch != null) {
            final cleanId = adminAssignedMatch.id.replaceAll('#', '').trim();
            if (!_completedJobIds.contains(cleanId)) {
              debugPrint('🎯 [DriverJobService] Found recent admin-assigned tow: ${adminAssignedMatch.id}');
              _stopCurrentOffer();
              activeJobNotifier.value = adminAssignedMatch;
              _startActiveJobTracking(adminAssignedMatch.id);
              return;
            }
          }
        }

        // 5. Only show truly pending / unassigned customer dispatches created recently (within last 60 mins)
        final pendingJobs = allJobs.where((t) {
          final cleanId = t.id.replaceAll('#', '').trim();
          final isPending = t.status == JobStatus.pending;
          final isUnassigned = t.driverName == null ||
              t.driverName!.trim().isEmpty ||
              t.driverName!.toLowerCase() == 'unassigned';
          final notCurrentActive = activeJob == null || activeJob!.id != t.id;
          final notCompleted = !_completedJobIds.contains(cleanId) &&
              !completedJobsNotifier.value.any((c) => c.id.replaceAll('#', '').trim() == cleanId);
          final notCancelled = !_cancelledJobIds.contains(t.id) &&
              !_cancelledJobIds.contains(cleanId);
          final notDeclinedMax = !_declinedJobIds.contains(t.id) &&
              !_declinedJobIds.contains(cleanId);
          final isRecent = now.difference(t.createdAt).inMinutes.abs() < 60;
          return isPending &&
              isUnassigned &&
              notCurrentActive &&
              notCompleted &&
              notCancelled &&
              notDeclinedMax &&
              isRecent;
        }).toList();

        _cachedPendingJobs = pendingJobs;
        _evaluatePendingQueue();
      } else {
        // Backend has 0 pending requests: ensure no stale cards or cached jobs are displayed
        _cachedPendingJobs = [];
        _stopCurrentOffer();
        availableRequestsNotifier.value = [];
        selectedRequestNotifier.value = null;
      }
    } catch (_) {
      // Backend is offline or network error
    }
  }

  /// Sequential one-by-one dispatch dispatcher with 5-10s timer and automatic fallbacks
  void _evaluatePendingQueue() {
    if (!driver.isOnline || activeJob != null) {
      _stopCurrentOffer();
      availableRequestsNotifier.value = [];
      selectedRequestNotifier.value = null;
      return;
    }

    // If an offer is currently ongoing:
    if (currentIncomingOfferNotifier.value != null) {
      final currentId = currentIncomingOfferNotifier.value!.id.replaceAll('#', '').trim();
      final stillExists = _cachedPendingJobs.any(
        (j) => j.id.replaceAll('#', '').trim() == currentId,
      );
      if (!stillExists) {
        // Job was taken by someone else or cancelled by customer
        _stopCurrentOffer();
      } else {
        // Continue existing active offer countdown & ringing
        return;
      }
    }

    final now = DateTime.now();

    // 1. Look for jobs that are eligible right now (cooldown has passed)
    final readyJobs = _cachedPendingJobs.where((j) {
      final cleanId = j.id.replaceAll('#', '').trim();
      final cd = _jobCooldownUntil[cleanId];
      return cd == null || !now.isBefore(cd);
    }).toList();

    if (readyJobs.isNotEmpty) {
      final nextJob = readyJobs.first;
      _startIncomingOffer(nextJob);
      return;
    }

    // 2. Fallback to same online driver:
    // If all pending jobs are currently on cooldown (e.g., this driver passed it 2s ago),
    // wait for the cooldown to expire and re-offer to this online driver!
    if (_cachedPendingJobs.isNotEmpty) {
      DateTime? earliest;
      for (final j in _cachedPendingJobs) {
        final cleanId = j.id.replaceAll('#', '').trim();
        final cd = _jobCooldownUntil[cleanId];
        if (cd != null) {
          if (earliest == null || cd.isBefore(earliest)) {
            earliest = cd;
          }
        }
      }

      _cooldownCheckTimer?.cancel();
      if (earliest != null) {
        final waitMs = earliest.difference(now).inMilliseconds;
        final safeWaitMs = waitMs > 0 ? waitMs : 250;
        _cooldownCheckTimer = Timer(Duration(milliseconds: safeWaitMs), () {
          _evaluatePendingQueue();
        });
      }
      availableRequestsNotifier.value = [];
      selectedRequestNotifier.value = null;
    } else {
      _stopCurrentOffer();
      availableRequestsNotifier.value = [];
      selectedRequestNotifier.value = null;
    }
  }

  /// Begins offering an incoming dispatch to the driver one-by-one with ringing audio and 10s timer
  void _startIncomingOffer(TowJob job) {
    _stopCurrentOffer();

    currentIncomingOfferNotifier.value = job;
    availableRequestsNotifier.value = [job];
    selectedRequestNotifier.value = job;

    _remainingOfferMs = 10000; // 10 seconds timer
    offerCountdownSecondsNotifier.value = 10;
    offerTimerProgressNotifier.value = 1.0;

    // Start loud alert ringing sound + rhythmic haptic vibration
    DriverSoundService.startAlertRingtone();

    _offerCountdownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_remainingOfferMs > 100) {
        _remainingOfferMs -= 100;
        offerTimerProgressNotifier.value = _remainingOfferMs / 10000.0;
        offerCountdownSecondsNotifier.value = (_remainingOfferMs / 1000.0).ceil();
      } else {
        timer.cancel();
        _handleOfferTimeoutOrDecline(job, isTimeout: true);
      }
    });
  }

  /// Handles 10-second expiry or explicit decline:
  /// - Stops ringing audio immediately
  /// - Passes to next driver or recycles back to same online driver
  /// - If pass count >= 2, marks for Admin manual dispatch
  Future<void> _handleOfferTimeoutOrDecline(TowJob job, {bool isTimeout = false}) async {
    _stopCurrentOffer();
    await DriverSoundService.playPassSound();

    final cleanId = job.id.replaceAll('#', '').trim();
    final passCount = (_jobPassCounts[cleanId] ?? 0) + 1;
    _jobPassCounts[cleanId] = passCount;

    debugPrint(
      '⏱️ [DriverJobService] Job $cleanId ${isTimeout ? "timed out (10s)" : "declined"}. Pass count: $passCount',
    );

    if (passCount >= 2) {
      // Order completed full cycle across drivers without acceptance -> Send to Admin Manual Dispatch!
      debugPrint('🚨 [DriverJobService] Job $cleanId reached $passCount passes. Forwarding to Admin Manual Dispatch.');
      _declinedJobIds.add(cleanId);
      _declinedJobIds.add(job.id);
      _forwardToAdminDispatch(job);
    } else {
      // Cooldown 2.5 seconds, then recycle back to the same online driver if no other drivers take it
      _jobCooldownUntil[cleanId] = DateTime.now().add(const Duration(milliseconds: 2500));
    }

    _evaluatePendingQueue();
  }

  /// Forwards unassigned/timed-out order to Admin portal for manual driver arrangement
  Future<void> _forwardToAdminDispatch(TowJob job) async {
    final cleanId = job.id.replaceAll('#', '').trim();
    final safeJobId = Uri.encodeComponent(cleanId);
    try {
      final statusUri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId/status');
      await http.put(
        statusUri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'status': 'pending_admin_dispatch',
          'needs_admin_dispatch': true,
          'driver_name': 'unassigned',
          'notes': 'Online drivers timed out / passed. Forwarded to Admin for manual dispatch.',
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  void _stopCurrentOffer() {
    _offerCountdownTimer?.cancel();
    _offerCountdownTimer = null;
    DriverSoundService.stopAlertRingtone();
    currentIncomingOfferNotifier.value = null;
  }

  /// Driver accepts a job request (via right-swipe or explicit Accept button)
  Future<void> acceptJob(TowJob job) async {
    _stopCurrentOffer();
    await DriverSoundService.playAcceptSound();

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
    final cleanDriverId = driver.id.startsWith('DRV-') ? driver.id : 'DRV-${driver.id}';
    try {
      final uri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId/accept');
      final res = await http.put(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'driver_id': cleanDriverId,
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
            'driver_id': cleanDriverId,
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

      // Ensure active driver's identity is registered on backend
      try {
        final regUri = Uri.parse(ApiConfig.usersEndpoint);
        await http.post(
          regUri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'name': driver.name,
            'email': driver.email,
            'phone': driver.phone,
            'role': 'driver',
            'truck_model': driver.truckModel,
            'license_plate': driver.licensePlate,
          }),
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}
    } catch (_) {}

    // Start live tracking synchronization loop
    _startActiveJobTracking(job.id);
  }

  /// Live tracking loop: broadcasts driver's real-time GPS and retrieves customer's live GPS
  void _startActiveJobTracking(String jobId) {
    _activeTrackingTimer?.cancel();
    final cleanJobId = jobId.replaceAll('#', '').trim();
    final safeJobId = Uri.encodeComponent(cleanJobId.isNotEmpty ? cleanJobId : jobId.trim());

    _activeTrackingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final current = activeJob;
      if (current == null || (current.id != jobId && current.id.replaceAll('#', '') != cleanJobId)) {
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

      // 1. FIRST: Check backend status for customer cancellation and live customer updates
      Map<String, dynamic>? towData;
      TowJob? updatedFromBackend;

      try {
        var getUri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId');
        var res = await http.get(getUri).timeout(const Duration(seconds: 3));
        if (res.statusCode != 200) {
          getUri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId?firebase_uid=dispatch_queue');
          res = await http.get(getUri).timeout(const Duration(seconds: 3));
        }

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['success'] == true && body['data'] is Map<String, dynamic>) {
            towData = body['data'] as Map<String, dynamic>;
            updatedFromBackend = TowJob.fromJson(towData);
          }
        }
      } catch (_) {}

      // If backend confirms the job was cancelled or completed:
      if (towData != null && updatedFromBackend != null) {
        final backendStatus = towData['status']?.toString().toLowerCase() ?? '';
        final isCancelled = updatedFromBackend.status == JobStatus.cancelled ||
            backendStatus.contains('cancel');
        final isCompleted = updatedFromBackend.status == JobStatus.completed ||
            backendStatus.contains('complete');

        if (isCompleted) {
          debugPrint('🏁 [DriverJobService] Active job $jobId completed in backend. Ending tracking loop.');
          _activeTrackingTimer?.cancel();
          _activeTrackingTimer = null;

          _completedJobIds.add(current.id);
          _completedJobIds.add(cleanJobId);
          _completedJobIds.add('#$cleanJobId');
          _saveCompletedJobIds();

          activeJobNotifier.value = null;
          startDispatchPolling();
          return;
        }

        if (isCancelled) {
          debugPrint('🚨 [DriverJobService] Customer cancelled active job $jobId detected by tracking loop');
          _activeTrackingTimer?.cancel();
          _activeTrackingTimer = null;

          final cancelledJob = updatedFromBackend.copyWith(
            status: JobStatus.cancelled,
            customerName: updatedFromBackend.customerName.isNotEmpty
                ? updatedFromBackend.customerName
                : current.customerName,
            vehicleName: updatedFromBackend.vehicleName.isNotEmpty
                ? updatedFromBackend.vehicleName
                : current.vehicleName,
          );

          _cancelledJobIds.add(current.id);
          _cancelledJobIds.add(cleanJobId);

          customerCancelledJobNotifier.value = cancelledJob;
          activeJobNotifier.value = null;
          startDispatchPolling();
          return;
        }

        // Apply updated customer coordinates if available
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

      // 2. SECOND: Broadcast live GPS coordinates to backend for Customer & Admin live tracking
      try {
        final locUri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId/driver-location');
        await http.put(
          locUri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'driver_lat': currentPos.latitude,
            'driver_lng': currentPos.longitude,
            'driver_heading': driverHeading,
            'status': towData?['status']?.toString() ?? current.status.name,
          }),
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}

      // Keep standby driver record in sync on profile
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs - _lastHeartbeatMs > 6000) {
        _lastHeartbeatMs = nowMs;
        _sendDriverHeartbeat(currentPos.latitude, currentPos.longitude, isOnline: true);
      }
    });
  }

  /// Driver cancels an active job, releasing it back or marking it cancelled on backend
  Future<void> cancelJob(TowJob job, {String? reason}) async {
    final cleanId = job.id.replaceAll('#', '').trim();
    _cancelledJobIds.add(cleanId);
    _cancelledJobIds.add(job.id);
    _activeTrackingTimer?.cancel();
    _activeTrackingTimer = null;
    activeJobNotifier.value = null;

    final safeJobId = Uri.encodeComponent(cleanId);
    try {
      final uri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId/status');
      await http.put(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'status': 'cancelled',
          'notes': reason != null ? 'Cancelled by driver: $reason' : 'Cancelled by driver',
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    try {
      final delUri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId?firebase_uid=dispatch_queue');
      await http.delete(delUri).timeout(const Duration(seconds: 3));
    } catch (_) {}

    final updatedList = List<TowJob>.from(availableRequestsNotifier.value)
      ..removeWhere((j) => j.id.replaceAll('#', '').trim() == cleanId);
    availableRequestsNotifier.value = updatedList;
    if (selectedRequest?.id.replaceAll('#', '').trim() == cleanId) {
      selectedRequestNotifier.value = updatedList.isNotEmpty ? updatedList.first : null;
    }

    startDispatchPolling();
  }

  /// Driver declines/rejects a job request (via left-swipe or explicit Decline button)
  void declineJob(TowJob job) {
    _handleOfferTimeoutOrDecline(job, isTimeout: false);
  }

  /// Clears available requests
  void resetDemoRequests() {
    _stopCurrentOffer();
    _jobPassCounts.clear();
    _jobCooldownUntil.clear();
    _declinedJobIds.clear();
    availableRequestsNotifier.value = [];
    selectedRequestNotifier.value = null;
  }

  Future<void> advanceJobStage() async {
    final current = activeJob;
    if (current == null) return;

    JobStatus nextStatus;
    switch (current.status) {
      case JobStatus.pending:
      case JobStatus.pendingAdminDispatch:
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
      if (nextStatus == JobStatus.arrived) {
        final pickupCoord = LatLng(current.pickupLat, current.pickupLng);
        driverLocationNotifier.value = pickupCoord;
      }

      final updated = current.copyWith(
        status: nextStatus,
        driverLat: nextStatus == JobStatus.arrived ? current.pickupLat : current.driverLat,
        driverLng: nextStatus == JobStatus.arrived ? current.pickupLng : current.driverLng,
      );
      activeJobNotifier.value = updated;

      final cleanId = current.id.replaceAll('#', '').trim();
      final safeJobId = Uri.encodeComponent(cleanId);
      try {
        final uri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId/status');
        await http.put(
          uri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'status': nextStatus.name}),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}

      try {
        final locUri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId/driver-location');
        await http.put(
          locUri,
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'status': nextStatus.name,
            'driver_lat': updated.driverLat,
            'driver_lng': updated.driverLng,
            'driver_heading': driverHeading,
          }),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
  }

  Future<void> _completeJob(TowJob job) async {
    _activeTrackingTimer?.cancel();
    _activeTrackingTimer = null;

    final completed = job.copyWith(status: JobStatus.completed);
    final currentList = List<TowJob>.from(completedJobsNotifier.value);
    currentList.removeWhere((c) => c.id == job.id);
    currentList.insert(0, completed);
    completedJobsNotifier.value = currentList;

    final earned = job.estimatedPayout;
    final newEarnings = driver.todayEarnings + earned;
    final newTotalTows = driver.totalTows + 1;

    driverNotifier.value = driver.copyWith(
      todayEarnings: newEarnings,
      totalTows: newTotalTows,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('driver_today_earnings', newEarnings);
      await prefs.setInt('driver_total_tows', newTotalTows);
    } catch (_) {}

    // 1. Immediately record in completed set & persist to storage
    final cleanId = job.id.replaceAll('#', '').trim();
    _completedJobIds.add(cleanId);
    _completedJobIds.add(job.id);
    _completedJobIds.add('#$cleanId');
    _saveCompletedJobIds();

    // 2. Clear active job immediately
    activeJobNotifier.value = null;

    // 3. Immediately update backend status to completed
    final safeJobId = Uri.encodeComponent(cleanId);
    try {
      final uri = Uri.parse('${ApiConfig.towsEndpoint}/$safeJobId/status');
      await http.put(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'status': 'completed'}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    startDispatchPolling();
  }
}
