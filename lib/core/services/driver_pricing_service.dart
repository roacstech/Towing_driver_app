import 'dart:math';

class DriverPricingBreakdown {
  final double baseFee;
  final double perMileRate;
  final double perKmRate;
  final double distanceMiles;
  final double distanceKm;
  final double freeMiles;
  final double freeKm;
  final double billableMiles;
  final double billableKm;
  final double distanceCost;
  final double prioritySurcharge;
  final double totalCost;
  final String serviceTitle;

  const DriverPricingBreakdown({
    required this.baseFee,
    required this.perMileRate,
    double? perKmRate,
    required this.distanceMiles,
    double? distanceKm,
    required this.freeMiles,
    double? freeKm,
    required this.billableMiles,
    double? billableKm,
    required this.distanceCost,
    required this.prioritySurcharge,
    required this.totalCost,
    this.serviceTitle = 'Light-Duty Towing',
  })  : perKmRate = perKmRate ?? (perMileRate / 1.60934),
        distanceKm = distanceKm ?? (distanceMiles * 1.60934),
        freeKm = freeKm ?? (freeMiles * 1.60934),
        billableKm = billableKm ?? (billableMiles * 1.60934);

  String get baseFeeFormatted => '\$${baseFee.toStringAsFixed(2)}';
  String get perMileRateFormatted => '\$${perMileRate.toStringAsFixed(2)}/mi';
  String get perKmRateFormatted => '\$${perKmRate.toStringAsFixed(2)}/km';
  String get distanceCostFormatted => '\$${distanceCost.toStringAsFixed(2)}';
  String get prioritySurchargeFormatted => '\$${prioritySurcharge.toStringAsFixed(2)}';
  String get totalCostFormatted => '\$${totalCost.toStringAsFixed(2)}';
  String get distanceMilesFormatted => '${distanceMiles.toStringAsFixed(1)} mi';
  String get distanceKmFormatted => '${distanceKm.toStringAsFixed(1)} km';
  String get billableMilesFormatted => '${billableMiles.toStringAsFixed(1)} mi';
  String get billableKmFormatted => '${billableKm.toStringAsFixed(1)} km';
  String get ratePerDistanceLabel => '\$${perMileRate.toStringAsFixed(2)}/mi (\$${perKmRate.toStringAsFixed(2)}/km)';
  String get rateFormula =>
      '${billableMiles.toStringAsFixed(1)} mi (${billableKm.toStringAsFixed(1)} km) @ \$${perMileRate.toStringAsFixed(2)}/mi (\$${perKmRate.toStringAsFixed(2)}/km)';
}

class DriverPricingService {
  static final DriverPricingService _instance = DriverPricingService._internal();
  factory DriverPricingService() => _instance;
  DriverPricingService._internal();

  /// Resolves exact pricing breakdown matching admin fixed service costs & per-km/per-mile rates
  DriverPricingBreakdown getBreakdown({
    required String serviceTitle,
    String? vehicleType,
    double? distanceMiles,
    String? totalCostString,
  }) {
    final titleLower = serviceTitle.toLowerCase();
    final vehicleLower = (vehicleType ?? '').toLowerCase();

    // 1. Identify rate tier: light, medium, heavy, motorcycle
    String tier = 'light';
    if (titleLower.contains('motorcycle') || vehicleLower.contains('motorcycle') || vehicleLower.contains('bike')) {
      tier = 'motorcycle';
    } else if (titleLower.contains('heavy') ||
        vehicleLower.contains('heavy') ||
        vehicleLower.contains('semi') ||
        vehicleLower.contains('tractor') ||
        vehicleLower.contains('commercial')) {
      tier = 'heavy';
    } else if (titleLower.contains('medium') ||
        vehicleLower.contains('medium') ||
        vehicleLower.contains('van') ||
        vehicleLower.contains('rv') ||
        vehicleLower.contains('bus')) {
      tier = 'medium';
    }

    // 2. Fixed Admin Base Prices
    double baseFee = 65.0;
    if (titleLower.contains('heavy')) {
      baseFee = 160.0;
    } else if (titleLower.contains('accident')) {
      baseFee = 120.0;
    } else if (titleLower.contains('ev') || titleLower.contains('electric')) {
      baseFee = 95.0;
    } else if (titleLower.contains('medium')) {
      baseFee = 85.0;
    } else if (titleLower.contains('flatbed')) {
      baseFee = 80.0;
    } else if (titleLower.contains('winch')) {
      baseFee = 75.0;
    } else if (titleLower.contains('motorcycle')) {
      baseFee = 70.0;
    } else if (titleLower.contains('lock') || titleLower.contains('key')) {
      baseFee = 50.0;
    } else if (titleLower.contains('tire') || titleLower.contains('flat')) {
      baseFee = 45.0;
    } else if (titleLower.contains('roadside')) {
      baseFee = 45.0;
    } else if (titleLower.contains('jump') || titleLower.contains('battery')) {
      baseFee = 40.0;
    } else if (titleLower.contains('fuel') || titleLower.contains('gas')) {
      baseFee = 35.0;
    } else {
      baseFee = 65.0;
    }

    // 3. Distance Rate per mile & per km
    double perMileRate = 4.50;
    double freeMiles = 5.0;

    if (tier == 'heavy') {
      perMileRate = 9.50;
    } else if (tier == 'medium') {
      perMileRate = 6.50;
    } else if (tier == 'motorcycle') {
      perMileRate = 4.00;
    } else {
      perMileRate = 4.50;
    }

    // Check if totalCostString already provides explicit total (e.g. "$92.45")
    double? parsedTotal;
    if (totalCostString != null && totalCostString.isNotEmpty) {
      parsedTotal = double.tryParse(totalCostString.replaceAll(RegExp(r'[^0-9.]'), ''));
    }

    double finalDistanceMiles = distanceMiles ?? 11.1;
    double billableMiles = max(0.0, finalDistanceMiles - freeMiles);
    double distanceCost = double.parse((billableMiles * perMileRate).toStringAsFixed(2));

    // If a total was already booked by customer, deduce distance cost consistently
    if (parsedTotal != null && parsedTotal > baseFee) {
      distanceCost = double.parse((parsedTotal - baseFee).toStringAsFixed(2));
      billableMiles = double.parse((distanceCost / perMileRate).toStringAsFixed(1));
      finalDistanceMiles = billableMiles + freeMiles;
    } else if (parsedTotal != null && parsedTotal > 0 && parsedTotal <= baseFee) {
      baseFee = parsedTotal;
      distanceCost = 0.0;
      billableMiles = 0.0;
    }

    final total = double.parse((baseFee + distanceCost).toStringAsFixed(2));

    return DriverPricingBreakdown(
      baseFee: baseFee,
      perMileRate: perMileRate,
      distanceMiles: finalDistanceMiles,
      freeMiles: freeMiles,
      billableMiles: billableMiles,
      distanceCost: distanceCost,
      prioritySurcharge: 0.0,
      totalCost: total,
      serviceTitle: serviceTitle.replaceAll('\n', ' ').trim(),
    );
  }
}

