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

        final driverPos = const LatLng(37.7700, -122.4200);
        final pickupPos = LatLng(job.pickupLat, job.pickupLng);
        final dropPos = LatLng(job.dropLat, job.dropLng);

        return Scaffold(
          backgroundColor: DriverColors.bgDark,
          body: Stack(
            children: [
              // 1. Live Flutter Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: job.status == JobStatus.towing ? dropPos : pickupPos,
                  initialZoom: 13.8,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.roacs.towing_driver',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: job.status == JobStatus.towing
                            ? [pickupPos, dropPos]
                            : [driverPos, pickupPos],
                        strokeWidth: 5.0,
                        color: DriverColors.primaryOrange,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Driver Tow Truck Marker
                      Marker(
                        point: driverPos,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.fire_truck_rounded, color: DriverColors.primaryOrange, size: 24),
                        ),
                      ),
                      // Pickup Marker
                      Marker(
                        point: pickupPos,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: DriverColors.enRouteAmber,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.car_crash_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      // Dropoff Marker
                      Marker(
                        point: dropPos,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: DriverColors.onlineGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 2. Top Navigation Bar with Status Banner
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: DriverColors.cardDark.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: job.status.color.withValues(alpha: 0.2),
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
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.my_location, color: Colors.white70),
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

              // 3. Bottom Execution Panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DriverColors.cardDark,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Customer & Call Row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: DriverColors.primaryOrange.withValues(alpha: 0.2),
                              child: Text(
                                job.customerName.isNotEmpty ? job.customerName[0] : 'C',
                                style: const TextStyle(
                                  color: DriverColors.primaryOrange,
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
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${job.vehicleName} • ${job.licensePlate}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: DriverColors.bgDark,
                                shape: BoxShape.circle,
                                border: Border.all(color: DriverColors.borderDark),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.phone, color: DriverColors.onlineGreen),
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
                                color: DriverColors.bgDark,
                                shape: BoxShape.circle,
                                border: Border.all(color: DriverColors.borderDark),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.message, color: DriverColors.navBlue),
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
                            color: DriverColors.bgDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: DriverColors.borderDark),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: DriverColors.enRouteAmber, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  job.notes,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Main Step Progression Action Button
                        ElevatedButton(
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            _getActionButtonText(job.status),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
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
  }

  IconData _getIconForStatus(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
      case JobStatus.accepted:
        return Icons.navigation_rounded;
      case JobStatus.arrived:
        return Icons.location_on;
      case JobStatus.towing:
        return Icons.local_shipping_rounded;
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
        return DriverColors.navBlue;
      case JobStatus.arrived:
        return DriverColors.primaryOrange;
      case JobStatus.towing:
        return DriverColors.onlineGreen;
      default:
        return DriverColors.primaryOrange;
    }
  }

  String _getActionButtonText(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
      case JobStatus.accepted:
        return 'ARRIVED AT PICKUP LOCATION';
      case JobStatus.arrived:
        return 'HOOK VEHICLE & START TOW';
      case JobStatus.towing:
        return 'COMPLETE TOW & UNLOAD';
      default:
        return 'JOB COMPLETED';
    }
  }

  void _showCompletionDialog(BuildContext context, TowJob job) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: DriverColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0x2210B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: DriverColors.onlineGreen, size: 54),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tow Completed!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vehicle delivered to ${job.dropAddress}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: DriverColors.bgDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Driver Payout',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    job.totalCost,
                    style: const TextStyle(
                      color: DriverColors.onlineGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DriverColors.primaryOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('BACK TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
