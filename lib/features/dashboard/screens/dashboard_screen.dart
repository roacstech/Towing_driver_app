import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../auth/screens/driver_login_screen.dart';
import '../../auth/services/driver_auth_service.dart';
import '../../documents/screens/driver_document_upload_screen.dart';
import '../../jobs/models/tow_job.dart';
import '../../jobs/screens/active_job_screen.dart';
import '../../jobs/services/driver_job_service.dart';
import '../../profile/screens/driver_profile_screen.dart';

/// Model representing static nearby dispatch requests shown on the map
class NearbyTowRequest {
  final String id;
  final String vehicleName;
  final String serviceReason;
  final String distance;
  final String duration;
  final String price;
  final String imagePath;
  final LatLng position;
  final String pickupAddress;
  final String dropAddress;

  const NearbyTowRequest({
    required this.id,
    required this.vehicleName,
    required this.serviceReason,
    required this.distance,
    required this.duration,
    required this.price,
    required this.imagePath,
    required this.position,
    required this.pickupAddress,
    required this.dropAddress,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final DriverJobService _jobService = DriverJobService();
  final MapController _mapController = MapController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _pulseController;
  int _selectedTabIndex = 0;
  int _currentLayerIndex = 0;
  bool _isOnline = true;
  bool _isSheetExpanded = false;

  // Center driver location (San Francisco coordinates)
  final LatLng _driverLocation = const LatLng(37.7749, -122.4194);

  // Free OpenStreetMap tile layers matching customer app (zero API keys / zero watermarks)
  final List<String> _tileLayers = [
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
  ];

  // 5 Nearby towing requests positioned cleanly around the driver
  late final List<NearbyTowRequest> _nearbyRequests;
  late NearbyTowRequest _selectedRequest;

  @override
  void initState() {
    super.initState();
    _jobService.init();

    _nearbyRequests = [
      // 1. Featured default card (Ford F-150, $160, 6 min) - Bottom Left
      NearbyTowRequest(
        id: 'REQ-101',
        vehicleName: 'Ford F-150',
        serviceReason: 'Disabled Vehicle',
        distance: '2.1 mi',
        duration: '6 min',
        price: '\$160',
        imagePath: 'assets/images/ford-f150.png',
        position: const LatLng(37.7720, -122.4220),
        pickupAddress: 'Mission St & 16th St, SF',
        dropAddress: 'City View Auto Repair, SOMA, SF',
      ),
      // 2. Top Left Marker ($140, 3 min)
      NearbyTowRequest(
        id: 'REQ-102',
        vehicleName: 'BMW 330i',
        serviceReason: 'Transmission Issue',
        distance: '1.2 mi',
        duration: '3 min',
        price: '\$140',
        imagePath: 'assets/images/bmw-x5.png',
        position: const LatLng(37.7780, -122.4228),
        pickupAddress: 'Geary Blvd & Van Ness, SF',
        dropAddress: 'European Auto Care, Mission, SF',
      ),
      // 3. Top Right Marker ($110, 6 min)
      NearbyTowRequest(
        id: 'REQ-103',
        vehicleName: 'Honda Civic',
        serviceReason: 'Flat Tire / Tow',
        distance: '2.8 mi',
        duration: '6 min',
        price: '\$110',
        imagePath: 'assets/images/ford-f150.png',
        position: const LatLng(37.7774, -122.4155),
        pickupAddress: 'Market St & 4th St, SF',
        dropAddress: 'Wheel Works, Potrero Hill, SF',
      ),
      // 4. Mid Left Marker ($125, 4 min)
      NearbyTowRequest(
        id: 'REQ-104',
        vehicleName: 'Tesla Model Y',
        serviceReason: 'Dead Battery Tow',
        distance: '1.5 mi',
        duration: '4 min',
        price: '\$125',
        imagePath: 'assets/images/tesla-model-y.png',
        position: const LatLng(37.7748, -122.4242),
        pickupAddress: 'Hayes St & Octavia Blvd, SF',
        dropAddress: 'Tesla Service Center, 11th St, SF',
      ),
      // 5. Bottom Right Marker ($90, 5 min)
      NearbyTowRequest(
        id: 'REQ-105',
        vehicleName: 'Toyota RAV4',
        serviceReason: 'Winch-out Recovery',
        distance: '1.9 mi',
        duration: '5 min',
        price: '\$90',
        imagePath: 'assets/images/bmw-x5.png',
        position: const LatLng(37.7724, -122.4150),
        pickupAddress: '8th St & Brannan St, SF',
        dropAddress: 'Bayline Towing Yard, SOMA, SF',
      ),
    ];

    _selectedRequest = _nearbyRequests[0];

    // Pulsing radar animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });
    _jobService.toggleOnlineStatus(_isOnline);

    if (_isOnline) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are Online! Scanning for nearby towing requests...'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      _pulseController.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are now Offline. No new dispatch jobs will be sent.'),
          backgroundColor: Color(0xFF64748B),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleAcceptRequest(NearbyTowRequest request) {
    // Convert to TowJob and set as active
    final towJob = TowJob(
      id: request.id,
      serviceTitle: request.serviceReason,
      requestType: request.serviceReason,
      vehicleName: request.vehicleName,
      licensePlate: '7XTR921',
      pickupAddress: request.pickupAddress,
      dropAddress: request.dropAddress,
      pickupLat: request.position.latitude,
      pickupLng: request.position.longitude,
      dropLat: 37.7785,
      dropLng: -122.4056,
      customerName: 'Marcus Vance Customer',
      customerPhone: '+1 (555) 438-9922',
      totalCost: request.price,
      etaOrDuration: request.duration,
      status: JobStatus.accepted,
      createdAt: DateTime.now(),
      notes: 'Customer request accepted from live radar dashboard.',
    );

    _jobService.activeJobNotifier.value = towJob;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF152238),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Text('Dispatch Accepted', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You accepted ${request.vehicleName} (${request.price})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Pickup: ${request.pickupAddress}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'ETA: ${request.duration} • Distance: ${request.distance}',
              style: const TextStyle(color: Color(0xFFFF521B), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay on Radar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ActiveJobScreen(job: towJob),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4800),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Start Navigation'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
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
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 14),
              _buildNotificationItem(
                icon: Icons.local_shipping_rounded,
                iconColor: const Color(0xFFFF4800),
                title: 'High Demand Zone Active',
                desc: 'Surge pricing (+15%) in SOMA & Mission district.',
                time: '2m ago',
              ),
              const SizedBox(height: 10),
              _buildNotificationItem(
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Compliance Verified',
                desc: 'Your commercial driver credentials are all up to date.',
                time: '1h ago',
              ),
              const SizedBox(height: 10),
              _buildNotificationItem(
                icon: Icons.payments_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Daily Payout Processed',
                desc: '\$345.50 transferred to linked bank account.',
                time: 'Yesterday',
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E293B)),
                    ),
                    Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEarningsModal() {
    final driver = _jobService.driver;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Color(0xFF152238),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Today's Performance & Earnings",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: "TODAY'S EARNINGS",
                      value: '\$${driver.todayEarnings.toStringAsFixed(2)}',
                      icon: Icons.payments_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'COMPLETED TOWS',
                      value: '${driver.totalTows}',
                      icon: Icons.local_shipping_rounded,
                      color: const Color(0xFFFF521B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'DRIVER RATING',
                      value: '★ ${driver.rating.toStringAsFixed(2)}',
                      icon: Icons.star_rounded,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'ACCEPTANCE RATE',
                      value: '98%',
                      icon: Icons.speed_rounded,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _showJobsModal() {
    final active = _jobService.activeJob;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
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
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Assigned & Active Jobs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 14),
              if (active != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFF4800)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            active.vehicleName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4800),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              active.status.label,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Pickup: ${active.pickupAddress}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ActiveJobScreen(job: active)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4800),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Open Active Route'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'No active job in progress.\nSelect a request on the radar map to accept.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // 1. Full-Screen Interactive OpenStreetMap
          _buildMapView(),

