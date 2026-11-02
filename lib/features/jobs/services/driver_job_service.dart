import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  // Available list of requests for the card stack and 'See All' list
  final ValueNotifier<List<TowJob>> availableRequestsNotifier =
      ValueNotifier<List<TowJob>>(List<TowJob>.from(TowJob.sampleRequests));

  // The currently focused/selected request card (syncs with the top map's route polyline)
  final ValueNotifier<TowJob?> selectedRequestNotifier =
      ValueNotifier<TowJob?>(TowJob.sampleRequests.first);

  final ValueNotifier<TowJob?> activeJobNotifier = ValueNotifier<TowJob?>(null);
  final ValueNotifier<TowJob?> pendingRequestNotifier = ValueNotifier<TowJob?>(null);
  final ValueNotifier<List<TowJob>> completedJobsNotifier =
      ValueNotifier<List<TowJob>>([]);

  DriverProfile get driver => driverNotifier.value;
  List<TowJob> get availableRequests => availableRequestsNotifier.value;
  TowJob? get selectedRequest => selectedRequestNotifier.value;
  TowJob? get activeJob => activeJobNotifier.value;
  TowJob? get pendingRequest => pendingRequestNotifier.value;
  List<TowJob> get completedJobs => completedJobsNotifier.value;

  Timer? _pollingTimer;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isOnline = prefs.getBool('driver_is_online') ?? true;
      driverNotifier.value = driver.copyWith(isOnline: isOnline);
    } catch (_) {}

    _loadSampleCompletedJobs();

    // Ensure selected request defaults to first available
    if (availableRequests.isNotEmpty) {
      selectedRequestNotifier.value = availableRequests.first;
    }

    if (driver.isOnline) {
      startDispatchPolling();
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
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (driver.isOnline && activeJob == null) {
        checkBackendForPendingJobs();
      }
    });

    if (activeJob == null) {
      Future.delayed(const Duration(seconds: 2), () {
        checkBackendForPendingJobs();
      });
    }
  }

  void stopDispatchPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Checks shared PostgreSQL / REST backend for new tows created by Customer App
  Future<void> checkBackendForPendingJobs() async {
    try {
      final uri = Uri.parse(ApiConfig.towsEndpoint);
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          final List list = body['data'];
          final activeOrPending = list
              .map((j) => TowJob.fromJson(j as Map<String, dynamic>))
              .where((t) => t.status == JobStatus.pending || t.status == JobStatus.accepted)
              .toList();

          if (activeOrPending.isNotEmpty) {
            // Merge into available if not already present
            final current = List<TowJob>.from(availableRequestsNotifier.value);
            for (final incoming in activeOrPending) {
              if (!current.any((e) => e.id == incoming.id)) {
                current.insert(0, incoming);
              }
            }
            availableRequestsNotifier.value = current;
            if (selectedRequest == null && current.isNotEmpty) {
              selectedRequestNotifier.value = current.first;
            }
          }
        }
      }
    } catch (_) {
      // Backend is optional or offline; realistic mock requests remain active
    }
  }

  /// Driver accepts a job request (via right-swipe or explicit Accept button)
  Future<void> acceptJob(TowJob job) async {
    final acceptedJob = job.copyWith(status: JobStatus.accepted);
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

    // Notify backend
    try {
      final uri = Uri.parse('${ApiConfig.towsEndpoint}/${job.id}/status');
      await http.put(
        uri,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'status': 'active'}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
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

  /// Reloads sample requests if the driver has cleared the queue
  void resetDemoRequests() {
    availableRequestsNotifier.value = List<TowJob>.from(TowJob.sampleRequests);
    selectedRequestNotifier.value = TowJob.sampleRequests.first;
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

  void _loadSampleCompletedJobs() {
    completedJobsNotifier.value = [
      TowJob(
        id: 'TOW-6841',
        serviceTitle: 'Heavy Wheel-Lift Recovery',
        requestType: 'Vehicle Transport',
        vehicleName: 'Ford F-150 SuperCrew',
        licensePlate: 'CAL-9942',
        pickupAddress: '420 Montgomery St, Financial District, SF',
        dropAddress: 'Bay Fleet Garage, 3rd St',
        pickupLat: 37.7925,
        pickupLng: -122.4023,
        dropLat: 37.7695,
        dropLng: -122.3892,
        customerName: 'David Miller',
        customerPhone: '+1 (555) 782-1200',
        totalCost: '\$160.00',
        estimatedPayout: 160.00,
        etaOrDuration: 'Completed in 38m',
        status: JobStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        notes: 'Dually rear wheel lift required.',
      ),
      TowJob(
        id: 'TOW-5912',
        serviceTitle: 'Standard Flatbed Tow',
        requestType: 'Flat Tire',
        vehicleName: 'Honda Civic Sport',
        licensePlate: '6VBN481',
        pickupAddress: 'Sunset Blvd & 22nd Ave, SF',
        dropAddress: 'Golden Gate Motors, Geary Blvd',
        pickupLat: 37.7533,
        pickupLng: -122.4812,
        dropLat: 37.7812,
        dropLng: -122.4691,
        customerName: 'Elena Rostova',
        customerPhone: '+1 (555) 349-8811',
        totalCost: '\$110.00',
        estimatedPayout: 110.00,
        etaOrDuration: 'Completed in 25m',
        status: JobStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        notes: 'Flat tire and missing spare wheel.',
      ),
    ];
  }
}
