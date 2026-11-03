import 'package:flutter/material.dart';
import '../../../core/constants/driver_colors.dart';
import '../models/tow_job.dart';

class CustomerCancelledDialog extends StatelessWidget {
  final TowJob job;
  final VoidCallback? onDismiss;

  const CustomerCancelledDialog({
    super.key,
    required this.job,
    this.onDismiss,
  });

  static bool isShowing = false;

  /// Shows the modal notification dialog to the driver when a customer cancels.
  static Future<void> show(
    BuildContext context, {
    required TowJob job,
    VoidCallback? onDismiss,
  }) async {
    if (isShowing) return;
    isShowing = true;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => CustomerCancelledDialog(
          job: job,
          onDismiss: () {
            onDismiss?.call();
          },
        ),
      );
    } finally {
      isShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanId = job.id.replaceAll('#', '').trim();
    final customerName = job.customerName.trim().isNotEmpty ? job.customerName : 'Customer';
    final vehicle = job.vehicleName.trim().isNotEmpty ? job.vehicleName : 'Vehicle';
    final plate = job.licensePlate.trim();
    final pickup = job.pickupAddress.trim().isNotEmpty ? job.pickupAddress : 'Pickup Location';

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 16,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prominent Red Alert Icon Badge
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: Color(0xFFDC2626),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),

            // Modal Header Title
            const Text(
              'Customer Cancelled Request',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: DriverColors.textNavy,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),

            // Order ID subtitle badge
            Text(
              'Order #$cleanId',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DriverColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            // Structured Job Card Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer & Vehicle Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: DriverColors.navy900,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: DriverColors.textNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    vehicle,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: DriverColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (plate.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                                    ),
                                    child: Text(
                                      plate,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFB45309),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ),
                  // Pickup Location Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: DriverColors.electricBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pickup,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: DriverColors.textNavy,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Informational Status Callout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The customer has cancelled this request. You are back online and ready for new dispatch requests.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E40AF),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Acknowledgment Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss?.call();
                },
                icon: const Icon(Icons.radar_rounded, size: 20, color: Colors.white),
                label: const Text(
                  'Back to Radar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DriverColors.navy900,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
