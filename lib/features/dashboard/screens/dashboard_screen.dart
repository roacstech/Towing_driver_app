import 'package:flutter/material.dart';
import '../../../core/constants/driver_colors.dart';
import '../../jobs/models/tow_job.dart';
import '../../jobs/screens/active_job_screen.dart';
import '../../jobs/services/driver_job_service.dart';
import '../../jobs/widgets/incoming_job_dialog.dart';
import '../../profile/models/driver_profile.dart';
import '../../profile/screens/driver_profile_screen.dart';
import '../../documents/screens/driver_document_upload_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DriverJobService _jobService = DriverJobService();
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _jobService.init();

    // Listen for incoming dispatch alerts to pop up the modal
    _jobService.pendingRequestNotifier.addListener(_onPendingRequestChanged);
    _jobService.activeJobNotifier.addListener(_onActiveJobChanged);
  }

  @override
  void dispose() {
    _jobService.pendingRequestNotifier.removeListener(_onPendingRequestChanged);
    _jobService.activeJobNotifier.removeListener(_onActiveJobChanged);
    super.dispose();
  }

  void _onPendingRequestChanged() {
    final pending = _jobService.pendingRequest;
    if (pending != null && !_dialogOpen && mounted) {
      _dialogOpen = true;
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (ctx) => IncomingJobDialog(job: pending),
      ).then((_) {
        _dialogOpen = false;
      });
    } else if (pending == null && _dialogOpen && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogOpen = false;
    }
  }

  void _onActiveJobChanged() {
    final active = _jobService.activeJob;
    if (active != null && mounted) {
      // Auto navigate to active job if not already viewing it
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ActiveJobScreen(job: active),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverColors.bgDark,
      body: SafeArea(
        child: ValueListenableBuilder<DriverProfile>(
          valueListenable: _jobService.driverNotifier,
          builder: (context, driver, _) {
            return RefreshIndicator(
              onRefresh: () async {
                await _jobService.checkBackendForPendingJobs();
              },
              color: DriverColors.primaryOrange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                  // 1. Top Header Row (Driver Name & Profile Avatar)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                driver.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: DriverColors.onlineGreen, size: 20),
                            ],
                          ),
                          Text(
                            driver.truckModel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => const DriverProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: DriverColors.primaryOrange, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 24,
                            backgroundColor: DriverColors.cardDark,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Online / Offline Status Toggle Card
                  _buildStatusCard(driver),
                  const SizedBox(height: 14),

                  // 2.1 Compliance & Document Verification Banner
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const DriverDocumentUploadScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: DriverColors.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: DriverColors.primaryOrange
                              .withValues(alpha: 0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DriverColors.primaryOrange
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.document_scanner_outlined,
                              color: DriverColors.primaryOrange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Fleet Documents',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: DriverColors.primaryOrange
                                            .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '1 Pending',
                                        style: TextStyle(
                                          color: DriverColors.primaryOrange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'CDL, Vehicle Registration & Inspection',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white54,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Active Job in Progress (if any)
                  ValueListenableBuilder<TowJob?>(
                    valueListenable: _jobService.activeJobNotifier,
                    builder: (context, activeJob, _) {
                      if (activeJob == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: _buildActiveJobBanner(activeJob),
                      );
                    },
                  ),

                  // 4. Quick Metrics / Earnings Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: "TODAY'S EARNINGS",
                          value: '\$${driver.todayEarnings.toStringAsFixed(2)}',
                          icon: Icons.payments_rounded,
                          color: DriverColors.onlineGreen,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'COMPLETED TOWS',
                          value: '${driver.totalTows}',
                          icon: Icons.local_shipping_rounded,
                          color: DriverColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'DRIVER RATING',
                          value: '★ ${driver.rating.toStringAsFixed(2)}',
                          icon: Icons.star_rounded,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'ACCEPTANCE RATE',
                          value: '98%',
                          icon: Icons.speed_rounded,
                          color: DriverColors.navBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // 5. Test Radar Action Button
                  Container(
                    decoration: BoxDecoration(
                      color: DriverColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DriverColors.borderDark),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: DriverColors.primaryOrange.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.radar_rounded, color: DriverColors.primaryOrange, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dispatch Simulator',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                driver.isOnline
                                    ? 'Scanning for stranded customers...'
                                    : 'Go online to scan for dispatch jobs',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: driver.isOnline
                              ? () => _jobService.checkBackendForPendingJobs()
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DriverColors.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Scan Now'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // 6. Recent Tows / Activity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Towing Jobs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'View All',
                        style: TextStyle(
                          color: DriverColors.primaryOrangeLight,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ValueListenableBuilder<List<TowJob>>(
                    valueListenable: _jobService.completedJobsNotifier,
                    builder: (context, jobs, _) {
                      if (jobs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: DriverColors.cardDark,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'No recent tows recorded yet today.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: jobs.map((j) => _buildJobItem(j)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(DriverProfile driver) {
    final isOnline = driver.isOnline;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DriverColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? DriverColors.onlineGreen : DriverColors.offlineRed,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? DriverColors.onlineGreen : DriverColors.offlineRed)
                .withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? DriverColors.onlineGreen : DriverColors.offlineRed,
              boxShadow: [
                BoxShadow(
                  color: isOnline ? DriverColors.onlineGreen : DriverColors.offlineRed,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                  style: TextStyle(
                    color: isOnline ? DriverColors.onlineGreen : DriverColors.offlineRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  isOnline ? 'Ready to receive roadside requests' : 'Tap to start accepting jobs',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isOnline,
            onChanged: (val) => _jobService.toggleOnlineStatus(val),
            activeThumbColor: Colors.white,
            activeTrackColor: DriverColors.onlineGreen,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade800,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobBanner(TowJob job) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DriverColors.primaryOrange.withValues(alpha: 0.9),
            DriverColors.primaryOrangeLight,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: DriverColors.primaryOrange.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation, color: DriverColors.primaryOrange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE JOB IN PROGRESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${job.vehicleName} (${job.status.label})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => ActiveJobScreen(job: job),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: DriverColors.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('RESUME', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DriverColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DriverColors.borderDark),
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
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobItem(TowJob job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DriverColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DriverColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.vehicleName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                job.totalCost,
                style: const TextStyle(
                  color: DriverColors.onlineGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${job.serviceTitle} • ${job.etaOrDuration}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on, color: DriverColors.primaryOrange, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.dropAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
