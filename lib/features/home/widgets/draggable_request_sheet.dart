import 'package:flutter/material.dart';
import '../../../core/constants/driver_colors.dart';
import '../../jobs/models/tow_job.dart';
import 'request_preview.dart';
import 'swipeable_request_card.dart';

class DraggableRequestSheet extends StatelessWidget {
  final List<TowJob> requests;
  final Function(TowJob) onAccept;
  final Function(TowJob) onReject;
  final Function(TowJob) onTapJob;
  final VoidCallback onSeeAll;
  final VoidCallback onResetDemo;

  const DraggableRequestSheet({
    super.key,
    required this.requests,
    required this.onAccept,
    required this.onReject,
    required this.onTapJob,
    required this.onSeeAll,
    required this.onResetDemo,
  });

  @override
  Widget build(BuildContext context) {
    final hasRequests = requests.isNotEmpty;
    final topJob = hasRequests ? requests.first : null;
    final nextJob = requests.length > 1 ? requests[1] : null;

    return Container(
      decoration: const BoxDecoration(
        color: DriverColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: DriverColors.bottomSheetShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Sleek Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: DriverColors.surfaceBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Header Row: "Nearby Requests", live count badge, "See All"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
                        child: Text(
                          'Nearby Requests',
                          style: TextStyle(
                            color: DriverColors.textNavy,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Live Count Badge with emerald dot
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: hasRequests ? DriverColors.greenTint : DriverColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasRequests ? DriverColors.greenBorder : DriverColors.surfaceBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: hasRequests ? DriverColors.emeraldGreen : DriverColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasRequests ? '${requests.length} LIVE' : 'IDLE',
                              style: TextStyle(
                                color: hasRequests ? DriverColors.emeraldDark : DriverColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // "See All" Action
                GestureDetector(
                  onTap: onSeeAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: DriverColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            color: DriverColors.electricBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: DriverColors.electricBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Card Stack or Empty Queue View
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: hasRequests
                ? Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Underneath Peeking Card Preview
                      if (nextJob != null) RequestPreview(job: nextJob),

                      // Prominent Active Swipeable Card
                      SwipeableRequestCard(
                        key: ValueKey(topJob!.id),
                        job: topJob,
                        onAccept: () => onAccept(topJob),
                        onReject: () => onReject(topJob),
                        onTap: () => onTapJob(topJob),
                      ),
                    ],
                  )
                : _buildEmptyRadarState(),
          ),

          // Stack Pagination Dots indicator
          if (hasRequests) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                requests.length > 5 ? 5 : requests.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == 0 ? 16 : 6,
                  height: 5,
                  decoration: BoxDecoration(
                    color: index == 0 ? DriverColors.electricBlue : DriverColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEmptyRadarState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: DriverColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DriverColors.surfaceBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: DriverColors.cardShadow,
            ),
            child: const Icon(
              Icons.radar_rounded,
              color: DriverColors.electricBlue,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Dispatch Radar Active',
            style: TextStyle(
              color: DriverColors.textNavy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Searching your 10-mile radius for new roadside and towing calls. Stay online to maintain priority queue placement.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DriverColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onResetDemo,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reload Available Requests'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DriverColors.electricBlue,
              side: const BorderSide(color: DriverColors.blueBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
