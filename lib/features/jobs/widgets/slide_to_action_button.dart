import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlideToActionButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onSlideComplete;
  final Color baseColor;
  final IconData icon;
  final double height;
  final bool enabled;

  const SlideToActionButton({
    super.key,
    required this.label,
    required this.onSlideComplete,
    this.baseColor = const Color(0xFF2563EB),
    this.icon = Icons.arrow_forward_rounded,
    this.height = 54.0,
    this.enabled = true,
  });

  @override
  State<SlideToActionButton> createState() => _SlideToActionButtonState();
}

class _SlideToActionButtonState extends State<SlideToActionButton>
    with TickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isLoading = false;
  bool _isDragging = false;
  bool _hasHapticTriggered = false;
  double _startX = 0.0;
  double _startOffset = 0.0;

  late AnimationController _springController;
  late Animation<double> _springAnimation;
  late AnimationController _shimmerController;

  static const double _thumbMargin = 4.0;
  // Responsive 25% threshold so the driver never has to slide multiple times
  static const double _completionThreshold = 0.25;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _springController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.enabled || _isLoading) return;
    _isDragging = true;
    _startX = details.globalPosition.dx;
    _startOffset = _dragOffset;
    _springController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (!_isDragging || !widget.enabled || _isLoading) return;

    final delta = details.globalPosition.dx - _startX;
    final newOffset = (_startOffset + delta).clamp(0.0, maxDrag);

    if (newOffset != _dragOffset) {
      setState(() {
        _dragOffset = newOffset;
      });

      if (_dragOffset >= maxDrag * _completionThreshold && !_hasHapticTriggered) {
        _hasHapticTriggered = true;
        HapticFeedback.selectionClick();
      } else if (_dragOffset < maxDrag * _completionThreshold) {
        _hasHapticTriggered = false;
      }
    }
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (!_isDragging) return;
    _isDragging = false;
    _hasHapticTriggered = false;

    if (!widget.enabled || _isLoading) return;

    final progress = maxDrag > 0 ? _dragOffset / maxDrag : 0.0;
    // Trigger if crossed 25% threshold OR if quick velocity swipe to the right
    final velocityX = details.primaryVelocity ?? 0.0;
    if (progress >= _completionThreshold || velocityX > 250) {
      _completeSlide(maxDrag);
    } else {
      _snapBack();
    }
  }

  void _onDragCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    _hasHapticTriggered = false;
    _snapBack();
  }

  void _completeSlide(double maxDrag) {
    if (_isLoading) return;
    HapticFeedback.heavyImpact();

    _springAnimation = Tween<double>(
      begin: _dragOffset,
      end: maxDrag,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutCubic,
    ))..addListener(() {
      setState(() {
        _dragOffset = _springAnimation.value;
      });
    });

    _springController.forward(from: 0).then((_) async {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      try {
        await widget.onSlideComplete();
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _dragOffset = 0.0;
          });
        }
      }
    });
  }

  void _snapBack() {
    _springAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutBack,
    ))..addListener(() {
      setState(() {
        _dragOffset = _springAnimation.value;
      });
    });

    _springController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final thumbSize = widget.height - (_thumbMargin * 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final maxDrag = (totalWidth - thumbSize - (_thumbMargin * 2)).clamp(0.0, totalWidth);
        final progress = maxDrag > 0 ? (_dragOffset / maxDrag).clamp(0.0, 1.0) : 0.0;
        final textOpacity = (1.0 - (progress * 1.6)).clamp(0.0, 1.0);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxDrag),
          onHorizontalDragEnd: (d) => _onDragEnd(d, maxDrag),
          onHorizontalDragCancel: _onDragCancel,
          onTap: () {
            if (widget.enabled && !_isLoading) {
              _completeSlide(maxDrag);
            }
          },
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.baseColor,
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                BoxShadow(
                  color: widget.baseColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 1. Sliding Drag Fill Track Behind Knob (Only shown when actively dragged)
                if (_dragOffset > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: _dragOffset + thumbSize + _thumbMargin,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                  ),

                // 2. Centered Action Label & Shimmer Chevrons
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: textOpacity,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: thumbSize + 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                widget.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 5),
                            AnimatedBuilder(
                              animation: _shimmerController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: 0.45 + (_shimmerController.value * 0.55),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Interactive Sliding Thumb (Constrained strictly inside the track)
                Positioned(
                  left: _thumbMargin + _dragOffset,
                  top: _thumbMargin,
                  bottom: _thumbMargin,
                  width: thumbSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.baseColor,
                                ),
                              ),
                            )
                          : Icon(
                              widget.icon,
                              color: widget.baseColor,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
