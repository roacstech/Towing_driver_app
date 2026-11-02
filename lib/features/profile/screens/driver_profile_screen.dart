import 'package:flutter/material.dart';
import '../../../core/localization/driver_language_service.dart';
import '../../auth/screens/driver_login_screen.dart';
import '../../auth/services/driver_auth_service.dart';
import '../../documents/screens/driver_document_upload_screen.dart';
import '../../jobs/services/driver_job_service.dart';
import '../models/driver_profile.dart';
import 'driver_logout_feedback_screen.dart';
import 'edit_driver_profile_screen.dart';
import 'faq_guidelines_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final DriverJobService _jobService = DriverJobService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'my_profile'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: InkWell(
                onTap: () => _showHelpSheet(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB), width: 1.2),
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.headset_mic_outlined, size: 16, color: Colors.black87),
                      const SizedBox(width: 6),
                      Text(
                        'help'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
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
      body: ValueListenableBuilder<DriverProfile>(
        valueListenable: _jobService.driverNotifier,
        builder: (context, driver, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // 1. Decorative Banner + Overlapping Avatar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 160,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Banner Image Container
                        Container(
                          width: double.infinity,
                          height: 116,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/profile_banner.png',
                              width: double.infinity,
                              height: 116,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFE11D48), Color(0xFFF97316), Color(0xFF991B1B)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.location_city_rounded,
                                      color: Colors.white24,
                                      size: 54,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Overlapping Avatar
                        Positioned(
                          top: 74,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFE5E7EB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                size: 44,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 2. Driver Name
                Text(
                  driver.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 22),

                // 3. Quick Stats Row (4.9 Rating, 546 Orders, 5 Months)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Rating Column
                      InkWell(
                        onTap: () => _showRatingBreakdown(context, driver),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    driver.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFFFB800),
                                    size: 24,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'rating'.tr,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Orders Column
                      Column(
                        children: [
                          Text(
                            '${driver.totalTows}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'orders'.tr,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),

                      // Months Column
                      Column(
                        children: [
                          Text(
                            '${driver.monthsActive}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'months'.tr,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 4. Subtle Thin Divider
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Divider(
                    color: Color(0xFFE5E7EB),
                    thickness: 1,
                    height: 1,
                  ),
                ),

                // 5. Menu List Items
                _buildMenuItem(
                  icon: Icons.speed_rounded,
                  title: 'best_performance'.tr,
                  onTap: () => _showPerformanceSheet(context, driver),
                ),
                _buildMenuItem(
                  icon: Icons.account_circle_outlined,
                  title: 'profile_info'.tr,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditDriverProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.badge_outlined,
                  title: 'id_card'.tr,
                  onTap: () => _showIdCardDialog(context, driver),
                ),
                _buildMenuItem(
                  icon: Icons.folder_shared_outlined,
                  title: 'documents'.tr,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DriverDocumentUploadScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.translate_rounded,
                  title: 'language_settings'.tr,
                  onTap: () => _showLanguageDialog(context),
                ),

                const SizedBox(height: 32),

                // 6. Logout Button (Outlined Pill)
                Container(
                  width: double.infinity,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: OutlinedButton(
                    onPressed: () => _confirmLogout(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.power_settings_new_rounded, size: 18, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          'logout'.tr,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 7. Delete Account Button (Solid Dark Black / Burgundy Pill)
                Container(
                  width: double.infinity,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton(
                    onPressed: () => _confirmDeleteAccount(context),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF1D0B09),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'delete_account'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0xFFF3F4F6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFF1F2937),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: Color(0xFF111827),
            ),
          ],
        ),
      ),
    );
  }

  // --- Modals & Sheets ---

  void _showPerformanceSheet(BuildContext context, DriverProfile driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.speed_rounded, color: Color(0xFF2563EB), size: 24),
                SizedBox(width: 10),
                Text(
                  'Best Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPerfMetric('Acceptance Rate', '98.5%', 'Top 5% in your hub', const Color(0xFF10B981)),
            _buildPerfMetric('Completion Rate', '99.2%', '542 of 546 orders fulfilled', const Color(0xFF10B981)),
            _buildPerfMetric('Customer Rating', '${driver.rating} ★', 'Based on 490 driver reviews', const Color(0xFFF59E0B)),
            _buildPerfMetric('On-Time Arrival', '97.0%', 'Average response time 8 mins', const Color(0xFF2563EB)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfMetric(String title, String val, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
              ],
            ),
            Text(
              val,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _showIdCardDialog(BuildContext context, DriverProfile driver) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.badge_rounded, color: Color(0xFFD97706), size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ID Card',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              // ID Card preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'CAPTAIN · VERIFIED',
                                style: TextStyle(
                                  color: Color(0xFF34D399),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${driver.id}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Vehicle Plate:',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            driver.licensePlate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                  label: const Text('Download Digital ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRatingBreakdown(BuildContext context, DriverProfile driver) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  driver.rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 36),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outstanding Rating', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('Based on 490 customer trips', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStarBar(5, 0.92),
            _buildStarBar(4, 0.06),
            _buildStarBar(3, 0.01),
            _buildStarBar(2, 0.01),
            _buildStarBar(1, 0.00),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarBar(int star, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$star', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: const Color(0xFFF3F4F6),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB800)),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(percent * 100).toInt()}%',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languages = ['English', 'हिन्दी (Hindi)', 'தமிழ் (Tamil)', 'తెలుగు (Telugu)', 'ಕನ್ನಡ (Kannada)'];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.translate_rounded, color: Colors.black),
              const SizedBox(width: 10),
              Text('select_language'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              final isSelected = DriverLanguageService().currentLanguage == lang;
              return InkWell(
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await DriverLanguageService().setLanguage(lang);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    setState(() {});
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('lang_updated'.tr),
                        backgroundColor: Colors.black87,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? Colors.black : const Color(0xFF4B5563),
                          fontSize: 14.5,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '24/7 Driver Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.phone_in_talk_rounded, color: Color(0xFF2563EB)),
              ),
              title: const Text('Towing Emergency Helpline', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Instant support for active job emergencies'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connecting to Towing Emergency Helpline...')),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFECFDF5),
                child: Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF10B981)),
              ),
              title: const Text('WhatsApp Chat Support', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Replies within 2 minutes'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening WhatsApp Support...')),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFFBEB),
                child: Icon(Icons.help_outline_rounded, color: Color(0xFFF59E0B)),
              ),
              title: const Text('FAQs & Guidelines', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Earnings, incentives & safety policies'),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FaqGuidelinesScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Close Button 'X'
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280), size: 24),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),

            // Large Yellow / Golden Logout Icon
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              child: const Icon(
                Icons.logout_rounded,
                size: 58,
                color: Color(0xFFFFC000),
              ),
            ),

            // Title
            Text(
              'logout'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 6),

            // Subtitle
            Text(
              'are_you_sure_logout'.tr,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),

            const SizedBox(height: 24),

            // "Yes" Button (Filled Yellow Pill)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DriverLogoutFeedbackScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFFFC000),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'yes'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // "Cancel" Button (Outlined Pill)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  'cancel'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('delete_account'.tr, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
        content: Text('cannot_be_undone'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DriverAuthService().logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account successfully deleted.')),
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D0B09),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('delete'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
