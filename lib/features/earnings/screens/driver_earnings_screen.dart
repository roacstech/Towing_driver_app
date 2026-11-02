import 'package:flutter/material.dart';
import '../../../core/constants/driver_colors.dart';
import '../../jobs/services/driver_job_service.dart';
import '../../jobs/models/tow_job.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobService = DriverJobService();

    return Scaffold(
      backgroundColor: DriverColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                color: DriverColors.textNavy,
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Driver Earnings',
          style: TextStyle(
            color: DriverColors.textNavy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Primary Today Balance Card
            ValueListenableBuilder(
              valueListenable: jobService.driverNotifier,
              builder: (context, driver, _) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DriverColors.navy900, DriverColors.textPrimary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: DriverColors.floatingControlShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TODAY\'S REVENUE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: DriverColors.emeraldGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.trending_up, color: DriverColors.emeraldGreen, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  '+18.4%',
                                  style: TextStyle(
                                    color: DriverColors.emeraldGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${driver.todayEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Colors.white12),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('Completed Tows', '${driver.totalTows} trips'),
                          _buildStatItem('Driver Rating', '${driver.rating.toStringAsFixed(2)} ★'),
                          _buildStatItem('Weekly Total', '\$1,845.00'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 2. Weekly Activity Chart Bar Mock
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DriverColors.surfaceBorder),
                boxShadow: DriverColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weekly Performance',
                        style: TextStyle(
                          color: DriverColors.textNavy,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Oct 23 - Oct 29',
                        style: TextStyle(
                          color: DriverColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildDayBar('Mon', 0.5, '\$210'),
                      _buildDayBar('Tue', 0.7, '\$280'),
                      _buildDayBar('Wed', 0.9, '\$360'),
                      _buildDayBar('Thu', 0.45, '\$190'),
                      _buildDayBar('Fri', 0.85, '\$340'),
                      _buildDayBar('Sat', 1.0, '\$415', isToday: true),
                      _buildDayBar('Sun', 0.3, '\$120'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Completed Tows History
            const Text(
              'Recent Completed Tows',
              style: TextStyle(
                color: DriverColors.textNavy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            ValueListenableBuilder<List<TowJob>>(
              valueListenable: jobService.completedJobsNotifier,
              builder: (context, completed, _) {
                if (completed.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DriverColors.surfaceBorder),
                    ),
                    child: const Center(
                      child: Text(
                        'No completed tows yet today',
                        style: TextStyle(color: DriverColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completed.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final job = completed[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DriverColors.surfaceBorder),
                        boxShadow: DriverColors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: DriverColors.greenTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: DriverColors.emeraldDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.serviceTitle,
                                  style: const TextStyle(
                                    color: DriverColors.textNavy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${job.vehicleName} · ${job.etaOrDuration}',
                                  style: const TextStyle(
                                    color: DriverColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            job.payoutFormatted,
                            style: const TextStyle(
                              color: DriverColors.emeraldDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDayBar(String day, double heightPct, String amount, {bool isToday = false}) {
    return Column(
      children: [
        Text(
          amount,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isToday ? DriverColors.electricBlue : DriverColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: 80 * heightPct,
          decoration: BoxDecoration(
            color: isToday ? DriverColors.electricBlue : DriverColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isToday ? DriverColors.electricBlue : DriverColors.surfaceBorder,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: isToday ? DriverColors.textNavy : DriverColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
