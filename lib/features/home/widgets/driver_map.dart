import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../jobs/models/tow_job.dart';

class DriverMap extends StatefulWidget {
  final List<TowJob> requests;
  final TowJob? selectedRequest;
  final ValueChanged<TowJob>? onRequestSelected;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onExpandSheet;
  final double sheetRatio;
  final bool isOnline;
  final VoidCallback? onToggleOnline;

  const DriverMap({
    super.key,
    required this.requests,
    this.selectedRequest,
    this.onRequestSelected,
    this.onMenuPressed,
    this.onNotificationsPressed,
    this.onExpandSheet,
    this.sheetRatio = 0.40,
    this.isOnline = true,
    this.onToggleOnline,
  });

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap> {
  final MapController _mapController = MapController();
  LatLng? _currentDriverLocation;

  @override
  void initState() {
    super.initState();
    _currentDriverLocation = _getDefaultDriverLocation();
    _fetchDriverLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchDriverLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final pos = await Geolocator.getLastKnownPosition() ??
              await Geolocator.getCurrentPosition();
          if (mounted) {
            setState(() {
              _currentDriverLocation = LatLng(pos.latitude, pos.longitude);
            });
            _centerOnDriverLocation();
            return;
          }
        }
      }
    } catch (_) {}

    // Fallback: Default realistic location for current job
    if (mounted) {
      setState(() {
        _currentDriverLocation = _getDefaultDriverLocation();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnDriverLocation();
      });
    }
  }

  LatLng _getDefaultDriverLocation() {
    final job = widget.selectedRequest;
    if (job != null) {
      // Driver position placed ~1.5 miles from pickup
      return LatLng(job.pickupLat - 0.009, job.pickupLng - 0.007);
    }
    return const LatLng(11.1389, 77.0325);
  }

  @override
  void didUpdateWidget(DriverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRequest?.id != oldWidget.selectedRequest?.id &&
        widget.selectedRequest != null) {
      _currentDriverLocation = _getDefaultDriverLocation();
      _centerOnDriverLocation();
    }
  }

  void _centerOnDriverLocation() {
    final driverLoc = _currentDriverLocation ?? _getDefaultDriverLocation();
    // In 6:4 mode (sheetRatio = 0.40), top 60% is visible map.
    // Optical center of visible 60% map is 30% from the top (shift south by 20% of viewport).
    final ratioShift = widget.sheetRatio / 2.0;
    final latOffset = ratioShift * 0.055;
    final target = LatLng(driverLoc.latitude - latOffset, driverLoc.longitude);
    try {
      _mapController.move(target, 13.0);
    } catch (_) {}
  }

  List<LatLng> _getRoutePoints(TowJob job) {
    final driverLoc = _currentDriverLocation ?? _getDefaultDriverLocation();
    final pLat = job.pickupLat;
    final pLng = job.pickupLng;
    final pickup = LatLng(pLat, pLng);

    // If driverLoc is far from pickup (> 150 miles), anchor driver locally
    LatLng effectiveDriverLoc = driverLoc;
    if (const Distance().as(LengthUnit.Mile, effectiveDriverLoc, pickup) > 150) {
      effectiveDriverLoc = LatLng(pLat - 0.009, pLng - 0.007);
    }

    // If drop is far from pickup (> 250 miles), anchor drop locally
    LatLng drop = LatLng(job.dropLat, job.dropLng);
    if (const Distance().as(LengthUnit.Mile, pickup, drop) > 250) {
      drop = LatLng(pLat + 0.015, pLng + 0.012);
    }

    // Default route points with slight curvature from driver to pickup and drop
    final midPickupLat = (effectiveDriverLoc.latitude + pickup.latitude) / 2 + 0.003;
    final midPickupLng = (effectiveDriverLoc.longitude + pickup.longitude) / 2 - 0.003;

    final midDropLat = (pickup.latitude + drop.latitude) / 2 + 0.004;
    final midDropLng = (pickup.longitude + drop.longitude) / 2 - 0.004;

    return [
      effectiveDriverLoc,
      LatLng(midPickupLat, midPickupLng),
      pickup,
      LatLng(midDropLat, midDropLng),
      drop,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedJob = widget.selectedRequest;
    final routePoints = selectedJob != null ? _getRoutePoints(selectedJob) : <LatLng>[];
    final pickupPos = selectedJob != null ? LatLng(selectedJob.pickupLat, selectedJob.pickupLng) : null;
    final dropPos = selectedJob != null ? LatLng(selectedJob.dropLat, selectedJob.dropLng) : null;
    final driverPos = _currentDriverLocation ?? _getDefaultDriverLocation();

    // Initial center offset for top 60% map visibility in 6:4 mode
    final initialCenter = LatLng(
      driverPos.latitude - (widget.sheetRatio / 2.0) * 0.055,
      driverPos.longitude,
    );

    return Stack(
      children: [
        // 1. Full Screen FlutterMap Tile Layer
        Positioned.fill(
          child: Container(
            color: const Color(0xFFE5E7EB),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 12.6,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.roacs.towing_driver',
                ),

                // 2. Route Polyline connecting Origin to Destination
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      // Outer soft glow shadow
                      Polyline(
                        points: routePoints,
                        strokeWidth: 9.0,
                        color: const Color(0xFF2563EB).withValues(alpha: 0.22),
                      ),
                      // Core vibrant electric blue route line
                      Polyline(
                        points: routePoints,
                        strokeWidth: 4.5,
                        color: const Color(0xFF2563EB),
                      ),
                    ],
                  ),

                // 3. Markers: Driver Location, Blue Origin Circle & Red Destination Pin
                MarkerLayer(
                  markers: [
                    // Driver Current Location Marker (Pulse ring + white ring + navigation arrow)
                    Marker(
                      point: driverPos,
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer translucent radar pulse aura
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Crisp white boundary
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          // Core blue driver navigation dot
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.navigation_rounded,
                                color: Colors.white,
                                size: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Origin Blue Dot Marker
                    if (pickupPos != null)
                      Marker(
                        point: pickupPos,
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Destination Red Pin Marker
                    if (dropPos != null)
                      Marker(
                        point: dropPos,
                        width: 38,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 38,
                                ),
                                Positioned(
                                  top: 9,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
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
              ],
            ),
          ),
        ),

        // 4. Ultra-Clean Floating Top Bar: Menu Button on Left, Recenter Location Button on Right
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Hamburger Menu Button
              GestureDetector(
                onTap: widget.onMenuPressed,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_rounded,
                      color: Color(0xFF1E293B),
                      size: 22,
                    ),
                  ),
                ),
              ),

              // Center: Interactive Online / Offline Badge with Animated Toggle Switch
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onToggleOnline?.call();
                },
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity > 60 && !widget.isOnline) {
                    // Swiped right -> go online
                    HapticFeedback.mediumImpact();
                    widget.onToggleOnline?.call();
                  } else if (velocity < -60 && widget.isOnline) {
                    // Swiped left -> go offline
                    HapticFeedback.mediumImpact();
                    widget.onToggleOnline?.call();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF0F172A),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Label (Clean text, no dot, matching reference images)
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        style: TextStyle(
                          color: widget.isOnline
                              ? const Color(0xFF006837)
                              : const Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: Text(
                            widget.isOnline ? 'ON DUTY' : 'OFF DUTY',
                            key: ValueKey<bool>(widget.isOnline),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Smooth Switch matching Images 2 & 3
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        width: 46,
                        height: 25,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: widget.isOnline
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFA0ABC0),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOutCubic,
                          alignment: widget.isOnline
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOutCubic,
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: widget.isOnline
                                  ? const Color(0xFF00873E)
                                  : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
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

              // Right: Current Location Button (replacing old notification bell!)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _centerOnDriverLocation();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 5. Floating "View Cards" Pill (Appears when map is full screen so driver can easily restore cards)
        if (widget.sheetRatio <= 0.16 && widget.requests.isNotEmpty)
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onExpandSheet?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.requests.length} Requests Available',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Cards',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
