import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/driver_colors.dart';
import '../models/tow_job.dart';
import '../services/driver_job_service.dart';

class ActiveJobScreen extends StatefulWidget {
  final TowJob job;

  const ActiveJobScreen({super.key, required this.job});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TowJob?>(
      valueListenable: DriverJobService().activeJobNotifier,
      builder: (context, activeJob, _) {
        final job = activeJob ?? widget.job;

        return ValueListenableBuilder<LatLng>(
          valueListenable: DriverJobService().driverLocationNotifier,
          builder: (context, liveDriverPos, _) {
            final driverPos = (job.driverLat != null && job.driverLng != null)
                ? LatLng(job.driverLat!, job.driverLng!)
                : liveDriverPos;
            final customerPos = LatLng(job.effectiveCustomerLat, job.effectiveCustomerLng);
            final pickupPos = LatLng(job.pickupLat, job.pickupLng);
            final dropPos = LatLng(job.dropLat, job.dropLng);

            return Scaffold(
              backgroundColor: DriverColors.scaffoldBg,
              body: Stack(
                children: [
                  // 1. Live Interactive Flutter Map
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: job.status == JobStatus.towing ? dropPos : customerPos,
                      initialZoom: 13.8,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.roacs.towing_driver',
                      ),
                      PolylineLayer(
                        polylines: [
                          // Glow
                          Polyline(
                            points: job.status == JobStatus.towing
                                ? [driverPos, dropPos]
                                : [driverPos, customerPos],
                            strokeWidth: 8.0,
                            color: DriverColors.electricBlue.withValues(alpha: 0.3),
                          ),
                          // Main line
                          Polyline(
                            points: job.status == JobStatus.towing
                                ? [driverPos, dropPos]
                                : [driverPos, customerPos],
                            strokeWidth: 4.5,
                            color: DriverColors.electricBlue,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // Driver Tow Truck Marker (Live Driver Location)
                          Marker(
                            point: driverPos,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: DriverColors.navy900,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: DriverColors.cardShadow,
                              ),
                              child: const Icon(Icons.fire_truck_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                          // Customer Live Location Marker
                          Marker(
                            point: customerPos,
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: DriverColors.electricBlue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: DriverColors.cardShadow,
                              ),
                              child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                          // Dropoff Destination Marker
                          Marker(
                            point: dropPos,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: DriverColors.emeraldGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: DriverColors.cardShadow,
                              ),
                              child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

              // 2. Top Floating Navigation Bar with Status
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: DriverColors.surfaceBorder),
                      boxShadow: DriverColors.floatingControlShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: job.status.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForStatus(job.status),
                            color: job.status.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                job.status.label.toUpperCase(),
                                style: TextStyle(
                                  color: job.status.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                job.status == JobStatus.towing
                                    ? 'En route to ${job.dropAddress}'
                                    : 'Navigating to ${job.pickupAddress}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: DriverColors.textNavy,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.my_location_rounded, color: DriverColors.electricBlue),
                          onPressed: () {
                            _mapController.move(
                              job.status == JobStatus.towing ? dropPos : pickupPos,
                              14.5,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Bottom Execution Sheet
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: DriverColors.bottomSheetShadow,
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Customer & Contact Row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: DriverColors.blueTint,
                              child: Text(
                                job.customerName.isNotEmpty ? job.customerName[0] : 'C',
                                style: const TextStyle(
                                  color: DriverColors.electricBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.customerName,
                                    style: const TextStyle(
                                      color: DriverColors.textNavy,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${job.vehicleName} • ${job.licensePlate}',
                                    style: const TextStyle(
                                      color: DriverColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: DriverColors.greenTint,
                                shape: BoxShape.circle,
                                border: Border.all(color: DriverColors.greenBorder),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.phone, color: DriverColors.emeraldDark),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Calling customer: ${job.customerPhone}')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: DriverColors.blueTint,
                                shape: BoxShape.circle,
                                border: Border.all(color: DriverColors.blueBorder),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.message, color: DriverColors.electricBlue),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Opening live chat with customer')),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Vehicle Notes Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DriverColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DriverColors.surfaceBorderLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: DriverColors.warningAmber, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  job.notes,
                                  style: const TextStyle(
                                    color: DriverColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Main Step Progression Action Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              final previousStatus = job.status;
                              await DriverJobService().advanceJobStage();

                              if (previousStatus == JobStatus.towing && context.mounted) {
                                _showCompletionDialog(context, job);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getActionColorForStatus(job.status),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              _getActionButtonText(job.status),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
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
        );
        },
      );
    },
  );
}

  IconData _getIconForStatus(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
      case JobStatus.accepted:
        return Icons.navigation_rounded;
      case JobStatus.arrived:
        return Icons.location_on;
      case JobStatus.towing:
        return Icons.fire_truck_rounded;
      case JobStatus.completed:
        return Icons.check_circle_rounded;
      case JobStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  Color _getActionColorForStatus(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
      case JobStatus.accepted:
        return DriverColors.electricBlue;
      case JobStatus.arrived:
        return DriverColors.navy900;
      case JobStatus.towing:
        return DriverColors.emeraldGreen;
      case JobStatus.completed:
        return DriverColors.emeraldGreen;
      case JobStatus.cancelled:
        return DriverColors.alertRed;
    }
  }

  String _getActionButtonText(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
      case JobStatus.accepted:
        return 'Slide When Arrived at Scene';
      case JobStatus.arrived:
        return 'Confirm Hooked & Begin Tow';
      case JobStatus.towing:
        return 'Complete Drop-Off & Collect ${widget.job.payoutFormatted}';
      case JobStatus.completed:
        return 'Job Completed Successfully';
      case JobStatus.cancelled:
        return 'Job Was Cancelled';
    }
  }

  void _showCompletionDialog(BuildContext context, TowJob job) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: DriverColors.greenTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: DriverColors.emeraldDark, size: 54),
            ),
            const SizedBox(height: 18),
            const Text(
              'Trip Finished!',
              style: TextStyle(
                color: DriverColors.textNavy,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You earned ${job.payoutFormatted} for this roadside recovery.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: DriverColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // dismiss dialog
                  Navigator.of(context).pop(); // back to driver home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DriverColors.emeraldGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Dispatch Queue', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
