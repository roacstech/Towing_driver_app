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

  final ValueNotifier<TowJob?> activeJobNotifier = ValueNotifier<TowJob?>(null);
  final ValueNotifier<TowJob?> pendingRequestNotifier = ValueNotifier<TowJob?>(null);
  final ValueNotifier<List<TowJob>> completedJobsNotifier =
      ValueNotifier<List<TowJob>>([]);

  DriverProfile get driver => driverNotifier.value;
  TowJob? get activeJob => activeJobNotifier.value;
  TowJob? get pendingRequest => pendingRequestNotifier.value;
  List<TowJob> get completedJobs => completedJobsNotifier.value;

  Timer? _pollingTimer;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isOnline = prefs.getBool('driver_is_online') ?? true;
    driverNotifier.value = driver.copyWith(isOnline: isOnline);

    _loadSampleCompletedJobs();

    if (isOnline) {
      startDispatchPolling();
    }
  }

  void toggleOnlineStatus(bool online) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('driver_is_online', online);
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
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (driver.isOnline && activeJob == null && pendingRequest == null) {
        checkBackendForPendingJobs();
      }
    });

    // Also trigger initial check
    if (activeJob == null && pendingRequest == null) {
      Future.delayed(const Duration(seconds: 2), () {
        checkBackendForPendingJobs();
      });
    }
  }

  void stopDispatchPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Checks shared PostgreSQL backend for new tows created by Customer App
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

          if (activeOrPending.isNotEmpty && activeJob == null && pendingRequest == null) {
            final latest = activeOrPending.first;
            pendingRequestNotifier.value = latest;
            return;
          }
        }
      }
    } catch (_) {
      // Offline fallback: simulated request if empty
    }

    // If no remote job found and driver is online, simulate a nearby customer request for demo
    if (pendingRequest == null && activeJob == null) {
      _simulateDemoRequest();
    }
  }

  void _simulateDemoRequest() {
    pendingRequestNotifier.value = TowJob(
      id: 'TOW-${DateTime.now().millisecondsSinceEpoch % 10000}',
      serviceTitle: 'Emergency Flatbed Tow',
      vehicleName: 'BMW 330i (Sedan)',
      licensePlate: '7XTR921',
      pickupAddress: 'Mission St & 16th St, San Francisco, CA',
      dropAddress: 'City View Auto Repair, SOMA, SF',
      pickupLat: 37.7649,
      pickupLng: -122.4194,
      dropLat: 37.7785,
      dropLng: -122.4056,
      customerName: 'Sarah Jenkins',
      customerPhone: '+1 (555) 438-9922',
      totalCost: '\$145.00',
      etaOrDuration: '6 mins away (1.8 miles)',
      status: JobStatus.pending,
      createdAt: DateTime.now(),
      notes: 'Transmission fluid leak, vehicle will not shift into gear.',
    );
  }

  Future<void> acceptJob(TowJob job) async {
    final acceptedJob = job.copyWith(status: JobStatus.accepted);
    activeJobNotifier.value = acceptedJob;
    pendingRequestNotifier.value = null;

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

  void declineJob() {
    pendingRequestNotifier.value = null;
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

      // Sync backend
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

    // Parse cost and increment earnings
    final cleanCostStr = job.totalCost.replaceAll(RegExp(r'[^0-9.]'), '');
    final addedEarn = double.tryParse(cleanCostStr) ?? 120.0;
    
    driverNotifier.value = driver.copyWith(
      todayEarnings: driver.todayEarnings + addedEarn,
      totalTows: driver.totalTows + 1,
    );

    activeJobNotifier.value = null;

    // Notify backend
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
        etaOrDuration: 'Completed in 38m',
        status: JobStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        notes: 'Dually rear wheel lift required.',
      ),
      TowJob(
        id: 'TOW-5912',
        serviceTitle: 'Standard Flatbed Tow',
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
        etaOrDuration: 'Completed in 25m',
        status: JobStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        notes: 'Flat tire and missing spare wheel.',
      ),
    ];
  }
}
