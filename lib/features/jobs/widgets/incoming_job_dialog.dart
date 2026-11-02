import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/driver_colors.dart';
import '../models/tow_job.dart';
import '../services/driver_job_service.dart';

class IncomingJobDialog extends StatefulWidget {
  final TowJob job;

  const IncomingJobDialog({super.key, required this.job});

  @override
  State<IncomingJobDialog> createState() => _IncomingJobDialogState();
}

class _IncomingJobDialogState extends State<IncomingJobDialog> {
  int _secondsLeft = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _countdownTimer?.cancel();
        DriverJobService().declineJob(widget.job);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsLeft / 30.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: DriverColors.bottomSheetShadow,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Job type badge & Payout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: DriverColors.blueTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DriverColors.blueBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on_rounded, color: DriverColors.electricBlue, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'NEW DISPATCH OFFER',
                        style: TextStyle(
                          color: DriverColors.electricBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.job.payoutFormatted,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: DriverColors.emeraldDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Vehicle title & license plate
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DriverColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fire_truck_rounded,
                    color: DriverColors.textNavy,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.job.vehicleName,
                        style: const TextStyle(
                          color: DriverColors.textNavy,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Plate: ${widget.job.licensePlate} • ${widget.job.serviceTitle}',
                        style: const TextStyle(
                          color: DriverColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pickup & Destination info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DriverColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DriverColors.surfaceBorderLight),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 10, color: DriverColors.electricBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.job.pickupAddress,
                          style: const TextStyle(
                            color: DriverColors.textNavy,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(height: 1, color: DriverColors.surfaceBorder),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: DriverColors.emeraldGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.job.dropAddress,
                          style: const TextStyle(
                            color: DriverColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Countdown timer progress bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Auto-pass in $_secondsLeft seconds',
                      style: const TextStyle(
                        color: DriverColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.job.distanceToPickup,
                      style: const TextStyle(
                        color: DriverColors.electricBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: DriverColors.surfaceBorder,
                  color: progress > 0.3 ? DriverColors.emeraldGreen : DriverColors.alertRed,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Actions: Reject / Accept
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _countdownTimer?.cancel();
                      DriverJobService().declineJob(widget.job);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: DriverColors.surfaceBorder, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      foregroundColor: DriverColors.textSecondary,
                    ),
                    child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      _countdownTimer?.cancel();
                      DriverJobService().acceptJob(widget.job);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DriverColors.emeraldGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Accept Job',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}
