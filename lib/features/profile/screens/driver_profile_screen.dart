import 'package:flutter/material.dart';
import '../../../core/constants/driver_colors.dart';
import '../../documents/screens/driver_document_upload_screen.dart';
import '../../jobs/services/driver_job_service.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = DriverJobService().driver;

    return Scaffold(
      backgroundColor: DriverColors.bgDark,
      appBar: AppBar(
        backgroundColor: DriverColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Driver Profile & Fleet Info',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // 1. Driver Avatar & Rating
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: DriverColors.primaryOrange, width: 3),
                        ),
                        child: const CircleAvatar(
                          radius: 46,
                          backgroundColor: DriverColors.cardDark,
                          child: Icon(Icons.person, color: Colors.white, size: 50),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: DriverColors.onlineGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    driver.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    driver.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${driver.rating.toStringAsFixed(2)} Driver Score',
                          style: const TextStyle(
                            color: Colors.amber,
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
            const SizedBox(height: 24),

            // 2. Tow Truck Details Card
            _buildSectionHeader('ASSIGNED TOW TRUCK'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverColors.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: DriverColors.borderDark),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.fire_truck, 'Vehicle Model', driver.truckModel),
                  const Divider(color: DriverColors.borderDark, height: 24),
                  _buildDetailRow(Icons.badge, 'License Plate', driver.licensePlate),
                  const Divider(color: DriverColors.borderDark, height: 24),
                  _buildDetailRow(Icons.fitness_center, 'Max Tow Capacity', '12,000 lbs (Class 6)'),
                  const Divider(color: DriverColors.borderDark, height: 24),
                  _buildDetailRow(Icons.settings, 'Winch System', '10,000 lb Ramsey Hydraulic'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Verification & Compliance
            _buildSectionHeader('CERTIFICATIONS & COMPLIANCE'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DriverColors.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: DriverColors.borderDark),
              ),
              child: Column(
                children: [
                  _buildComplianceRow('Commercial Driver License (CDL Class A)', true),
                  const SizedBox(height: 14),
                  _buildComplianceRow('Tow Operator Roadside Safety Certified', true),
                  const SizedBox(height: 14),
                  _buildComplianceRow('DOT Annual Vehicle Safety Inspection', true),
                  const SizedBox(height: 14),
                  _buildComplianceRow('Commercial Roadside Liability (\$1M)', true),
                  const SizedBox(height: 16),
                  const Divider(color: DriverColors.borderDark, height: 1),
                  const SizedBox(height: 12),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: DriverColors.primaryOrange
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DriverColors.primaryOrange
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_upload_outlined,
                            color: DriverColors.primaryOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Manage & Upload Documents',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Upload CDL, Registration, COI, and DOT Inspection',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: DriverColors.primaryOrange,
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 4. Logout / Back
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: DriverColors.offlineRed,
                side: const BorderSide(color: DriverColors.offlineRed),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Close Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: DriverColors.primaryOrange, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceRow(String label, bool isVerified) {
    return Row(
      children: [
        Icon(
          isVerified ? Icons.check_circle_rounded : Icons.pending,
          color: isVerified ? DriverColors.onlineGreen : Colors.amber,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isVerified ? const Color(0x2210B981) : const Color(0x22F59E0B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isVerified ? 'VERIFIED' : 'PENDING',
            style: TextStyle(
              color: isVerified ? DriverColors.onlineGreen : Colors.amber,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
