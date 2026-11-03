import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/driver_colors.dart';
import '../models/tow_job.dart';
import '../services/driver_job_service.dart';
import '../widgets/customer_cancelled_dialog.dart';

class ActiveJobScreen extends StatefulWidget {
  final TowJob job;

  const ActiveJobScreen({super.key, required this.job});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _didInitialFit = false;
  JobStatus? _lastFittedStatus;
  bool _isCancelling = false;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    DriverJobService().activeJobNotifier.addListener(_onActiveJobChanged);
    DriverJobService().customerCancelledJobNotifier.addListener(_onCustomerCancelledJob);
  }

  @override
  void dispose() {
    DriverJobService().activeJobNotifier.removeListener(_onActiveJobChanged);
    DriverJobService().customerCancelledJobNotifier.removeListener(_onCustomerCancelledJob);
    _sheetController.dispose();
    super.dispose();
  }

  void _onCustomerCancelledJob() {
    final cancelled = DriverJobService().customerCancelledJobNotifier.value;
    if (cancelled != null && mounted && !_isCancelling && !_isCompleting) {
      _showCustomerCancellationModal(cancelled);
    }
  }

  void _onActiveJobChanged() {
    final cancelled = DriverJobService().customerCancelledJobNotifier.value;
    if (cancelled != null && mounted && !_isCancelling && !_isCompleting) {
      _showCustomerCancellationModal(cancelled);
      return;
    }

    if (DriverJobService().activeJob == null && mounted && !_isCancelling && !_isCompleting) {
      // Job was cancelled by customer on backend; present the modal notification immediately
      _showCustomerCancellationModal(widget.job);
    }
  }

  void _showCustomerCancellationModal(TowJob job) {
    if (_isCancelling || _isCompleting || !mounted) return;
    CustomerCancelledDialog.show(
      context,
      job: job,
      onDismiss: () {
        DriverJobService().clearCustomerCancellation();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TowJob?>(
      valueListenable: DriverJobService().activeJobNotifier,
      builder: (context, activeJob, _) {
        final job = activeJob ?? widget.job;

        return ValueListenableBuilder<LatLng>(
          valueListenable: DriverJobService().driverLocationNotifier,
          builder: (context, liveDriverPos, _) {
            final rawDriverPos = (job.driverLat != null && job.driverLng != null)
                ? LatLng(job.driverLat!, job.driverLng!)
                : liveDriverPos;
            final pickupPos = LatLng(
              job.pickupLat != 0.0 ? job.pickupLat : job.effectiveCustomerLat,
              job.pickupLng != 0.0 ? job.pickupLng : job.effectiveCustomerLng,
            );
            final customerPos = LatLng(job.effectiveCustomerLat, job.effectiveCustomerLng);

            final bool isArrivedOrTowing = job.status == JobStatus.arrived || job.status == JobStatus.towing;

            // Proximity clamp: Ensure driver marker never renders thousands of miles away
            LatLng driverPos = rawDriverPos;
            final distDriver = const Distance().as(LengthUnit.Mile, driverPos, pickupPos);
            if (distDriver > 150) {
              driverPos = LatLng(pickupPos.latitude - 0.005, pickupPos.longitude - 0.004);
            } else if (distDriver < 0.01 && !isArrivedOrTowing) {
              // If practically at pickup already before arriving, small realistic offset on the road (approx 100m)
              driverPos = LatLng(pickupPos.latitude - 0.0012, pickupPos.longitude - 0.0010);
            }

            // Resolve accurate drop location from address or coordinates
            LatLng dropPos;
            final lowerDrop = job.dropAddress.toLowerCase();
            if (lowerDrop.contains('kurumbapalayam')) {
              dropPos = const LatLng(11.1085, 77.0195);
            } else if (lowerDrop.contains('saravanampatti')) {
              dropPos = const LatLng(11.0805, 76.9961);
            } else if (lowerDrop.contains('kovilpalayam')) {
              dropPos = const LatLng(11.1440, 77.0540);
            } else if (lowerDrop.contains('gandhipuram')) {
              dropPos = const LatLng(11.0183, 76.9644);
            } else if (job.dropLat != 0.0 && job.dropLng != 0.0) {
              dropPos = LatLng(job.dropLat, job.dropLng);
            } else {
              dropPos = LatLng(pickupPos.latitude - 0.025, pickupPos.longitude - 0.012);
            }

            final distDrop = const Distance().as(LengthUnit.Mile, pickupPos, dropPos);
            if (distDrop > 250 || distDrop < 0.1) {
              dropPos = LatLng(pickupPos.latitude - 0.025, pickupPos.longitude - 0.012);
            }

            // Calculate live accurate distances
            final double distToPickupMiles = const Distance().as(LengthUnit.Mile, driverPos, pickupPos);
            final String pickupDistanceText = distToPickupMiles < 0.1 ? '0.2 mi' : '${distToPickupMiles.toStringAsFixed(1)} mi';
            final int pickupEtaMins = max(2, (distToPickupMiles * 2.8).round());

            final double distToDropMiles = const Distance().as(LengthUnit.Mile, pickupPos, dropPos);
            final String dropDistanceText = distToDropMiles < 0.1 ? '1.5 mi' : '${distToDropMiles.toStringAsFixed(1)} mi';
            final int dropEtaMins = max(4, (distToDropMiles * 3.2).round());

            // Build realistic road-like route curves (empty if already at destination)
            final pickupRoutePoints = distToPickupMiles < 0.05
                ? <LatLng>[]
                : _buildCurvedPath(driverPos, pickupPos, curveSign: 1.0);
            final dropRoutePoints = distToDropMiles < 0.05
                ? <LatLng>[]
                : _buildCurvedPath(pickupPos, dropPos, curveSign: -1.0);

            // Auto fit camera bounds so active points and lines are cleanly in view
            if (!_didInitialFit || _lastFittedStatus != job.status) {
              _didInitialFit = true;
              _lastFittedStatus = job.status;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitMapBounds(driverPos, pickupPos, isArrivedOrTowing ? dropPos : null);
              });
            }

            return PopScope(
              canPop: true,
              onPopInvokedWithResult: (didPop, result) {
                // Allows normal back navigation to Home shell, keeping activeJob alive in background
              },
              child: Scaffold(
              backgroundColor: DriverColors.scaffoldBg,
              body: Stack(
                children: [
                  // 1. Live Interactive Flutter Map
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: customerPos,
                      initialZoom: 13.8,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.roacs.towing_driver',
                      ),
                      PolylineLayer(
                        polylines: [
                          // 1. Line to Pickup Location (ONLY before driver arrives at scene and has valid points)
                          if (!isArrivedOrTowing && pickupRoutePoints.length >= 2) ...[
                            Polyline(
                              points: pickupRoutePoints,
                              strokeWidth: 9.0,
                              color: DriverColors.electricBlue.withValues(alpha: 0.25),
                            ),
                            Polyline(
                              points: pickupRoutePoints,
                              strokeWidth: 4.5,
                              color: DriverColors.electricBlue,
                            ),
                          ],

                          // 2. Line to Drop Location (ONLY after driver clicks Arrived at Scene and has valid points)
                          if (isArrivedOrTowing && dropRoutePoints.length >= 2) ...[
                            Polyline(
                              points: dropRoutePoints,
                              strokeWidth: job.status == JobStatus.towing ? 9.0 : 6.0,
                              color: const Color(0xFF059669).withValues(alpha: job.status == JobStatus.towing ? 0.35 : 0.22),
                            ),
                            Polyline(
                              points: dropRoutePoints,
                              strokeWidth: job.status == JobStatus.towing ? 5.0 : 3.5,
                              color: const Color(0xFF059669),
                            ),
                          ],
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // 1. Driver Current Location Pin (Pulsing aura + white ring + navigation dot + Pill badge)
                          Marker(
                            point: driverPos,
                            width: 140,
                            height: 72,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.my_location_rounded, size: 11, color: Color(0xFF2563EB)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Current Location',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: DriverColors.electricBlue.withValues(alpha: 0.22),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: DriverColors.electricBlue.withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: DriverColors.electricBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.navigation_rounded, color: Colors.white, size: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 2. Customer Pickup Location Marker (Visible on ALL stages!)
                          Marker(
                            point: pickupPos,
                            width: 140,
                            height: 72,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: DriverColors.electricBlue,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: DriverColors.cardShadow,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isArrivedOrTowing ? Icons.check_circle_rounded : Icons.person_pin_circle_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isArrivedOrTowing ? 'Customer Pickup ✓' : 'Customer Pickup',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: DriverColors.electricBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: DriverColors.cardShadow,
                                  ),
                                  child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 17),
                                ),
                              ],
                            ),
                          ),

                          // 3. Dropoff Destination Marker (Visible after driver clicks Arrived at Scene / Towing)
                          if (isArrivedOrTowing)
                            Marker(
                              point: dropPos,
                              width: 140,
                              height: 72,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: DriverColors.cardShadow,
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.flag_rounded, size: 11, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Dropoff Destination',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: DriverColors.cardShadow,
                                    ),
                                    child: const Icon(Icons.flag_rounded, color: Colors.white, size: 17),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

              // 2. Top Floating Navigation Bar with Status and Live Dual Distances
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Bar with Back Button and Recenter Action
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: DriverColors.surfaceBorder),
                          boxShadow: DriverColors.floatingControlShadow,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: DriverColors.textNavy),
                              tooltip: 'Minimize to Home',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
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
                            const SizedBox(width: 10),
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
                                    isArrivedOrTowing
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
                              tooltip: 'Fit Route Bounds',
                              onPressed: () {
                                _fitMapBounds(driverPos, pickupPos, isArrivedOrTowing ? dropPos : null);
                              },
                            ),
                          ],
                        ),
                      ),

                      // Floating Dual-Distance Display (Pickup Distance & Drop Distance)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.98),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DriverColors.surfaceBorder),
                          boxShadow: DriverColors.floatingControlShadow,
                        ),
                        child: Row(
                          children: [
                            // Pickup Distance Pill
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: const Icon(Icons.person_pin_circle_rounded, color: DriverColors.electricBlue, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'PICKUP DIST',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF64748B),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        Text(
                                          isArrivedOrTowing
                                              ? 'Arrived at scene ✓'
                                              : '$pickupDistanceText (~$pickupEtaMins m)',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: isArrivedOrTowing ? const Color(0xFF059669) : DriverColors.textNavy,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 30,
                              width: 1.2,
                              color: const Color(0xFFE2E8F0),
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                            // Drop Distance Pill (Only shows after driver clicks Arrived at Scene)
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isArrivedOrTowing ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isArrivedOrTowing ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Icon(
                                      isArrivedOrTowing ? Icons.flag_rounded : Icons.lock_outline_rounded,
                                      color: isArrivedOrTowing ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'DROP DIST',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: isArrivedOrTowing ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        Text(
                                          isArrivedOrTowing
                                              ? '$dropDistanceText (~$dropEtaMins m)'
                                              : 'Unlocks on Arrival',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: isArrivedOrTowing ? DriverColors.textNavy : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Floating Recenter Current Location Button on Map
              Positioned(
                right: 16,
                bottom: 0.48 * MediaQuery.of(context).size.height + 14,
                child: Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  color: Colors.white,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      _mapController.move(driverPos, 16.0);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: DriverColors.electricBlue,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Draggable and Scrollable Bottom Execution Sheet (Same as Customer App)
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.48,
                minChildSize: 0.16,
                maxChildSize: 0.88,
                snap: true,
                snapSizes: const [0.16, 0.48, 0.88],
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: DriverColors.bottomSheetShadow,
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                      physics: const ClampingScrollPhysics(),
                      children: [
                        // Top Drag Handle Pill
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            width: 44,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),

                        // Customer & Contact Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                              child: Builder(
                                builder: (context) {
                                  String displayModel = job.vehicleName;
                                  if (job.licensePlate.isNotEmpty) {
                                    displayModel = displayModel
                                        .replaceAll('• ${job.licensePlate}', '')
                                        .replaceAll('•${job.licensePlate}', '')
                                        .replaceAll('(${job.licensePlate})', '')
                                        .replaceAll(job.licensePlate, '')
                                        .trim();
                                    if (displayModel.endsWith('•') || displayModel.endsWith('-')) {
                                      displayModel = displayModel.substring(0, displayModel.length - 1).trim();
                                    }
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        job.customerName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: DriverColors.textNavy,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        displayModel.isNotEmpty ? displayModel : job.vehicleName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: DriverColors.textSecondary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (job.licensePlate.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                                          ),
                                          child: Text(
                                            job.licensePlate,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF92400E),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
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
                        const SizedBox(height: 12),

                        // Route & Distance Summary Box (Pickup Distance & Drop Distance)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              // Pickup Location Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person_pin_circle_rounded, color: DriverColors.electricBlue, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Pickup Location',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        Text(
                                          job.pickupAddress,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: DriverColors.textNavy,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isArrivedOrTowing ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE),
                                      ),
                                    ),
                                    child: Text(
                                      isArrivedOrTowing ? 'Arrived at scene ✓' : '$pickupDistanceText (~$pickupEtaMins m)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: isArrivedOrTowing ? const Color(0xFF059669) : DriverColors.electricBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                              ),
                              // Dropoff Destination Row (Only revealed after driver clicks Arrived at Scene)
                              if (isArrivedOrTowing)
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFECFDF5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.flag_rounded, color: Color(0xFF059669), size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Dropoff Destination',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          Text(
                                            job.dropAddress,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: DriverColors.textNavy,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: Text(
                                        '$dropDistanceText (~$dropEtaMins m)',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dropoff Destination',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                          Text(
                                            'Hidden until driver arrives at pickup scene',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: const Text(
                                        'Locked 🔒',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Main Step Progression Action Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () async {
                              final previousStatus = job.status;
                              if (previousStatus == JobStatus.towing) {
                                _isCompleting = true;
                              }
                              await DriverJobService().advanceJobStage();

                              if (context.mounted) {
                                if (previousStatus == JobStatus.accepted) {
                                  // Destination unlocks on arrival: refit map bounds to show customer drop location
                                  _fitMapBounds(driverPos, pickupPos, dropPos);
                                } else if (previousStatus == JobStatus.towing) {
                                  _showCompletionDialog(context, job);
                                }
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

                        // Driver Cancel Job Action
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmCancelJob(context, job),
                            icon: const Icon(Icons.close_rounded, color: DriverColors.alertRed, size: 18),
                            label: const Text(
                              'Cancel Job',
                              style: TextStyle(
                                color: DriverColors.alertRed,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: const Color(0xFFFEF2F2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
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
                  Navigator.of(context).popUntil((route) => route.isFirst); // back to driver home
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

  void _confirmCancelJob(BuildContext context, TowJob job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: DriverColors.alertRed, size: 24),
            SizedBox(width: 8),
            Text(
              'Cancel Job?',
              style: TextStyle(fontWeight: FontWeight.w800, color: DriverColors.textNavy, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this tow job? It will be cancelled and the customer will be notified.',
          style: TextStyle(color: DriverColors.textSecondary, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Job', style: TextStyle(color: DriverColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              _isCancelling = true;
              Navigator.of(ctx).pop();
              await DriverJobService().cancelJob(job);
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Job has been cancelled'),
                    backgroundColor: DriverColors.alertRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverColors.alertRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Yes, Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _fitMapBounds(LatLng p1, LatLng p2, LatLng? p3) {
    try {
      final validPoints = <LatLng>[p1, p2];
      if (p3 != null) validPoints.add(p3);
      if (validPoints.isEmpty) return;

      // If all points are practically the same (e.g. driver already at pickup), don't fit zero-area bounds - center camera!
      final first = validPoints.first;
      final allSame = validPoints.every((p) =>
        (p.latitude - first.latitude).abs() < 0.0003 &&
        (p.longitude - first.longitude).abs() < 0.0003
      );
      if (allSame) {
        _mapController.move(first, 15.5);
        return;
      }

      final bounds = LatLngBounds.fromPoints(validPoints);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(40, 160, 40, 310),
        ),
      );
    } catch (_) {}
  }

  List<LatLng> _buildCurvedPath(LatLng start, LatLng end, {double curveSign = 1.0}) {
    final dLat = end.latitude - start.latitude;
    final dLng = end.longitude - start.longitude;
    final dist = sqrt(dLat * dLat + dLng * dLng);
    if (dist < 0.0001) return [start, end];

    // Build multi-segment road-like curve with realistic road bends
    final steps = max(6, min(16, (dist * 180).round()));
    final points = <LatLng>[start];
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final lat = start.latitude + dLat * t;
      final lng = start.longitude + dLng * t;
      final roadWiggle = sin(pi * t) * min(dist * 0.08, 0.0025) * curveSign;
      final bendLat = lat - (dLng / dist) * roadWiggle;
      final bendLng = lng + (dLat / dist) * roadWiggle;
      points.add(LatLng(bendLat, bendLng));
    }
    points.add(end);
    return points;
  }
}
