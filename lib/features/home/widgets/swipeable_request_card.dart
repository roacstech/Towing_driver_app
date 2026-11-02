import 'package:flutter/material.dart';
import '../../../core/services/driver_sound_service.dart';
import '../../jobs/models/tow_job.dart';

class SwipeableRequestCard extends StatefulWidget {
  final TowJob job;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTap;
  final bool isInteractive;

  const SwipeableRequestCard({
    super.key,
    required this.job,
    required this.onAccept,
    required this.onReject,
    required this.onTap,
    this.isInteractive = true,
  });

  @override
  State<SwipeableRequestCard> createState() => _SwipeableRequestCardState();
}

class _SwipeableRequestCardState extends State<SwipeableRequestCard>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  late AnimationController _springController;
  late Animation<double> _springAnimation;
  bool _isCommitting = false;

  static const double _swipeThreshold = 95.0;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    // Zero sound on start
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!widget.isInteractive || _isCommitting) return;
    setState(() {
      _dragOffset += details.delta.dx;
    });
    // NO premature sound during dragging!
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!widget.isInteractive || _isCommitting) return;

    final velocity = details.velocity.pixelsPerSecond.dx;

    if (_dragOffset > _swipeThreshold || velocity > 400) {
      _commitSwipe(isAccept: true);
    } else if (_dragOffset < -_swipeThreshold || velocity < -400) {
      _commitSwipe(isAccept: false);
    } else {
      _springBack();
    }
  }

  void _commitSwipe({required bool isAccept}) {
    if (_isCommitting) return;
    _isCommitting = true;

    // Play sound EXACTLY ONCE on commit
    if (isAccept) {
      DriverSoundService.playAcceptSound();
    } else {
      DriverSoundService.playPassSound();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = isAccept ? screenWidth * 1.3 : -screenWidth * 1.3;

    _springAnimation = Tween<double>(
      begin: _dragOffset,
      end: targetX,
    ).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragOffset = _springAnimation.value;
        });
      });

    _springController.forward(from: 0).then((_) {
      if (isAccept) {
        widget.onAccept();
      } else {
        widget.onReject();
      }
      if (mounted) {
        setState(() {
          _dragOffset = 0.0;
          _isCommitting = false;
        });
      }
    });
  }

  void _springBack() {
    _springAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
    )..addListener(() {
        setState(() {
          _dragOffset = _springAnimation.value;
        });
      });

    _springController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    // Smooth 3D translation and slight tilt rotation for active card
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..translate(_dragOffset, 0.0)
      ..rotateZ(_dragOffset * 0.0005);

    return GestureDetector(
      onHorizontalDragStart: widget.isInteractive ? _onHorizontalDragStart : null,
      onHorizontalDragUpdate: widget.isInteractive ? _onHorizontalDragUpdate : null,
      onHorizontalDragEnd: widget.isInteractive ? _onHorizontalDragEnd : null,
      onTap: widget.onTap,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: transform,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Clean Hero Vehicle Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Image.asset(
                  job.vehicleImage,
                  height: 135,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 135,
                      width: double.infinity,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(
                          Icons.fire_truck_rounded,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 2. Clean Spacious Card Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title, Distance & Payout Header Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Category Badge + Service Title + Distance & Vehicle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E3A8A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.directions_car_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Flexible(
                                    child: Text(
                                      job.requestType,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.near_me_rounded,
                                    size: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${job.distanceToPickup} • ${job.pickupEta}',
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '• ${job.vehicleName}',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
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
                        const SizedBox(width: 10),

                        // Right Column: Price ($180) & Est. Earnings
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              job.payoutWhole,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const Text(
                              'Est. Earnings',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Pickup Address Row with dedicated badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF2563EB),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PICKUP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                job.pickupAddress,
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Dropoff Address Row with dedicated badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF2F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFEF4444),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DROPOFF',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                job.dropAddress,
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tags Row: e.g. Urgent Priority, Full-Size
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: job.tags.map((tag) {
                        final isPurple = tag.toLowerCase().contains('long') ||
                            tag.toLowerCase().contains('distance') ||
                            tag.toLowerCase().contains('urgent');
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isPurple
                                ? const Color(0xFFF3E8FF)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: isPurple
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFF475569),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 3. Clean Polished Action Buttons (52px Height)
                    Row(
                      children: [
                        // Clean Modern Pass Button (Flex 4)
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: 52,
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(26),
                                splashColor: const Color(0xFFF1F5F9),
                                highlightColor: const Color(0xFFF8FAFC),
                                onTap: () => _commitSwipe(isAccept: false),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.close_rounded,
                                        color: Color(0xFF64748B),
                                        size: 20,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Pass',
                                        style: TextStyle(
                                          color: Color(0xFF334155),
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Vibrant Emerald Accept Button (Flex 6)
                        Expanded(
                          flex: 6,
                          child: SizedBox(
                            height: 52,
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(26),
                                onTap: () => _commitSwipe(isAccept: true),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(26),
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
                                      Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      SizedBox(width: 7),
                                      Text(
                                        'Accept',
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
