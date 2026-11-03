import 'package:flutter/material.dart';

enum JobStatus {
  pending,
  accepted,
  arrived,
  towing,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case JobStatus.pending:
        return 'Dispatch Request';
      case JobStatus.accepted:
        return 'En Route to Pickup';
      case JobStatus.arrived:
        return 'Arrived at Scene';
      case JobStatus.towing:
        return 'Towing in Progress';
      case JobStatus.completed:
        return 'Job Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case JobStatus.pending:
        return const Color(0xFFF59E0B);
      case JobStatus.accepted:
        return const Color(0xFF2563EB);
      case JobStatus.arrived:
        return const Color(0xFF8B5CF6);
      case JobStatus.towing:
        return const Color(0xFF0F172A);
      case JobStatus.completed:
        return const Color(0xFF10B981);
      case JobStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }
}

class TowJob {
  final String id;
  final String serviceTitle;
  final String requestType; // Flat Tire, Dead Battery, Accident Recovery, Lockout, Vehicle Transport
  final String vehicleName;
  final String vehicleYear;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleCategory;
  final String licensePlate;
  final String vehicleImage;
  final String pickupAddress;
  final String dropAddress;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final String distanceToPickup;
  final String pickupEta;
  final String tripDuration;
  final String customerName;
  final String customerPhone;
  final double customerRating;
  final String totalCost;
  final double estimatedPayout;
  final double basePayout;
  final double mileagePayout;
  final double hazardFee;
  final double specialEquipmentFee;
  final String etaOrDuration;
  final JobStatus status;
  final DateTime createdAt;
  final String notes;
  final bool isUrgent;
  final String urgencyReason;
  final List<String> equipmentRequirements;

  final String? driverId;
  final String? driverName;
  final double? customerLat;
  final double? customerLng;
  final double? driverLat;
  final double? driverLng;
  final double? driverHeading;

  const TowJob({
    required this.id,
    required this.serviceTitle,
    required this.requestType,
    required this.vehicleName,
    this.vehicleYear = '2023',
    this.vehicleMake = 'Tesla',
    this.vehicleModel = 'Model Y',
    this.vehicleCategory = 'Electric AWD SUV',
    required this.licensePlate,
    this.vehicleImage = 'assets/vehicles/tesla-model-y.png',
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    this.driverId,
    this.driverName,
    this.customerLat,
    this.customerLng,
    this.driverLat,
    this.driverLng,
    this.driverHeading,
    this.distanceToPickup = '1.8 mi',
    this.pickupEta = '6 min',
    this.tripDuration = '24 min',
    required this.customerName,
    required this.customerPhone,
    this.customerRating = 4.95,
    required this.totalCost,
    this.estimatedPayout = 145.00,
    this.basePayout = 75.00,
    this.mileagePayout = 40.00,
    this.hazardFee = 20.00,
    this.specialEquipmentFee = 10.00,
    required this.etaOrDuration,
    required this.status,
    required this.createdAt,
    this.notes = 'Standard roadside recovery',
    this.isUrgent = false,
    this.urgencyReason = 'Standard Priority',
    this.equipmentRequirements = const ['Flatbed Tow Truck', 'Wheel Chocks', 'Soft Straps'],
  });

  double get effectiveCustomerLat => customerLat ?? pickupLat;
  double get effectiveCustomerLng => customerLng ?? pickupLng;

  String get payoutFormatted => '\$${estimatedPayout.toStringAsFixed(2)}';
  String get payoutWhole => (estimatedPayout % 1 == 0)
      ? '\$${estimatedPayout.toInt()}'
      : '\$${estimatedPayout.toStringAsFixed(2)}';
  bool get isHighPay => estimatedPayout >= 150.0;

  List<String> get tags {
    final cat = vehicleCategory.split(' ').first;
    if (requestType.toLowerCase().contains('transport') || requestType.toLowerCase().contains('distance')) {
      return ['Long Distance', cat];
    } else if (isUrgent) {
      return ['Urgent Priority', cat];
    } else if (serviceTitle.toLowerCase().contains('medium')) {
      return ['Medium-Duty', cat];
    } else if (serviceTitle.toLowerCase().contains('heavy')) {
      return ['Heavy-Duty', cat];
    } else {
      return ['Standard', cat];
    }
  }

