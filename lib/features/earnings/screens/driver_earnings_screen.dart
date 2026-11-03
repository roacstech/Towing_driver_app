import 'package:flutter/material.dart';
import '../../../core/constants/driver_colors.dart';
import '../../jobs/services/driver_job_service.dart';
import '../../jobs/models/tow_job.dart';

class DailyPerformance {
  final String dayName;
  final String fullDayName;
  final String dateString;
  final double amount;
  final int completedTows;
  final double onlineHours;
  final double rating;

  const DailyPerformance({
    required this.dayName,
    required this.fullDayName,
    required this.dateString,
    required this.amount,
    required this.completedTows,
    required this.onlineHours,
    required this.rating,
  });

  String get amountFormatted => '\$${amount.toInt()}';
  String get fullAmountFormatted => '\$${amount.toStringAsFixed(2)}';
  String get avgPerTowFormatted {
    if (completedTows == 0) return '\$0.00';
    return '\$${(amount / completedTows).toStringAsFixed(2)}';
  }
}

class WeeklyData {
  final String dateRange;
  final List<DailyPerformance> days;

  const WeeklyData({
    required this.dateRange,
    required this.days,
  });

  double get totalEarnings => days.fold(0.0, (sum, d) => sum + d.amount);
  int get totalTows => days.fold(0, (sum, d) => sum + d.completedTows);
  double get totalHours => days.fold(0.0, (sum, d) => sum + d.onlineHours);
  double get maxAmount => days.fold(1.0, (max, d) => d.amount > max ? d.amount : max);
}

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  final DriverJobService _jobService = DriverJobService();

  late List<WeeklyData> _weeks;
  int _selectedWeekIndex = 0;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _weeks = _buildWeeks();
    _selectedWeekIndex = 0;
    _selectedDayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
  }

  List<WeeklyData> _buildWeeks() {
    final now = DateTime.now();
    final driver = _jobService.driver;
    final completedCount = _jobService.completedJobs.length;
    final todayEarned = driver.todayEarnings;

    final daysToMonday = (now.weekday - 1);
    final monday = now.subtract(Duration(days: daysToMonday));

    List<WeeklyData> generatedWeeks = [];

    for (int w = 0; w < 4; w++) {
      final weekMonday = monday.subtract(Duration(days: w * 7));
      final weekSunday = weekMonday.add(const Duration(days: 6));
      final dateRangeStr =
          '${_monthName(weekMonday.month)} ${weekMonday.day.toString().padLeft(2, '0')} - ${_monthName(weekSunday.month)} ${weekSunday.day.toString().padLeft(2, '0')}';

      List<DailyPerformance> days = [];
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const fullDayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

      for (int d = 0; d < 7; d++) {
        final dayDate = weekMonday.add(Duration(days: d));
        final isToday = w == 0 && (d == (now.weekday - 1));
        final isPastDayInCurrentWeek = w == 0 && (d < (now.weekday - 1));

        double amount = 0;
        int tows = 0;
        double hours = 0;
        double rating = 4.95;

        if (isToday) {
          amount = todayEarned;
          tows = completedCount;
          hours = driver.isOnline ? 3.5 : 0.0;
        } else if (isPastDayInCurrentWeek || w > 0) {
          tows = (driver.totalTows > 0) ? ((driver.totalTows ~/ 45) + (d % 2)) : 0;
          amount = tows * 85.0;
          hours = tows > 0 ? (tows * 1.2) : 0.0;
        }

        days.add(
          DailyPerformance(
            dayName: dayNames[d],
            fullDayName: fullDayNames[d],
            dateString: '${_monthName(dayDate.month)} ${dayDate.day.toString().padLeft(2, '0')}',
            amount: amount,
            completedTows: tows,
            onlineHours: hours,
            rating: rating,
          ),
        );
      }

      generatedWeeks.add(WeeklyData(dateRange: dateRangeStr, days: days));
    }

    return generatedWeeks;
  }

  String _monthName(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[(month - 1) % 12];
  }

  void _goToPreviousWeek() {
    if (_selectedWeekIndex > 0) {
      setState(() {
        _selectedWeekIndex--;
      });
    }
  }

  void _goToNextWeek() {
    if (_selectedWeekIndex < _weeks.length - 1) {
      setState(() {
        _selectedWeekIndex++;
      });
    }
  }

  void _goToPreviousDay() {
    setState(() {
      if (_selectedDayIndex > 0) {
        _selectedDayIndex--;
      } else if (_selectedWeekIndex > 0) {
        _selectedWeekIndex--;
        _selectedDayIndex = 6;
      }
    });
  }

  void _goToNextDay() {
    setState(() {
      if (_selectedDayIndex < 6) {
        _selectedDayIndex++;
      } else if (_selectedWeekIndex < _weeks.length - 1) {
        _selectedWeekIndex++;
        _selectedDayIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentWeek = _weeks[_selectedWeekIndex];
    final selectedDay = currentWeek.days[_selectedDayIndex];

    final canGoPrevDay = _selectedDayIndex > 0 || _selectedWeekIndex > 0;
    final canGoNextDay = _selectedDayIndex < 6 || _selectedWeekIndex < _weeks.length - 1;

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
              valueListenable: _jobService.driverNotifier,
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
                          Expanded(child: _buildStatItem('Completed Tows', '${driver.totalTows} trips')),
                          Expanded(child: _buildStatItem('Driver Rating', '${driver.rating.toStringAsFixed(2)} ★')),
                          Expanded(child: _buildStatItem('Weekly Total', '\$${currentWeek.totalEarnings.toStringAsFixed(2)}')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 2. Interactive Weekly Performance Card with Day-Wise Inspection
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
                  // Header Row with Title and Previous/Next Week Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Weekly Performance',
                          style: TextStyle(
                            color: DriverColors.textNavy,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Week Stepper (Prev / Next week)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        decoration: BoxDecoration(
                          color: DriverColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DriverColors.surfaceBorderLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _selectedWeekIndex > 0 ? _goToPreviousWeek : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    size: 18,
                                    color: _selectedWeekIndex > 0
                                        ? DriverColors.textNavy
                                        : DriverColors.textMuted.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                currentWeek.dateRange,
                                style: const TextStyle(
                                  color: DriverColors.textNavy,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _selectedWeekIndex < _weeks.length - 1 ? _goToNextWeek : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: _selectedWeekIndex < _weeks.length - 1
                                        ? DriverColors.textNavy
                                        : DriverColors.textMuted.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 7-Day Performance Bar Chart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(currentWeek.days.length, (index) {
                      final dayData = currentWeek.days[index];
                      final isSelected = index == _selectedDayIndex;
                      return Expanded(
                        child: _buildDayBar(
                          dayData,
                          currentWeek.maxAmount,
                          isSelected,
                          () {
                            setState(() {
                              _selectedDayIndex = index;
                            });
                          },
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: DriverColors.surfaceBorderLight),
                  const SizedBox(height: 14),

                  // Day-Wise Detailed Performance Section with Day Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Prev Day Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: canGoPrevDay ? _goToPreviousDay : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                            decoration: BoxDecoration(
                              color: canGoPrevDay
                                  ? DriverColors.surfaceSubtle
                                  : DriverColors.surfaceSubtle.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: DriverColors.surfaceBorderLight),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chevron_left_rounded,
                                  size: 16,
                                  color: canGoPrevDay
                                      ? DriverColors.textNavy
                                      : DriverColors.textMuted,
                                ),
                                const SizedBox(width: 1),
                                Text(
                                  'Prev',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: canGoPrevDay
                                        ? DriverColors.textNavy
                                        : DriverColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Day & Date Title
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: DriverColors.electricBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                '${selectedDay.fullDayName}, ${selectedDay.dateString}',
                                style: const TextStyle(
                                  color: DriverColors.textNavy,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Next Day Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: canGoNextDay ? _goToNextDay : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                            decoration: BoxDecoration(
                              color: canGoNextDay
                                  ? DriverColors.surfaceSubtle
                                  : DriverColors.surfaceSubtle.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: DriverColors.surfaceBorderLight),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Next',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: canGoNextDay
                                        ? DriverColors.textNavy
                                        : DriverColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 1),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: canGoNextDay
                                      ? DriverColors.textNavy
                                      : DriverColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 4-Card Day Metric Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: DriverColors.surfaceBorderLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: DriverColors.emeraldDark,
                            iconBg: DriverColors.greenTint,
                            label: 'Day Revenue',
                            value: selectedDay.fullAmountFormatted,
                          ),
                        ),
                        Container(width: 1, height: 32, color: DriverColors.surfaceBorder),
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.fire_truck_rounded,
                            iconColor: DriverColors.electricBlue,
                            iconBg: DriverColors.blueTint,
                            label: 'Completed',
                            value: '${selectedDay.completedTows} tows',
                          ),
                        ),
                        Container(width: 1, height: 32, color: DriverColors.surfaceBorder),
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.timer_outlined,
                            iconColor: const Color(0xFFD97706),
                            iconBg: const Color(0xFFFEF3C7),
                            label: 'Online Time',
                            value: '${selectedDay.onlineHours} hrs',
                          ),
                        ),
                        Container(width: 1, height: 32, color: DriverColors.surfaceBorder),
                        Expanded(
                          child: _buildMetricItem(
                            icon: Icons.analytics_outlined,
                            iconColor: const Color(0xFF7C3AED),
                            iconBg: const Color(0xFFF3E8FF),
                            label: 'Avg / Tow',
                            value: selectedDay.avgPerTowFormatted,
                          ),
                        ),
                      ],
                    ),
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
              valueListenable: _jobService.completedJobsNotifier,
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

  Widget _buildDayBar(
    DailyPerformance dayData,
    double maxAmount,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final heightPct = (dayData.amount / maxAmount).clamp(0.2, 1.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: isSelected ? 10 : 9,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? DriverColors.electricBlue : DriverColors.textSecondary,
            ),
            child: Text(dayData.amountFormatted),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: 24,
            height: 82 * heightPct,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              color: isSelected ? null : DriverColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isSelected ? const Color(0xFF1D4ED8) : DriverColors.surfaceBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dayData.dayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? DriverColors.textNavy : DriverColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 4 : 0,
            height: isSelected ? 4 : 0,
            decoration: const BoxDecoration(
              color: DriverColors.electricBlue,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: DriverColors.textNavy,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            color: DriverColors.textSecondary,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