          // 2. Top Floating Navigation Header
          _buildTopHeader(),

          // 3. Right-hand Map Action Controls (Compass, Layers, Re-center)
          // Dynamically shifts up when the bottom sheet is swiped up!
          _buildRightMapControls(),

          // 4. Bottom Floating Dispatch Sheet (Swipe-up expandable) + Bottom Nav Bar
          _buildBottomContainer(),
        ],
      ),
    );
  }

  // --- MAP VIEW WITH RADAR AND MARKERS ---
  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _driverLocation,
        initialZoom: 15.0,
        minZoom: 12.0,
        maxZoom: 18.5,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // OpenStreetMap Tile Layer (Free, no watermarks, matches customer app)
        TileLayer(
          urlTemplate: _tileLayers[_currentLayerIndex],
          userAgentPackageName: 'com.roacs.towing_driver',
          maxZoom: 19,
        ),

        // Central Radar Pulses & Tow Truck Marker
        MarkerLayer(
          markers: [
            // Center driver tow truck with animated radar waves
            Marker(
              point: _driverLocation,
              width: 250,
              height: 250,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isOnline)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(250, 250),
                            painter: RadarPulsePainter(
                              pulseProgress: _pulseController.value,
                            ),
                          );
                        },
                      ),
                    _buildCenterTowTruckMarker(),
                  ],
                ),
              ),
            ),

            // 5 Surrounding Demand Request Markers (Cleanly positioned on screen)
            ..._nearbyRequests.map((req) {
              final isSelected = req.id == _selectedRequest.id;
              return Marker(
                point: req.position,
                width: 115,
                height: 52,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRequest = req;
                    });
                  },
                  child: _buildRequestMarkerPin(req, isSelected: isSelected),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  // Central Tow Truck Vehicle Widget
  Widget _buildCenterTowTruckMarker() {
    return Transform.rotate(
      angle: -0.45, // Angled slightly to the right matching reference UI
      child: Container(
        width: 48,
        height: 82,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(2, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Front Cab (Vibrant Orange with Windshield & Flashing Light Bar)
            Container(
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFFF521B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Stack(
                children: [
                  // Windshield glass
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Flashing strobe beacon on roof
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 18,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withValues(alpha: 0.8),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Flatbed Tow Deck
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF334155),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.settings_overscan_rounded,
                      color: Color(0xFFFF521B),
                      size: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Request Marker Pin (Red Pin + Price/ETA Pill)
  Widget _buildRequestMarkerPin(NearbyTowRequest req, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF4800) : Colors.black.withValues(alpha: 0.08),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Red-Orange pointer pin with white center
          Container(
            width: 17,
            height: 17,
            decoration: const BoxDecoration(
              color: Color(0xFFFF3B30),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                req.price,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                req.duration,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TOP FLOATING HEADER ---
  Widget _buildTopHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 18,
      right: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Hamburger Menu Button (Circle)
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.menu, color: Color(0xFF1E293B), size: 22),
            ),
          ),

          // Center Pill Status Indicator (Online / Offline Capsule)
          GestureDetector(
            onTap: _toggleOnlineStatus,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing status dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isOnline ? const Color(0xFF00E676) : const Color(0xFF94A3B8),
                      boxShadow: [
                        if (_isOnline)
                          BoxShadow(
                            color: const Color(0xFF00E676).withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
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

          // Right Notification Bell Button (Circle)
          GestureDetector(
            onTap: _showNotificationsSheet,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B), size: 23),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4800),
                        shape: BoxShape.circle,
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

  // --- RIGHT-SIDE MAP FLOATING CONTROLS ---
  Widget _buildRightMapControls() {
    final bottomOffset = _isSheetExpanded
        ? (MediaQuery.of(context).size.height * 0.58 + 80)
        : 265.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      right: 16,
      bottom: bottomOffset,
      child: Column(
        children: [
          // Compass / Navigation Button
          _buildMapCircleButton(
            icon: Icons.near_me_rounded,
            onTap: () {
              _mapController.rotate(0);
            },
          ),
          const SizedBox(height: 10),

          // Layers Switcher Button (Toggles between OpenStreetMap Styles)
          _buildMapCircleButton(
            icon: Icons.layers_outlined,
            onTap: () {
              setState(() {
                _currentLayerIndex = (_currentLayerIndex + 1) % _tileLayers.length;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_currentLayerIndex == 0
                      ? 'Switched to Standard OpenStreetMap'
                      : 'Switched to Humanitarian OpenStreetMap'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // My Location Target Button
          _buildMapCircleButton(
            icon: Icons.my_location_rounded,
            onTap: () {
              _mapController.move(_driverLocation, 15.0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1E293B), size: 21),
      ),
    );
  }

  // --- BOTTOM DISPATCH CARD & BOTTOM NAVIGATION BAR ---
  Widget _buildBottomContainer() {
    final screenHeight = MediaQuery.of(context).size.height;
    final expandedHeight = screenHeight * 0.58;
    const collapsedHeight = 195.0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Swipe-up Expandable Dispatch Card
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -150) {
                  // Swiped UP -> expand
                  setState(() {
                    _isSheetExpanded = true;
                  });
                } else if (details.primaryVelocity! > 150) {
                  // Swiped DOWN -> collapse
                  setState(() {
                    _isSheetExpanded = false;
                  });
                }
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              height: _isSheetExpanded ? expandedHeight : collapsedHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Drag handle pill (Tap toggles expansion)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSheetExpanded = !_isSheetExpanded;
                      });
                    },
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header Row (📍 5 towing requests nearby ... See All / Collapse)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFECE5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFFF4800),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_nearbyRequests.length} towing requests nearby',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSheetExpanded = !_isSheetExpanded;
                            });
                          },
                          child: Row(
                            children: [
                              Text(
                                _isSheetExpanded ? 'Collapse' : 'See All',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFF4800),
                                ),
                              ),
                              Icon(
                                _isSheetExpanded
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.keyboard_arrow_up_rounded,
                                color: const Color(0xFFFF4800),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Content: If collapsed -> Single Card Preview; If expanded -> Full scrollable list of all requests!
                  Expanded(
                    child: _isSheetExpanded
                        ? _buildExpandedRequestsList()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildRequestTile(_selectedRequest, isSinglePreview: true),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Navigation Bar (Home, Jobs, Earnings, Messages, Profile)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            padding: EdgeInsets.only(
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom
                  : 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.work_outline_rounded, 'Jobs'),
                _buildNavItem(2, Icons.bar_chart_rounded, 'Earnings'),
                _buildNavItem(3, Icons.chat_bubble_outline_rounded, 'Messages'),
                _buildNavItem(4, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Expanded list showing all 5 requests
  Widget _buildExpandedRequestsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      itemCount: _nearbyRequests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final req = _nearbyRequests[idx];
        return _buildRequestTile(req, isSinglePreview: false);
      },
    );
  }

  // Request tile builder used both in collapsed single-view and expanded full-list
  Widget _buildRequestTile(NearbyTowRequest req, {required bool isSinglePreview}) {
    final isSelected = req.id == _selectedRequest.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRequest = req;
        });
        _mapController.move(req.position, 15.0);
      },
      child: Container(
        margin: isSinglePreview ? const EdgeInsets.symmetric(horizontal: 18) : EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF9F6) : const Color(0xFFFAFAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4800) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Car thumbnail image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                req.imagePath,
                width: 80,
                height: 52,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => Container(
                  width: 80,
                  height: 52,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.directions_car, color: Colors.grey, size: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Reason
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    req.vehicleName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    req.serviceReason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 13,
                        color: Color(0xFFFF4800),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${req.distance} • ${req.duration}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Price & Accept Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  req.price,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF3B30),
                  ),
                ),
                const SizedBox(height: 6),
                ElevatedButton(
                  onPressed: () => _handleAcceptRequest(req),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4800),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;
    final activeColor = const Color(0xFFFF4800);
    final inactiveColor = const Color(0xFF94A3B8);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });

        if (index == 1) {
          _showJobsModal();
        } else if (index == 2) {
          _showEarningsModal();
        } else if (index == 3) {
          _showNotificationsSheet();
        } else if (index == 4) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
          ).then((_) {
            setState(() {
              _selectedTabIndex = 0;
            });
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 24,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- DRIVER SIDE DRAWER ---
  Widget _buildDrawer() {
    final driver = _jobService.driver;

    return Drawer(
      backgroundColor: const Color(0xFF0B1320),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF521B), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(0xFF1E293B),
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              driver.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Color(0xFF10B981), size: 16),
                          ],
                        ),
                        Text(
                          driver.truckModel,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '★ ${driver.rating.toStringAsFixed(2)} Driver Score',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildDrawerTile(
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.document_scanner_outlined,
                    title: 'Fleet Documents & Verification',
                    badgeText: '1 Pending',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DriverDocumentUploadScreen()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.payments_outlined,
                    title: "Earnings Breakdown",
                    onTap: () {
                      Navigator.of(context).pop();
                      _showEarningsModal();
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.assignment_outlined,
                    title: "Job History & Logs",
                    onTap: () {
                      Navigator.of(context).pop();
                      _showJobsModal();
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.radar_outlined,
                    title: "Check Remote Backend",
                    onTap: () {
                      Navigator.of(context).pop();
                      _jobService.checkBackendForPendingJobs();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Checking PostgreSQL dispatch queue...')),
                      );
                    },
                  ),
                  const Divider(color: Color(0xFF1E293B), height: 24),
                  _buildDrawerTile(
                    icon: Icons.logout_rounded,
                    title: 'Log Out',
                    color: const Color(0xFFEF4444),
                    onTap: () async {
                      await DriverAuthService().logout();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white,
    String? badgeText,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Row(
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 14)),
          if (badgeText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF521B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Color(0xFFFF521B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Custom painter for the animated concentric radar pulses and demand direction cones
class RadarPulsePainter extends CustomPainter {
  final double pulseProgress; // 0.0 to 1.0

  RadarPulsePainter({required this.pulseProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Concentric rings matching reference UI
    final ringPaint = Paint()
      ..color = const Color(0xFFFF521B).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fillPaint = Paint()
      ..color = const Color(0xFFFF521B).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    // Inner ring (radius 40)
    canvas.drawCircle(center, 40, fillPaint);
    canvas.drawCircle(center, 40, ringPaint);

    // Mid ring (radius 72)
    canvas.drawCircle(center, 72, fillPaint..color = const Color(0xFFFF521B).withValues(alpha: 0.04));
    canvas.drawCircle(center, 72, ringPaint..color = const Color(0xFFFF521B).withValues(alpha: 0.18));

    // Outer ring (radius 104)
    canvas.drawCircle(center, 104, ringPaint..color = const Color(0xFFFF521B).withValues(alpha: 0.14));

    // 2. Conical demand fan sectors radiating towards the 5 request locations
    final conePaint = Paint()
      ..color = const Color(0xFFFF521B).withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;

    void drawDemandCone(double startAngle, double sweepAngle, double radius) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
        )
        ..close();
      canvas.drawPath(path, conePaint);
    }

    // Sectors facing the 5 request pins precisely
    drawDemandCone(-0.75, 0.50, 115); // Top-left pin direction (BMW 330i)
    drawDemandCone(0.55, 0.50, 115);  // Top-right pin direction (Honda Civic)
    drawDemandCone(-3.14, 0.45, 115); // Mid-left pin direction (Tesla Model Y)
    drawDemandCone(-2.40, 0.50, 115); // Bottom-left pin direction (Ford F-150)
    drawDemandCone(1.05, 0.45, 115);  // Bottom-right pin direction (Toyota RAV4)

    // 3. Dynamic expanding pulse wave
    final animatedRadius = 40 + (pulseProgress * 75);
    final waveAlpha = (1.0 - pulseProgress).clamp(0.0, 1.0);
    final pulsePaint = Paint()
      ..color = const Color(0xFFFF521B).withValues(alpha: waveAlpha * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, animatedRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant RadarPulsePainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress;
  }
}