  IconData get requestTypeIcon {
    switch (requestType.toLowerCase()) {
      case 'flat tire':
        return Icons.tire_repair_rounded;
      case 'dead battery':
        return Icons.battery_charging_full_rounded;
      case 'accident recovery':
        return Icons.car_crash_rounded;
      case 'lockout':
        return Icons.key_rounded;
      case 'vehicle transport':
      default:
        return Icons.fire_truck_rounded;
    }
  }

  TowJob copyWith({
    JobStatus? status,
    String? etaOrDuration,
    String? notes,
    bool? isUrgent,
    double? estimatedPayout,
    String? driverId,
    String? driverName,
    String? customerName,
    String? vehicleName,
    String? pickupAddress,
    String? licensePlate,
    double? customerLat,
    double? customerLng,
    double? driverLat,
    double? driverLng,
    double? driverHeading,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
  }) {
    return TowJob(
      id: id,
      serviceTitle: serviceTitle,
      requestType: requestType,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleYear: vehicleYear,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehicleCategory: vehicleCategory,
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleImage: vehicleImage,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropAddress: dropAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      customerLat: customerLat ?? this.customerLat,
      customerLng: customerLng ?? this.customerLng,
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      driverHeading: driverHeading ?? this.driverHeading,
      distanceToPickup: distanceToPickup,
      pickupEta: pickupEta,
      tripDuration: tripDuration,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone,
      customerRating: customerRating,
      totalCost: totalCost,
      estimatedPayout: estimatedPayout ?? this.estimatedPayout,
      basePayout: basePayout,
      mileagePayout: mileagePayout,
      hazardFee: hazardFee,
      specialEquipmentFee: specialEquipmentFee,
      etaOrDuration: etaOrDuration ?? this.etaOrDuration,
      status: status ?? this.status,
      createdAt: createdAt,
      notes: notes ?? this.notes,
      isUrgent: isUrgent ?? this.isUrgent,
      urgencyReason: urgencyReason,
      equipmentRequirements: equipmentRequirements,
    );
  }

