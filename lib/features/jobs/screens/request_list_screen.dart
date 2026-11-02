import 'package:flutter/material.dart';
import '../../../core/constants/driver_colors.dart';
import '../../../core/services/driver_sound_service.dart';
import '../models/tow_job.dart';
import '../services/driver_job_service.dart';
import '../../profile/models/driver_profile.dart';
import 'active_job_screen.dart';
import 'trip_details_screen.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  final DriverJobService _jobService = DriverJobService();

  void _handleTapJob(TowJob job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => TripDetailsScreen(job: job),
      ),
    );
  }

  void _handleAcceptJob(TowJob job) {
    DriverSoundService.playAcceptSound();
    _jobService.acceptJob(job);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Job Accepted!',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Text(
                    'En route to ${job.vehicleName}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ActiveJobScreen(job: job),
      ),
    );
  }

  void _handleRejectJob(TowJob job) {
    DriverSoundService.playPassSound();
    _jobService.declineJob(job);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        content: Text(
          'Request for ${job.vehicleName} passed.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                color: DriverColors.textNavy,
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Available Requests',
          style: TextStyle(
            color: DriverColors.textNavy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ValueListenableBuilder<DriverProfile>(
        valueListenable: _jobService.driverNotifier,
        builder: (context, driver, _) {
          if (!driver.isOnline) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: DriverColors.surfaceSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.power_settings_new_rounded,
                        color: DriverColors.textMuted,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "You're Currently Offline",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: DriverColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Go online to view and accept active dispatch requests in your area.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: DriverColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _jobService.toggleOnlineStatus(true),
                      icon: const Icon(Icons.bolt_rounded, size: 20),
                      label: const Text(
                        'Go Online',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DriverColors.emeraldGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ValueListenableBuilder<List<TowJob>>(
            valueListenable: _jobService.availableRequestsNotifier,
            builder: (context, requests, _) {
              if (requests.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 56,
                          color: DriverColors.textMuted,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Available Requests',
                          style: TextStyle(
                            color: DriverColors.textNavy,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'New dispatch requests in your area will appear here in real time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: DriverColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: requests.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final job = requests[index];
                  return _buildRequestCard(context, job);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, TowJob job) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _handleTapJob(job),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Premium Vehicle Showroom Stage
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Container(
                  height: 155,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF8FAFC),
                        Color(0xFFEEF2F6),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Showroom floor soft shadow
                      Positioned(
                        bottom: 12,
                        child: Container(
                          width: 200,
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(Radius.elliptical(200, 14)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Centered Vehicle Image
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        child: Center(
                          child: Image.asset(
                            job.vehicleImage,
                            height: 125,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: Icon(
                                    Icons.fire_truck_rounded,
                                    size: 48,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Year & Category Pill (Top Left)
                      Positioned(
                        top: 10,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '${job.vehicleYear} · ${job.vehicleCategory}',
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ),

                      // Urgent / Distance Pill (Top Right)
                      if (job.isUrgent)
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
                                SizedBox(width: 3),
                                Text(
                                  'URGENT HAZARD',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  size: 12,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${job.distanceToPickup} (${job.pickupEta})',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. Card Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Title, Vehicle & Payout Header Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Deep Blue Circle Icon Container
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E3A8A),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.directions_car_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.requestType,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${job.vehicleYear} ${job.vehicleName}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right: Price & Est. Earnings
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              job.payoutWhole,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Est. Earnings',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Pickup & Dropoff Route Container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          // Pickup Address Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PICKUP',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    Text(
                                      job.pickupAddress,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Vertical route connector
                          Padding(
                            padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 2,
                                  height: 10,
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ],
                            ),
                          ),

                          // Dropoff Address Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF2F2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'DROPOFF',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    Text(
                                      job.dropAddress,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tags Row: e.g. Urgent Priority, Full-Size
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: job.tags.map((tag) {
                        final isPurple = tag.toLowerCase().contains('long') ||
                            tag.toLowerCase().contains('distance') ||
                            tag.toLowerCase().contains('urgent');
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isPurple
                                ? const Color(0xFFF3E8FF)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: isPurple
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFF475569),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 3. Action Buttons Side-by-Side In Line (52px height)
                    Row(
                      children: [
                        // Compact Icon-Only Pass Button (52x52)
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              splashColor: const Color(0xFFF1F5F9),
                              highlightColor: const Color(0xFFF8FAFC),
                              onTap: () => _handleRejectJob(job),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFF64748B),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Wide Prominent Accept Button (Expanded in line next to Pass button)
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(26),
                                onTap: () => _handleAcceptJob(job),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.38),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Accept',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
      ),
    );
  }
}
