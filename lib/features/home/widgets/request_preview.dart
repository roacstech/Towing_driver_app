import 'package:flutter/material.dart';
import '../../../core/constants/driver_colors.dart';
import '../../jobs/models/tow_job.dart';

class RequestPreview extends StatelessWidget {
  final TowJob job;

  const RequestPreview({
    super.key,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 16),
      child: Transform.scale(
        scale: 0.94,
        child: Container(
          decoration: BoxDecoration(
            color: DriverColors.surfaceWhite.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: DriverColors.surfaceBorder,
              width: 1,
            ),
            boxShadow: DriverColors.cardShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top preview row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DriverColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(job.requestTypeIcon, size: 14, color: DriverColors.textSecondary),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              job.requestType,
                              style: const TextStyle(
                                color: DriverColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    job.payoutFormatted,
                    style: const TextStyle(
                      color: DriverColors.textNavy,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Vehicle preview
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 56,
                      height: 40,
                      color: Colors.white,
                      child: Image.asset(
                        job.vehicleImage,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.directions_car, color: DriverColors.textMuted);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${job.vehicleYear} ${job.vehicleName}',
                          style: const TextStyle(
                            color: DriverColors.textNavy,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${job.distanceToPickup} away · ${job.pickupEta} ETA',
                          style: const TextStyle(
                            color: DriverColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Dummy placeholder for button space
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: DriverColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
