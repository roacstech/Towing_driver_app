import 'package:flutter/material.dart';
import '../../../core/constants/driver_colors.dart';
import '../../auth/screens/driver_login_screen.dart';
import '../../auth/services/driver_auth_service.dart';
import '../../documents/screens/driver_document_upload_screen.dart';
import '../../jobs/services/driver_job_service.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobService = DriverJobService();

    return Scaffold(
      backgroundColor: DriverColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: DriverColors.textNavy,
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Driver Profile & Fleet Info',
          style: TextStyle(
            color: DriverColors.textNavy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const BouncingScrollPhysics(),
        child: ValueListenableBuilder(
          valueListenable: jobService.driverNotifier,
          builder: (context, driver, _) {
            return Column(
              children: [
                // 1. Driver Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: DriverColors.surfaceBorder),
                    boxShadow: DriverColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: DriverColors.electricBlue, width: 2.5),
                            ),
                            child: const CircleAvatar(
                              radius: 42,
                              backgroundColor: DriverColors.surfaceSubtle,
                              child: Icon(
                                Icons.person_rounded,
                                color: DriverColors.textNavy,
                                size: 48,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: DriverColors.emeraldGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        driver.name,
                        style: const TextStyle(
                          color: DriverColors.textNavy,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        driver.email,
                        style: const TextStyle(
                          color: DriverColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: DriverColors.amberTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DriverColors.amberBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${driver.rating.toStringAsFixed(2)} Driver Rating · Gold Tier',
                              style: const TextStyle(
                                color: Color(0xFFB45309),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Active Fleet Vehicle Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DriverColors.surfaceBorder),
                    boxShadow: DriverColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ASSIGNED TOW TRUCK',
                            style: TextStyle(
                              color: DriverColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: DriverColors.greenTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'VERIFIED FLEET',
                              style: TextStyle(
                                color: DriverColors.emeraldDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        driver.truckModel,
                        style: const TextStyle(
                          color: DriverColors.textNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Commercial Plate: ${driver.licensePlate}',
                        style: const TextStyle(
                          color: DriverColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SpecBadge('21ft Chevron Bed'),
                          _SpecBadge('10,000 lbs Winch'),
                          _SpecBadge('Wheel-Lift Ready'),
                          _SpecBadge('GoJak System Onboard'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Status Switch Tile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DriverColors.surfaceBorder),
                    boxShadow: DriverColors.cardShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: driver.isOnline ? DriverColors.emeraldGreen : DriverColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver.isOnline ? 'Active on Dispatch Network' : 'Offline / Off-Duty',
                                style: const TextStyle(
                                  color: DriverColors.textNavy,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                driver.isOnline ? 'Receiving priority job offers' : 'Not receiving new requests',
                                style: const TextStyle(
                                  color: DriverColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: driver.isOnline,
                        activeColor: DriverColors.emeraldGreen,
                        onChanged: (val) {
                          jobService.toggleOnlineStatus(val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Driver Documentation & Compliance
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DriverColors.surfaceBorder),
                    boxShadow: DriverColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Credentials & Safety Records',
                        style: TextStyle(
                          color: DriverColors.textNavy,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildDocItem('Commercial Driver License (CDL-A)', 'Verified · Exp. 2028', Icons.badge_outlined),
                      _buildDocItem('DOT Medical Certificate', 'Compliant · Exp. May 2027', Icons.medical_services_outlined),
                      _buildDocItem('Towing & Recovery Association Card', 'Level 2 Certified Master', Icons.card_membership_outlined),
                      const SizedBox(height: 14),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DriverDocumentUploadScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: DriverColors.blueTint,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DriverColors.blueBorder),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                color: DriverColors.electricBlue,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Manage & Upload Documents',
                                      style: TextStyle(
                                        color: DriverColors.textNavy,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Upload CDL, Registration, COI, and DOT Inspection',
                                      style: TextStyle(
                                        color: DriverColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: DriverColors.electricBlue,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 5. Sign Out Driver Account
                ElevatedButton.icon(
                  onPressed: () async {
                    await DriverAuthService().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (ctx) => const DriverLoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign Out Driver Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2),
                    foregroundColor: DriverColors.alertRed,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDocItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DriverColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: DriverColors.textNavy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: DriverColors.textNavy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: DriverColors.emeraldDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: DriverColors.emeraldGreen, size: 18),
        ],
      ),
    );
  }
}

class _SpecBadge extends StatelessWidget {
  final String label;

  const _SpecBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DriverColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DriverColors.surfaceBorderLight),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: DriverColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
