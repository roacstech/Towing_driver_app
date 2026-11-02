import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../jobs/models/tow_job.dart';
import 'swipeable_request_card.dart';

class CenteredLayeredCardStack extends StatelessWidget {
  final List<TowJob> requests;
  final bool isOnline;
  final VoidCallback? onGoOnline;
  final Function(TowJob) onAccept;
  final Function(TowJob) onReject;
  final Function(TowJob) onTapJob;
  final VoidCallback onResetDemo;

  const CenteredLayeredCardStack({
    super.key,
    required this.requests,
    this.isOnline = true,
    this.onGoOnline,
    required this.onAccept,
    required this.onReject,
    required this.onTapJob,
    required this.onResetDemo,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline) {
      return _buildOfflineState();
    }

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

  Widget _buildOfflineState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: const Icon(
              Icons.power_settings_new_rounded,
              color: Color(0xFF64748B),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "You're Currently Offline",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Go online to receive nearby towing calls, roadside recoveries, and high-priority dispatch requests.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onGoOnline?.call();
                },
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Go Online Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
