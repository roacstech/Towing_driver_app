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
              // 1. Premium Vehicle Showroom Stage (Properly Padded & Centered)
              Container(
                height: 155,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF8FAFC),
                      Color(0xFFEEF2F6),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Showroom Floor Soft Shadow
                    Positioned(
                      bottom: 12,
                      child: Container(
                        width: 200,
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.elliptical(200, 14)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Centered Vehicle Image with Contain Fit
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Center(
                        child: Image.asset(
                          job.vehicleImage,
                          height: 125,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
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
                    ),

                    // Year & Category Pill (Top Left)
                    Positioned(
                      top: 10,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '${job.vehicleYear} · ${job.vehicleCategory}',
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),

                    // Urgent / Distance Pill (Top Right)
                    if (job.isUrgent)
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'URGENT HAZARD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                size: 12,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${job.distanceToPickup} (${job.pickupEta})',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Clean Spacious Card Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title, Vehicle & Payout Header Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Column: Category Icon + Service Title + Vehicle Details
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E3A8A),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.directions_car_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
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
                              const SizedBox(height: 2),
                              Text(
                                job.vehicleName.startsWith(job.vehicleYear)
                                    ? job.vehicleName
                                    : '${job.vehicleYear} ${job.vehicleName}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right Column: Price ($95) & Est. Earnings
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
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Est. Earnings',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Pickup & Dropoff Route Container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          // Pickup Address Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 13,
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
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    Text(
                                      job.pickupAddress,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Vertical route connector
                          Padding(
                            padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 2,
                                  height: 10,
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ],
                            ),
                          ),

                          // Dropoff Address Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF2F2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 13,
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
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    Text(
                                      job.dropAddress,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                        // Compact Icon-Only Pass Button (52x52)
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              splashColor: const Color(0xFFF1F5F9),
                              highlightColor: const Color(0xFFF8FAFC),
                              onTap: () => _commitSwipe(isAccept: false),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFF64748B),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Wide Prominent Accept Button (Expanded to fill remaining width)
                        Expanded(
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
                                        color: const Color(0xFF10B981).withValues(alpha: 0.38),
                                        blurRadius: 14,
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
                                      SizedBox(width: 8),
                                      Text(
                                        'Accept',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
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
