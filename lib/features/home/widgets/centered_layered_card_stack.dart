import 'package:flutter/material.dart';
import '../../jobs/models/tow_job.dart';
import 'swipeable_request_card.dart';

class CenteredLayeredCardStack extends StatelessWidget {
  final List<TowJob> requests;
  final Function(TowJob) onAccept;
  final Function(TowJob) onReject;
  final Function(TowJob) onTapJob;
  final VoidCallback onResetDemo;

  const CenteredLayeredCardStack({
    super.key,
    required this.requests,
    required this.onAccept,
    required this.onReject,
    required this.onTapJob,
    required this.onResetDemo,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    final topJob = requests.first;
    final hasSecond = requests.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Layered Stack with subtle deck depth
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // Underneath peeking card (subtle 5px lip behind active card)
            if (hasSecond)
              Positioned(
                top: -5,
                left: 12,
                right: 12,
                bottom: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                ),
              ),

            // Foreground Active Card
            SwipeableRequestCard(
              key: ValueKey(topJob.id),
              job: topJob,
              onAccept: () => onAccept(topJob),
              onReject: () => onReject(topJob),
              onTap: () => onTapJob(topJob),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Carousel Queue Indicator & Swipe Instructions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                requests.length > 5 ? 5 : requests.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: index == 0 ? 14 : 5,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '← Swipe to Pass / Accept →',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0B1527),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF10B981),
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'All Dispatches Reviewed',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You are online. New nearby towing and recovery calls will appear automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onResetDemo,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reset Demo Jobs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
