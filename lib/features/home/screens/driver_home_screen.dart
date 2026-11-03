import 'package:flutter/material.dart';
import '../../jobs/models/tow_job.dart';
import '../../jobs/screens/request_list_screen.dart';
import '../../jobs/screens/trip_details_screen.dart';
import '../../jobs/screens/active_job_screen.dart';
import '../../jobs/services/driver_job_service.dart';
import '../../profile/models/driver_profile.dart';
import '../../profile/screens/driver_profile_screen.dart';
import '../../earnings/screens/driver_earnings_screen.dart';
import '../widgets/driver_map.dart';
import '../widgets/centered_layered_card_stack.dart';
import '../../jobs/widgets/customer_cancelled_dialog.dart';

class DriverHomeScreen extends StatefulWidget {
  final VoidCallback? onSwitchToProfile;

  const DriverHomeScreen({
    super.key,
    this.onSwitchToProfile,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final DriverJobService _jobService = DriverJobService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final ValueNotifier<double> _sheetRatioNotifier = ValueNotifier<double>(0.48);

  @override
  void initState() {
    super.initState();
    _jobService.init();
    _sheetController.addListener(_onSheetSizeChanged);
    _jobService.customerCancelledJobNotifier.addListener(_onCustomerCancelledJob);
  }

  @override
  void dispose() {
    _jobService.customerCancelledJobNotifier.removeListener(_onCustomerCancelledJob);
    _sheetController.removeListener(_onSheetSizeChanged);
    _sheetController.dispose();
    _sheetRatioNotifier.dispose();
    _jobService.stopDispatchPolling();
    super.dispose();
  }

  void _onCustomerCancelledJob() {
    final cancelledJob = _jobService.customerCancelledJobNotifier.value;
    if (cancelledJob != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ModalRoute.of(context)?.isCurrent == true) {
          CustomerCancelledDialog.show(
            context,
            job: cancelledJob,
            onDismiss: () {
              _jobService.clearCustomerCancellation();
            },
          );
        }
      });
    }
  }

  // Smooth updates without triggering full-tree rebuilds for 120fps scrolling
  void _onSheetSizeChanged() {
    if (_sheetController.isAttached) {
      final currentSize = _sheetController.size;
      _sheetRatioNotifier.value = currentSize;
    }
  }

  bool _isNavigatingToActiveJob = false;

  void _navigateToActiveJob(TowJob job) {
    if (_isNavigatingToActiveJob) return;
    _isNavigatingToActiveJob = true;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ActiveJobScreen(job: job),
      ),
    ).then((_) {
      if (mounted) {
        _isNavigatingToActiveJob = false;
      }
    });
  }

  void _handleAcceptJob(TowJob job) {
    _jobService.acceptJob(job);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Job Accepted!',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Text(
                    'En route to ${job.vehicleName}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    _navigateToActiveJob(job);
  }

  void _handleRejectJob(TowJob job) {
    _jobService.declineJob(job);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        content: Text(
          'Request for ${job.vehicleName} passed.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
    );
  }

  void _handleOpenTripDetails(TowJob job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => TripDetailsScreen(job: job),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Driver Profile Header with Clean Online/Offline Toggle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: ValueListenableBuilder<DriverProfile>(
                valueListenable: _jobService.driverNotifier,
                builder: (context, driver, _) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E3A8A),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver.name.isNotEmpty ? driver.name : 'Driver Partner',
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${driver.rating.toStringAsFixed(1)} (${driver.totalTows} tows)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Clean Online/Offline Switcher inside the Drawer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: driver.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: driver.isOnline ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: driver.isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  driver.isOnline ? 'Online (Accepting Calls)' : 'Offline (Paused)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: driver.isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            Switch.adaptive(
                              value: driver.isOnline,
                              activeTrackColor: const Color(0xFF16A34A),
                              onChanged: (val) {
                                _jobService.toggleOnlineStatus(val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_rounded, color: Color(0xFF2563EB)),
                    title: const Text('Dispatch Radar (Home)', style: TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFF64748B)),
                    title: const Text('All Requests', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RequestListScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.credit_card_outlined, color: Color(0xFF64748B)),
                    title: const Text('Earnings & Payouts', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DriverEarningsScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B)),
                    title: const Text('Driver Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onSwitchToProfile != null) {
                        widget.onSwitchToProfile!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<DriverProfile>(
              valueListenable: _jobService.driverNotifier,
              builder: (context, driver, _) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fire_truck_rounded, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Assigned: ${driver.truckModel} (${driver.licensePlate})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 1. Today's Performance & Shift Summary
  Widget _buildPerformanceSection() {
    return ValueListenableBuilder<DriverProfile>(
      valueListenable: _jobService.driverNotifier,
      builder: (context, driver, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today\'s Shift Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Today Earnings',
                      value: '\$${driver.todayEarnings.toStringAsFixed(2)}',
                      subtitle: '${_jobService.completedJobs.length} tows today',
                      icon: Icons.attach_money_rounded,
                      iconColor: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Tows Completed',
                      value: '${driver.totalTows} Tows',
                      subtitle: '${_jobService.completedJobs.length} today',
                      icon: Icons.fire_truck_rounded,
                      iconColor: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Acceptance Rate',
                      value: '99%',
                      subtitle: 'Active Priority Tier',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      bgColor: const Color(0xFFF5F3FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Shift Status',
                      value: driver.isOnline ? 'Online' : 'Offline',
                      subtitle: driver.isOnline ? 'Accepting dispatches' : 'Dispatch paused',
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFFFBEB),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Upcoming Queue
  Widget _buildQueueSection(List<TowJob> requests) {
    final queuedJobs = requests.skip(1).take(3).toList();
    if (queuedJobs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Nearby Calls in Queue (${requests.length - 1} more)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestListScreen()),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...queuedJobs.map((job) => _buildQueueItem(job)),
        ],
      ),
    );
  }

  Widget _buildQueueItem(TowJob job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              job.vehicleImage,
              width: 52,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 52,
                height: 44,
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.fire_truck_rounded, size: 22, color: Color(0xFF94A3B8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.requestType,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${job.distanceToPickup} • ${job.vehicleName}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                job.payoutWhole,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () {
                  _jobService.selectRequest(job);
                  _sheetController.animateTo(
                    0.42,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Equipment & Carrier Checklist Card
  Widget _buildCarrierStatusCard() {
    return ValueListenableBuilder<DriverProfile>(
      valueListenable: _jobService.driverNotifier,
      builder: (context, driver, _) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 28),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined, color: Color(0xFF2563EB), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Assigned Carrier: ${driver.truckModel} (${driver.licensePlate}) · Hydraulic winch & certified wheel-lift straps verified.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      backgroundColor: Colors.white,
      body: ValueListenableBuilder<TowJob?>(
        valueListenable: _jobService.activeJobNotifier,
        builder: (context, activeJob, _) {
          return ValueListenableBuilder<DriverProfile>(
            valueListenable: _jobService.driverNotifier,
            builder: (context, driver, _) {
              final isOnline = driver.isOnline;

              return ValueListenableBuilder<List<TowJob>>(
                valueListenable: _jobService.availableRequestsNotifier,
                builder: (context, requests, _) {
                  final visibleRequests = isOnline ? requests : const <TowJob>[];

                  return ValueListenableBuilder<TowJob?>(
                    valueListenable: _jobService.selectedRequestNotifier,
                    builder: (context, selectedJob, _) {
                      final effectiveSelected = isOnline
                          ? (activeJob ?? (selectedJob ?? (visibleRequests.isNotEmpty ? visibleRequests.first : null)))
                          : null;

                      return Stack(
                        children: [
                          // 1. Full Screen Interactive Map Layer
                          ValueListenableBuilder<double>(
                            valueListenable: _sheetRatioNotifier,
                            builder: (context, ratio, _) {
                              return Positioned.fill(
                                child: DriverMap(
                                  requests: activeJob != null ? [activeJob] : visibleRequests,
                                  selectedRequest: effectiveSelected,
                                  sheetRatio: ratio,
                                  isOnline: isOnline,
                                  onToggleOnline: () {
                                    _jobService.toggleOnlineStatus(!isOnline);
                                  },
                                  onRequestSelected: (job) {
                                    _jobService.selectRequest(job);
                                  },
                                  onMenuPressed: () {
                                    _scaffoldKey.currentState?.openDrawer();
                                  },
                                  onExpandSheet: () {
                                    _sheetController.animateTo(
                                      0.48,
                                      duration: const Duration(milliseconds: 280),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                ),
                              );
                            },
                          ),

                          // 2. Persistent Floating Live Active Job Banner on Map
                          if (activeJob != null)
                            Positioned(
                              top: MediaQuery.of(context).padding.top + 70,
                              left: 16,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => _navigateToActiveJob(activeJob),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF334155), width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.28),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2563EB),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.fire_truck_rounded, color: Colors.white, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF10B981),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '1 JOB IN PROGRESS • ${activeJob.status.label.toUpperCase()}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Color(0xFF93C5FD),
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${activeJob.customerName} • ${activeJob.vehicleName}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Resume',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          // 3. Buttery Smooth 120fps Sliding Driver Hub Sheet
                          DraggableScrollableSheet(
                            controller: _sheetController,
                            initialChildSize: 0.48, // Comfortable initial ratio (customer-app matched)
                            minChildSize: 0.16,    // Collapsed: 84% map visible, handle & header accessible
                            maxChildSize: 0.88,    // Expanded: full view with shift stats
                            snap: true,
                            snapSizes: const [0.16, 0.48, 0.88],
                            builder: (context, scrollController) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                                      blurRadius: 24,
                                      offset: const Offset(0, -6),
                                    ),
                                  ],
                                ),
                                child: CustomScrollView(
                                  controller: scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  slivers: [
                                    SliverToBoxAdapter(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Top Drag Handle Pill
                                          const SizedBox(height: 10),
                                          Center(
                                            child: Container(
                                              width: 44,
                                              height: 4.5,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFCBD5E1),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // The Cards: Active Job In-Progress Card OR Available Dispatch Stack
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: activeJob != null
                                                ? _buildActiveJobCard(activeJob)
                                                : CenteredLayeredCardStack(
                                                    requests: visibleRequests,
                                                    isOnline: isOnline,
                                                    onGoOnline: () => _jobService.toggleOnlineStatus(true),
                                                    onAccept: _handleAcceptJob,
                                                    onReject: _handleRejectJob,
                                                    onTapJob: _handleOpenTripDetails,
                                                    onResetDemo: () => _jobService.resetDemoRequests(),
                                                  ),
                                          ),

                                          const SizedBox(height: 16),

                                          // Scroll Down Affordance
                                          const Center(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.keyboard_arrow_down_rounded,
                                                  size: 16,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Shift Stats & Queue',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 14),

                                          // RELATED INFORMATION SECTION:
                                          // A) Today's Shift Performance & Earnings Summary
                                          _buildPerformanceSection(),

                                          // B) Nearby Dispatches in Queue (Only shown when online and no active job)
                                          if (isOnline && activeJob == null && requests.length > 1)
                                            _buildQueueSection(requests),

                                          // C) Carrier & Equipment Checklist
                                          _buildCarrierStatusCard(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActiveJobCard(TowJob job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x101D4ED8),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'ACTIVE TOW • ${job.status.label.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                job.payoutFormatted,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  job.customerName.isNotEmpty ? job.customerName[0] : 'C',
                  style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.customerName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      job.vehicleName,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pickup: ${job.pickupAddress}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToActiveJob(job),
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text(
                'Resume Active Order',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
