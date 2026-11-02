import 'package:flutter/material.dart';
import '../../../core/constants/driver_colors.dart';
import '../models/tow_job.dart';
import '../services/driver_job_service.dart';
import 'trip_details_screen.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final DriverJobService _jobService = DriverJobService();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filters = [
    'All',
    'Nearby (< 2 mi)',
    'Urgent',
    'Highest Payout',
    'Accident Recovery',
    'Flat Tire',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                color: DriverColors.textNavy,
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Available Requests',
          style: TextStyle(
            color: DriverColors.textNavy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ValueListenableBuilder<List<TowJob>>(
              valueListenable: _jobService.availableRequestsNotifier,
              builder: (context, requests, _) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DriverColors.greenTint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DriverColors.greenBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: DriverColors.emeraldGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${requests.length} LIVE',
                          style: const TextStyle(
                            color: DriverColors.emeraldDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<TowJob>>(
        valueListenable: _jobService.availableRequestsNotifier,
        builder: (context, allRequests, _) {
          // Apply search and filter
          var filteredList = allRequests.where((job) {
            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final matchesVehicle = job.vehicleName.toLowerCase().contains(q);
              final matchesType = job.requestType.toLowerCase().contains(q);
              final matchesAddress = job.pickupAddress.toLowerCase().contains(q);
              if (!matchesVehicle && !matchesType && !matchesAddress) return false;
            }

            switch (_selectedFilter) {
              case 'Nearby (< 2 mi)':
                final distNum = double.tryParse(job.distanceToPickup.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                return distNum <= 2.0;
              case 'Urgent':
                return job.isUrgent;
              case 'Highest Payout':
                return job.estimatedPayout >= 140.0;
              case 'Accident Recovery':
                return job.requestType == 'Accident Recovery';
              case 'Flat Tire':
                return job.requestType == 'Flat Tire';
              case 'All':
              default:
                return true;
            }
          }).toList();

          if (_selectedFilter == 'Highest Payout') {
            filteredList.sort((a, b) => b.estimatedPayout.compareTo(a.estimatedPayout));
          }

          return Column(
            children: [
              // Search & Filter Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: DriverColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DriverColors.surfaceBorderLight),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search by vehicle, service, or location...',
                          hintStyle: TextStyle(
                            color: DriverColors.textMuted,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: DriverColors.textSecondary,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips Bar
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final f = _filters[index];
                          final isSelected = f == _selectedFilter;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilter = f;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DriverColors.textNavy
                                    : DriverColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? DriverColors.textNavy
                                      : DriverColors.surfaceBorder,
                                ),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : DriverColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: DriverColors.surfaceBorder),

              // Vertically Scrollable List of Premium Compact Request Cards
              Expanded(
                child: filteredList.isNotEmpty
                    ? ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        itemCount: filteredList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final job = filteredList[index];
                          return _buildCompactJobCard(context, job);
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: DriverColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No matching requests found',
                              style: TextStyle(
                                color: DriverColors.textNavy,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try clearing filters or search terms',
                              style: TextStyle(
                                color: DriverColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactJobCard(BuildContext context, TowJob job) {
    return Container(
      decoration: BoxDecoration(
        color: DriverColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: job.isUrgent ? DriverColors.redBorder : DriverColors.surfaceBorder,
          width: 1.2,
        ),
        boxShadow: DriverColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => TripDetailsScreen(job: job),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: urgency / service type & payout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (job.isUrgent) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: DriverColors.redTint,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: DriverColors.redBorder),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  color: DriverColors.alertRedDark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: DriverColors.blueTint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                job.requestType,
                                style: const TextStyle(
                                  color: DriverColors.electricBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      job.payoutFormatted,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Middle row: Vehicle photo thumbnail + Vehicle specs + ETA
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 64,
                        height: 46,
                        color: DriverColors.surfaceSubtle,
                        child: Image.asset(
                          job.vehicleImage,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.directions_car,
                              color: DriverColors.textMuted,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${job.vehicleYear} ${job.vehicleName}',
                            style: const TextStyle(
                              color: DriverColors.textNavy,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job.pickupAddress,
                            style: const TextStyle(
                              color: DriverColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: DriverColors.textMuted,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bottom row: Distance & ETA pills
                Row(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          size: 13,
                          color: DriverColors.electricBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          job.distanceToPickup,
                          style: const TextStyle(
                            color: DriverColors.textNavy,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: DriverColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${job.pickupEta} ETA',
                          style: const TextStyle(
                            color: DriverColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        'Details',
                        style: TextStyle(
                          color: DriverColors.electricBlue.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
