import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../onboarding/screens/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  final Widget? nextScreen;
  const SplashScreen({super.key, this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _hoverController;
  late AnimationController _progressController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  String _statusText = 'Connecting to Central Towing...';
  Timer? _statusTimer1;
  Timer? _statusTimer2;
  Timer? _navTimer;
  bool _loadingCompleted = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Smooth entrance fade & scale (800ms)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 2. Subtle organic floating hover for vehicle (2200ms loop)
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 3. Smooth progress bar animation (2500ms)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _entryController.forward();
    _hoverController.repeat(reverse: true);
    _progressController.forward();

    // Staged status updates
    _statusTimer1 = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _statusText = 'Syncing telemetry & GPS routes...';
        });
      }
    });

    _statusTimer2 = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _statusText = 'Driver console online';
        });
      }
    });

    // When progress hits 100%, show ready state, then auto-navigate to the welcome splash screen
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _loadingCompleted = true;
          _statusText = 'Ready for dispatches';
        });

        _navTimer = Timer(const Duration(milliseconds: 700), () {
          if (mounted) {
            _navigateToNext();
          }
        });
      }
    });
  }

  void _navigateToNext() {
    if (_navigated) return;
    _navigated = true;
    _navTimer?.cancel();
    final target = widget.nextScreen ?? const DriverWelcomeScreen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: RouteSettings(
          name: target is DriverWelcomeScreen ? '/welcome' : '/dashboard',
        ),
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 650),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _hoverController.dispose();
    _progressController.dispose();
    _statusTimer1?.cancel();
    _statusTimer2?.cancel();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          onTap: () {
            if (_loadingCompleted) {
              _navigateToNext();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
            // Soft ambient light backdrop glow matching customer app
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryOrange.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0284C7).withValues(alpha: 0.03),
                ),
              ),
            ),

            // Foreground Content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 1. Top Header Pill: 24/7 Verified Dispatch
                          Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7.5,
                                    height: 7.5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF10B981),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'DRIVER DISPATCH NETWORK',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 2. Realistic 3D Tow Truck Vehicle & Driver Partner Identity
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 3D Vehicle Showcase with subtle breathing hover
                              AnimatedBuilder(
                                animation: _hoverController,
                                builder: (context, child) {
                                  final hoverOffset =
                                      math.sin(_hoverController.value * math.pi) *
                                          3.5;
                                  return Transform.translate(
                                    offset: Offset(0, -hoverOffset),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(
                                    maxWidth: 340,
                                    maxHeight: 220,
                                  ),
                                  child: Image.asset(
                                    'assets/images/central_tow_truck_3d.jpg',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 180,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.local_shipping_rounded,
                                          size: 80,
                                          color: AppColors.primaryOrange,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Properly Aligned Typography: CENTRAL TOWING
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'CENTRAL ',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 3.0,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'TOWING',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 3.0,
                                            color: AppColors.primaryOrange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Driver Partner Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primaryOrange
                                        .withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.badge_outlined,
                                      size: 13,
                                      color: AppColors.primaryOrange,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'DRIVER PARTNER CONSOLE',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.4,
                                        color: AppColors.primaryOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Tagline Pill
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.shield_outlined,
                                          size: 13,
                                          color: AppColors.primaryOrange,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'RAPID ROADSIDE & VEHICLE RECOVERY',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // 3. Bottom Minimal Progress & Non-Overlapping Status
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 36,
                              left: 20,
                              right: 20,
                            ),
                            child: AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                final percent =
                                    (_progressAnimation.value * 100).toInt();

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Progress Bar + Live Percentage Counter
                                    Container(
                                      width: double.infinity,
                                      constraints:
                                          const BoxConstraints(maxWidth: 220),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'INITIALIZING',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 1.0,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              ),
                                              Text(
                                                '$percent%',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      AppColors.primaryOrange,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: LinearProgressIndicator(
                                                value: _progressAnimation.value,
                                                minHeight: 4,
                                                backgroundColor:
                                                    const Color(0xFFF1F5F9),
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                        Color>(
                                                  AppColors.primaryOrange,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Dynamic Clean Non-Overlapping Status Text
                                    SizedBox(
                                      height: 20,
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          layoutBuilder: (currentChild,
                                              previousChildren) {
                                            return currentChild ??
                                                const SizedBox.shrink();
                                          },
                                          transitionBuilder:
                                              (child, animation) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                          child: Text(
                                            _statusText,
                                            key: ValueKey<String>(_statusText),
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: _loadingCompleted
                                                  ? AppColors.primaryOrange
                                                  : const Color(0xFF64748B),
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  ],
                                );
                              },
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
      ),
    ),
  );
}
}
