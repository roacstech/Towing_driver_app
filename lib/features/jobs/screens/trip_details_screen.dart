import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/driver_colors.dart';
import '../models/tow_job.dart';
import '../services/driver_job_service.dart';

class TripDetailsScreen extends StatelessWidget {
  final TowJob job;

  const TripDetailsScreen({
    super.key,
    required this.job,
  });

  void _handleAccept(BuildContext context) {
    HapticFeedback.heavyImpact();
    DriverJobService().acceptJob(job);
    Navigator.of(context).pop(); // Return to dashboard, which listens to activeJob
  }

  void _handleDecline(BuildContext context) {
    HapticFeedback.lightImpact();
    DriverJobService().declineJob(job);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pickupPos = LatLng(job.pickupLat, job.pickupLng);
    final dropPos = LatLng(job.dropLat, job.dropLng);

    return Scaffold(
      backgroundColor: DriverColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: DriverColors.textNavy,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          job.serviceTitle,
          style: const TextStyle(
            color: DriverColors.textNavy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Vehicle Hero Card with Image & Priority Badge
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: job.isUrgent ? DriverColors.redBorder : DriverColors.surfaceBorder,
                      width: 1.5,
                    ),
                    boxShadow: DriverColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      // Photo Header
                      Stack(
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: DriverColors.surfaceSubtle,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            child: Image.asset(
                              job.vehicleImage,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.directions_car_filled_rounded,
                                    size: 64,
                                    color: DriverColors.textMuted,
                                  ),
                                );
                              },
                            ),
                          ),
                          // Badges overlay
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Row(
                              children: [
                                if (job.isUrgent) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: DriverColors.alertRed,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: DriverColors.cardShadow,
                                    ),
                                    child: const Text(
                                      'URGENT CALL',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: DriverColors.surfaceBorder),
                                  ),
                                  child: Text(
                                    job.requestType,
                                    style: const TextStyle(
                                      color: DriverColors.textNavy,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Payout Pill on Top Right
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: DriverColors.navy900,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: DriverColors.cardShadow,
                              ),
                              child: Text(
                                job.payoutFormatted,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Vehicle Title & License Plate Details
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${job.vehicleYear} ${job.vehicleName}',
                                    style: const TextStyle(
                                      color: DriverColors.textNavy,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    job.vehicleCategory,
                                    style: const TextStyle(
                                      color: DriverColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: DriverColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: DriverColors.surfaceBorder),
                              ),
                              child: Text(
                                'LIC: ${job.licensePlate}',
                                style: const TextStyle(
                                  color: DriverColors.textNavy,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Customer Issue & Description Quote Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                        children: [
                          const Icon(
                            Icons.report_problem_outlined,
                            size: 18,
                            color: DriverColors.warningAmber,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Customer-Reported Condition',
                              style: TextStyle(
                                color: DriverColors.textNavy,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DriverColors.amberTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DriverColors.amberBorder),
                        ),
                        child: Text(
                          '"${job.notes}"',
                          style: const TextStyle(
                            color: Color(0xFF78350F),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Customer Contact Quick Bar
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: DriverColors.blueTint,
                            child: Text(
                              job.customerName.substring(0, 1),
                              style: const TextStyle(
                                color: DriverColors.electricBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.customerName,
                                  style: const TextStyle(
                                    color: DriverColors.textNavy,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${job.customerRating} Rating',
                                      style: const TextStyle(
                                        color: DriverColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: DriverColors.greenTint,
                              shape: BoxShape.circle,
                              border: Border.all(color: DriverColors.greenBorder),
                            ),
                            child: const Center(
                              child: Icon(Icons.phone_rounded, size: 18, color: DriverColors.emeraldDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Location, Addresses & Interactive Route Preview Map
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DriverColors.surfaceBorder),
                    boxShadow: DriverColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      // Pickup & Destination Address Pins
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Pickup
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: DriverColors.electricBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PICKUP LOCATION',
                                        style: TextStyle(
                                          color: DriverColors.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        job.pickupAddress,
                                        style: const TextStyle(
                                          color: DriverColors.textNavy,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${job.distanceToPickup} from your current truck position (${job.pickupEta} ETA)',
                                        style: const TextStyle(
                                          color: DriverColors.electricBlue,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Dotted connector
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 2,
                                  height: 22,
                                  color: DriverColors.surfaceBorder,
                                ),
                              ),
                            ),

                            // Destination / Dropoff
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: DriverColors.emeraldGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DESTINATION FACILITY',
                                        style: TextStyle(
                                          color: DriverColors.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        job.dropAddress,
                                        style: const TextStyle(
                                          color: DriverColors.textNavy,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Estimated trip duration: ${job.tripDuration}',
                                        style: const TextStyle(
                                          color: DriverColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Embedded Route Map
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        child: SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                (pickupPos.latitude + dropPos.latitude) / 2,
                                (pickupPos.longitude + dropPos.longitude) / 2,
                              ),
                              initialZoom: 13.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.roacs.towing_driver',
                              ),
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: [pickupPos, dropPos],
                                    strokeWidth: 4.5,
                                    color: DriverColors.electricBlue,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: pickupPos,
                                    width: 24,
                                    height: 24,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: DriverColors.electricBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.circle, color: Colors.white, size: 8),
                                    ),
                                  ),
                                  Marker(
                                    point: dropPos,
                                    width: 24,
                                    height: 24,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: DriverColors.emeraldGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.flag_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Equipment & Fleet Requirements
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                        'Equipment Requirements',
                        style: TextStyle(
                          color: DriverColors.textNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: job.equipmentRequirements.map((eq) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: DriverColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: DriverColors.surfaceBorderLight),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.build_circle_outlined, size: 14, color: DriverColors.electricBlue),
                                const SizedBox(width: 6),
                                Text(
                                  eq,
                                  style: const TextStyle(
                                    color: DriverColors.textNavy,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Itemized Payout Breakdown
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
                      const Text(
                        'Estimated Driver Payout Breakdown',
                        style: TextStyle(
                          color: DriverColors.textNavy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPayoutRow('Base Hookup & Dispatch', '\$${job.basePayout.toStringAsFixed(2)}'),
                      _buildPayoutRow('Mileage Fare (${job.distanceToPickup})', '\$${job.mileagePayout.toStringAsFixed(2)}'),
                      if (job.hazardFee > 0)
                        _buildPayoutRow('Highway Safety / Hazard Surcharge', '+\$${job.hazardFee.toStringAsFixed(2)}', isHighlight: true),
                      if (job.specialEquipmentFee > 0)
                        _buildPayoutRow('Special Equipment Fee', '+\$${job.specialEquipmentFee.toStringAsFixed(2)}'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: DriverColors.surfaceBorder),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL NET PAYOUT',
                                  style: TextStyle(
                                    color: DriverColors.textNavy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                Text(
                                  'Direct deposit upon completion',
                                  style: TextStyle(
                                    color: DriverColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: DriverColors.greenTint,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: DriverColors.greenBorder),
                            ),
                            child: Text(
                              job.payoutFormatted,
                              style: const TextStyle(
                                color: DriverColors.emeraldDark,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
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

          // 6. Floating Bottom Action Dock (Accept & Decline)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: DriverColors.bottomSheetShadow,
                border: const Border(top: BorderSide(color: DriverColors.surfaceBorder)),
              ),
              child: Row(
                children: [
                  // Pass Button
                  SizedBox(
                    height: 52,
                    width: 90,
                    child: OutlinedButton(
                      onPressed: () => _handleDecline(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: DriverColors.surfaceBorder, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: DriverColors.surfaceSubtle,
                        foregroundColor: DriverColors.textSecondary,
                      ),
                      child: const Text(
                        'Pass',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Accept Job Button
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _handleAccept(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DriverColors.emeraldGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 20),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Accept · ${job.payoutFormatted}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutRow(String label, String amount, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isHighlight ? DriverColors.alertRedDark : DriverColors.textSecondary,
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: TextStyle(
              color: isHighlight ? DriverColors.alertRedDark : DriverColors.textNavy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
