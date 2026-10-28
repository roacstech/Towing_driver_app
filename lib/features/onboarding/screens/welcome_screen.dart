import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class DriverWelcomeScreen extends StatefulWidget {
  const DriverWelcomeScreen({super.key});

  @override
  State<DriverWelcomeScreen> createState() => _DriverWelcomeScreenState();
}

class _DriverWelcomeScreenState extends State<DriverWelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_driver_welcome', true);
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/dashboard'),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _onNext() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            // 1. PageView for 4 welcome screens
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildScreenOne(),
                _buildScreenTwo(),
                _buildScreenThree(),
                _buildScreenFour(),
              ],
            ),

            // 2. Top Header: Skip Button
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _completeOnboarding,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Bottom Navigation: Indicator + Next/Check CTA Button
            Positioned(
              left: 24,
              right: 24,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Dots Indicator
                      Row(
                        children: List.generate(4, (index) {
                          final bool isActive = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 7),
                            width: isActive ? 34 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primaryOrange
                                  : AppColors.indicatorInactive,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      // Circular Action Button
                      GestureDetector(
                        onTap: _onNext,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryOrange
                                    .withValues(alpha: 0.42),
                                blurRadius: 18,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _currentPage == 3
                                  ? const Icon(
                                      Icons.check_rounded,
                                      key: ValueKey('check'),
                                      color: Colors.white,
                                      size: 32,
                                    )
                                  : const Icon(
                                      Icons.arrow_forward_rounded,
                                      key: ValueKey('arrow'),
                                      color: Colors.white,
                                      size: 28,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SCREEN 1: READY FOR THE ROAD ---
  Widget _buildScreenOne() {
    return _buildPageLayout(
      bgImagePath: 'assets/images/driver_bg_1.png',
      category: '24/7 ROADSIDE DISPATCH',
      titleLine1: 'READY',
      titleLine2: 'FOR THE',
      highlightWord: 'ROAD',
      subtitle:
          'Instant towing dispatches, live navigation routes, and swift recovery response.',
    );
  }

  // --- SCREEN 2: REAL-TIME JOB ALERTS ---
  Widget _buildScreenTwo() {
    return _buildPageLayout(
      bgImagePath: 'assets/images/driver_bg_2.png',
      category: 'SMART DISPATCH CONSOLE',
      titleLine1: 'REAL-TIME',
      titleLine2: 'DISPATCH',
      highlightWord: 'ALERTS',
      subtitle:
          'Accept nearby towing jobs in one tap with full route telemetry and vehicle data.',
    );
  }

  // --- SCREEN 3: SECURE VEHICLE HANDLING ---
  Widget _buildScreenThree() {
    return _buildPageLayout(
      bgImagePath: 'assets/images/driver_bg_3.png',
      category: 'SAFETY & PROTOCOLS',
      titleLine1: 'SECURE',
      titleLine2: 'VEHICLE',
      highlightWord: 'RECOVERY',
      subtitle:
          'Certified loading checklists and photo inspection for peace of mind.',
      extraContent: Column(
        children: [
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  icon: Icons.assignment_turned_in_rounded,
                  title: 'Photo Inspection',
                  subtitle: 'Document condition\nbefore hookup',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildServiceCard(
                  icon: Icons.shield_rounded,
                  title: 'Secure Tie-Down',
                  subtitle: 'Heavy-duty ratchet\nwheel safety',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  icon: Icons.near_me_rounded,
                  title: 'Turn-by-Turn',
                  subtitle: 'Direct navigation\nto destination',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildServiceCard(
                  icon: Icons.speed_rounded,
                  title: 'ETA Telemetry',
                  subtitle: 'Customer live\ntracking updates',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SCREEN 4: DRIVER PARTNER FLEET ---
  Widget _buildScreenFour() {
    return _buildPageLayout(
      bgImagePath: 'assets/images/driver_bg_4.png',
      category: 'DRIVER PARTNER FLEET',
      titleLine1: 'Earn More.',
      titleLine2: 'Drive Safe.',
      highlightWord: 'Central Towing.',
      subtitle:
          'Guaranteed dispatch flow, transparent payouts, and 24/7 roadside driver support.',
      extraContent: Column(
        children: [
          const SizedBox(height: 20),
          _buildFeatureCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Direct Weekly Payouts',
            subtitle: 'Track your trip fares and bonuses in real-time',
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            icon: Icons.headset_mic_rounded,
            title: '24/7 Dispatch Control',
            subtitle: 'Immediate operator assistance on the road',
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            icon: Icons.stars_rounded,
            title: 'Partner Rewards',
            subtitle: 'Tiered incentive bonuses for top driver ratings',
          ),
        ],
      ),
    );
  }

  // Reusable page layout wrapper matching customer app's welcome screen
  Widget _buildPageLayout({
    required String bgImagePath,
    required String category,
    required String titleLine1,
    required String titleLine2,
    required String highlightWord,
    required String subtitle,
    Widget? extraContent,
  }) {
    return Stack(
      children: [
        // Background Photo
        Positioned.fill(
          child: Image.asset(
            bgImagePath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF0F172A),
            ),
          ),
        ),

        // Gradient overlay at the top for maximum text contrast
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.32, 0.62, 1.0],
                colors: [
                  Colors.white.withValues(alpha: 0.97),
                  Colors.white.withValues(alpha: 0.86),
                  Colors.white.withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Foreground Content
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 62, 24, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Tag
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                        color: AppColors.categoryGray,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Main Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (titleLine1.isNotEmpty)
                      Text(
                        titleLine1,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: AppColors.titleNavy,
                          height: 1.1,
                          letterSpacing: -0.6,
                        ),
                      ),
                    if (titleLine2.isNotEmpty)
                      Text(
                        titleLine2,
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: AppColors.titleNavy,
                          height: 1.1,
                          letterSpacing: -0.6,
                        ),
                      ),
                    Text(
                      highlightWord,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryOrange,
                        height: 1.1,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF334155),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Extra content cards (Screen 3 & 4)
                ?extraContent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2x2 Service Card (Screen 3)
  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.customCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.customCardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.customCardMainText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.customCardDescText,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // Linear Feature Card (Screen 4)
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.customCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.customCardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.customCardMainText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.customCardDescText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