  factory TowJob.fromJson(Map<String, dynamic> json) {
    JobStatus parseStatus(dynamic s) {
      final str = s?.toString().toLowerCase() ?? 'pending';
      if (str.contains('complete')) return JobStatus.completed;
      if (str.contains('cancel')) return JobStatus.cancelled;
      if (str.contains('tow')) return JobStatus.towing;
      if (str.contains('arriv')) return JobStatus.arrived;
      if (str.contains('active') || str.contains('accept')) return JobStatus.accepted;
      return JobStatus.pending;
    }

    double? parseCoord(dynamic val) {
      if (val == null) return null;
      return double.tryParse(val.toString());
    }

    // Dynamic Service Title & Request Type
    final serviceTitle = (json['service_title'] ?? json['serviceTitle'] ?? 'Roadside Towing').toString();
    final reqType = (json['request_type'] ?? json['requestType'] ?? serviceTitle).toString();

    // Dynamic Vehicle Name, Make, Model, Year, Category & Image
    final rawVehicleName = (json['vehicle_name'] ?? json['vehicleName'] ?? 'Customer Vehicle').toString();
    
    // Extract year if present at beginning of vehicle name (e.g. "2023 Honda Accord")
    String parsedYear = (json['vehicle_year'] ?? json['year'])?.toString() ?? '';
    String vehicleName = rawVehicleName;
    final yearMatch = RegExp(r'^(\d{4})\s+(.+)$').firstMatch(rawVehicleName);
    if (yearMatch != null) {
      parsedYear = yearMatch.group(1)!;
      vehicleName = yearMatch.group(2)!;
    }
    if (parsedYear.isEmpty) parsedYear = '2024';

    // Dynamic vehicle make & model
    String vehicleMake = (json['vehicle_make'] ?? json['make'])?.toString() ?? '';
    String vehicleModel = (json['vehicle_model'] ?? json['model'])?.toString() ?? '';
    if (vehicleMake.isEmpty) {
      final parts = vehicleName.split(' ');
      vehicleMake = parts.isNotEmpty ? parts.first : 'Vehicle';
      vehicleModel = parts.length > 1 ? parts.sublist(1).join(' ') : 'Model';
    }

    // Dynamic category determination
    String vehicleCategory = (json['vehicle_category'] ?? json['vehicle_type'])?.toString() ?? '';
    if (vehicleCategory.isEmpty) {
      final lowerName = rawVehicleName.toLowerCase();
      if (lowerName.contains('tesla') || lowerName.contains('ev ') || lowerName.contains('electric')) {
        vehicleCategory = 'Electric AWD';
      } else if (lowerName.contains('suv') || lowerName.contains('x5') || lowerName.contains('fortuner') || lowerName.contains('creta')) {
        vehicleCategory = 'Mid-Size SUV';
      } else if (lowerName.contains('truck') || lowerName.contains('f-150') || lowerName.contains('pickup')) {
        vehicleCategory = 'Full-Size Truck';
      } else {
        vehicleCategory = 'Sedan';
      }
    }

    // Dynamic vehicle asset image mapping
    String vehicleImage = (json['vehicle_image'] ?? json['asset_path'] ?? json['assetPath'])?.toString() ?? '';
    if (!vehicleImage.startsWith('assets/vehicles/') && !vehicleImage.startsWith('assets/home/vehicles/')) {
      final lowerName = rawVehicleName.toLowerCase();
      if (lowerName.contains('tesla')) {
        vehicleImage = 'assets/vehicles/tesla-model-y.png';
      } else if (lowerName.contains('bmw') || lowerName.contains('fortuner') || lowerName.contains('suv')) {
        vehicleImage = 'assets/vehicles/bmw-x5.png';
      } else if (lowerName.contains('ford') || lowerName.contains('truck') || lowerName.contains('f-150')) {
        vehicleImage = 'assets/vehicles/ford-f150.png';
      } else if (lowerName.contains('audi')) {
        vehicleImage = 'assets/vehicles/audi_test.png';
      } else {
        // High quality transparent sedan asset (Honda City, Accord, Toyota, Hyundai, etc.)
        vehicleImage = 'assets/vehicles/hyundai_test.png';
      }
    }

    // Dynamic Estimated Payout based on customer fare
    final totalCostStr = (json['total_cost'] ?? json['totalCost'])?.toString() ?? '\$120.00';
    double payout = (json['estimated_payout'] as num?)?.toDouble() ?? 0.0;
    if (payout <= 0) {
      final costNum = double.tryParse(totalCostStr.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (costNum != null && costNum > 0) {
        // Driver earnings matches customer fare exactly
        payout = costNum;
      } else {
        payout = 120.00;
      }
    }

    // Dynamic Coordinates with regex extraction & Coimbatore regional landmarks
    final rawPickupAddress = (json['pickupAddress'] ?? json['pickup_address'] ?? '').toString();
    final rawDropAddress = (json['dropAddress'] ?? json['drop_address'] ?? '').toString();

    // Helper to extract (lat, lng) from address strings like "(11.1389, 77.0326)"
    double? extractCoordFromText(String text, int index) {
      final match = RegExp(r'\((-?\d+\.?\d*),\s*(-?\d+\.?\d*)\)').firstMatch(text);
      if (match != null && match.groupCount >= 2) {
        return double.tryParse(match.group(index)!);
      }
      return null;
    }

    // Helper for known Coimbatore hubs
    String lookupCoimbatoreHubName(double lat, double lng) {
      if ((lat - 11.1085).abs() < 0.020 && (lng - 77.0195).abs() < 0.020) {
        return 'Kurumbapalayam, Coimbatore North';
      }
      if ((lat - 11.1388).abs() < 0.025 && (lng - 77.0326).abs() < 0.025) {
        return 'Onnipalayam Pudur, Coimbatore North';
      }
      if ((lat - 11.1440).abs() < 0.025 && (lng - 77.0540).abs() < 0.025) {
        return 'Kovilpalayam, Kunnathur';
      }
      if ((lat - 11.0805).abs() < 0.025 && (lng - 76.9961).abs() < 0.025) {
        return 'Saravanampatti, Coimbatore';
      }
      if ((lat - 11.0268).abs() < 0.025 && (lng - 77.0028).abs() < 0.025) {
        return 'Peelamedu, Coimbatore';
      }
      if ((lat - 11.0028).abs() < 0.025 && (lng - 77.0189).abs() < 0.025) {
        return 'Singanallur, Coimbatore';
      }
      if ((lat - 11.0183).abs() < 0.025 && (lng - 76.9644).abs() < 0.025) {
        return 'Gandhipuram, Coimbatore';
      }
      return 'Onnipalayam Pudur, Coimbatore North';
    }

    double? lookupCoimbatoreHubLat(String address) {
      final lower = address.toLowerCase();
      if (lower.contains('onnipalayam')) return 11.1389;
      if (lower.contains('kurumbapalayam')) return 11.1085;
      if (lower.contains('kunnathur') || lower.contains('kovilpalayam')) return 11.1440;
      if (lower.contains('saravanampatti')) return 11.0805;
      if (lower.contains('peelamedu') || lower.contains('avinashi')) return 11.0268;
      if (lower.contains('trichy road') || lower.contains('singanallur')) return 11.0028;
      if (lower.contains('gandhipuram')) return 11.0183;
      return null;
    }

    double? lookupCoimbatoreHubLng(String address) {
      final lower = address.toLowerCase();
      if (lower.contains('onnipalayam')) return 77.0326;
      if (lower.contains('kurumbapalayam')) return 77.0195;
      if (lower.contains('kunnathur') || lower.contains('kovilpalayam')) return 77.0540;
      if (lower.contains('saravanampatti')) return 76.9961;
      if (lower.contains('peelamedu') || lower.contains('avinashi')) return 77.0028;
      if (lower.contains('trichy road') || lower.contains('singanallur')) return 77.0189;
      if (lower.contains('gandhipuram')) return 76.9644;
      return null;
    }

    final pLat = parseCoord(json['pickup_lat'] ?? json['pickupLat']) ??
        extractCoordFromText(rawPickupAddress, 1) ??
        lookupCoimbatoreHubLat(rawPickupAddress) ??
        11.1389;

    final pLng = parseCoord(json['pickup_lng'] ?? json['pickupLng']) ??
        extractCoordFromText(rawPickupAddress, 2) ??
        lookupCoimbatoreHubLng(rawPickupAddress) ??
        77.0325;

    final dLat = parseCoord(json['drop_lat'] ?? json['dropLat']) ??
        extractCoordFromText(rawDropAddress, 1) ??
        lookupCoimbatoreHubLat(rawDropAddress) ??
        (pLat + 0.015);

    final dLng = parseCoord(json['drop_lng'] ?? json['dropLng']) ??
        extractCoordFromText(rawDropAddress, 2) ??
        lookupCoimbatoreHubLng(rawDropAddress) ??
        (pLng + 0.012);

    final custLat = parseCoord(json['customer_lat'] ?? json['customerLat']) ?? pLat;
    final custLng = parseCoord(json['customer_lng'] ?? json['customerLng']) ?? pLng;

    // Real Customer Identity Resolution (from payload or date_formatted / notes)
    String customerName = (json['customer_name'] ?? json['customerName'] ?? '').toString().trim();
    String customerPhone = (json['customer_phone'] ?? json['customerPhone'] ?? '').toString().trim();

    final dateStr = (json['date_formatted'] ?? json['dateFormatted'] ?? '').toString();
    if (customerName.isEmpty || customerName.toLowerCase() == 'customer') {
      final match = RegExp(r'\[Customer:\s*([^|\]]+)').firstMatch(dateStr);
      if (match != null) {
        customerName = match.group(1)!.trim();
      }
    }
    if (customerPhone.isEmpty || customerPhone.contains('019-2831')) {
      final matchPhone = RegExp(r'Phone:\s*([^\]]+)').firstMatch(dateStr);
      if (matchPhone != null) {
        customerPhone = matchPhone.group(1)!.trim();
      }
    }

    final notes = (json['notes'] ?? json['special_notes'])?.toString() ?? 'Customer requested $serviceTitle. Proceed to pickup coordinates.';

    // Clean addresses: Never display raw "Current Location (lat, lng)" or raw coordinates
    String resolvedPickup = (json['pickupAddress'] ?? json['pickup_address'] ?? '').toString().trim();
    if (resolvedPickup.contains('(')) {
      resolvedPickup = resolvedPickup.replaceAll(RegExp(r'\s*\(-?\d+\.?\d*,\s*-?\d+\.?\d*\)'), '').trim();
    }
    if (resolvedPickup.isEmpty || 
        resolvedPickup.toLowerCase().startsWith('current location') ||
        (resolvedPickup.toLowerCase().contains('kovilpalayam') && (pLat - 11.1388).abs() < 0.015)) {
      resolvedPickup = lookupCoimbatoreHubName(pLat, pLng);
    }

    String resolvedDrop = (json['dropAddress'] ?? json['drop_address'] ?? '').toString().trim();
    if (resolvedDrop.contains('(')) {
      resolvedDrop = resolvedDrop.replaceAll(RegExp(r'\s*\(-?\d+\.?\d*,\s*-?\d+\.?\d*\)'), '').trim();
    }
    if (resolvedDrop.isEmpty || resolvedDrop.toLowerCase().startsWith('current location')) {
      resolvedDrop = lookupCoimbatoreHubName(dLat, dLng);
    }

    return TowJob(
      id: json['id']?.toString() ?? 'TW-${DateTime.now().millisecondsSinceEpoch % 100000}',
      serviceTitle: serviceTitle,
      requestType: reqType,
      vehicleName: vehicleName,
      vehicleYear: parsedYear,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehicleCategory: vehicleCategory,
      licensePlate: json['licensePlate'] ?? json['license_plate'] ?? '',
      vehicleImage: vehicleImage,
      pickupAddress: resolvedPickup,
      dropAddress: resolvedDrop,
      pickupLat: pLat,
      pickupLng: pLng,
      dropLat: dLat,
      dropLng: dLng,
      driverId: (json['driver_id'] ?? json['driverId'])?.toString(),
      driverName: (json['driver_name'] ?? json['driverName'])?.toString(),
      customerLat: custLat,
      customerLng: custLng,
      driverLat: parseCoord(json['driver_lat'] ?? json['driverLat']),
      driverLng: parseCoord(json['driver_lng'] ?? json['driverLng']),
      driverHeading: parseCoord(json['driver_heading'] ?? json['driverHeading']),
      distanceToPickup: json['distance_to_pickup'] ?? (json['distance_miles'] != null ? '${json['distance_miles']} mi' : '1.8 mi'),
      pickupEta: json['pickup_eta'] ?? (json['eta_or_duration'] ?? '6 min'),
      tripDuration: json['trip_duration'] ?? '24 min',
      customerName: customerName.isNotEmpty ? customerName : 'Customer',
      customerPhone: customerPhone.isNotEmpty ? customerPhone : '+1 (555) 019-2831',
      customerRating: (json['customer_rating'] as num?)?.toDouble() ?? 4.95,
      totalCost: totalCostStr,
      estimatedPayout: payout,
      basePayout: double.parse((payout * 0.6).toStringAsFixed(2)),
      mileagePayout: double.parse((payout * 0.4).toStringAsFixed(2)),
      hazardFee: (json['hazard_fee'] as num?)?.toDouble() ?? 0.00,
      specialEquipmentFee: (json['special_equipment_fee'] as num?)?.toDouble() ?? 0.00,
      etaOrDuration: json['etaOrDuration'] ?? json['eta_or_duration'] ?? '6 min ETA (1.8 mi)',
      status: parseStatus(json['status']),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: notes,
      isUrgent: json['is_urgent'] ?? false,
      urgencyReason: json['urgency_reason'] ?? 'Standard Priority',
      equipmentRequirements: (json['equipment_requirements'] as List?)?.map((e) => e.toString()).toList() ??
          const ['Flatbed Tow Truck', 'Wheel Chocks', 'Soft Straps'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_title': serviceTitle,
      'request_type': requestType,
      'vehicle_name': vehicleName,
      'vehicle_year': vehicleYear,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_category': vehicleCategory,
      'license_plate': licensePlate,
      'vehicle_image': vehicleImage,
      'pickup_address': pickupAddress,
      'drop_address': dropAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'drop_lat': dropLat,
      'drop_lng': dropLng,
      'driver_id': driverId,
      'driver_name': driverName,
      'distance_to_pickup': distanceToPickup,
      'pickup_eta': pickupEta,
      'trip_duration': tripDuration,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_rating': customerRating,
      'total_cost': totalCost,
      'estimated_payout': estimatedPayout,
      'base_payout': basePayout,
      'mileage_payout': mileagePayout,
      'hazard_fee': hazardFee,
      'special_equipment_fee': specialEquipmentFee,
      'etaOrDuration': etaOrDuration,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'is_urgent': isUrgent,
      'urgency_reason': urgencyReason,
      'equipment_requirements': equipmentRequirements,
    };
  }

  /// Real incoming requests are populated live from the backend API.
  static List<TowJob> sampleRequests = [];
}
