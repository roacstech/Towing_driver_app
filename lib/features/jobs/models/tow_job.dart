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
  String get payoutWhole => '\$${estimatedPayout.toInt()}';
  bool get isHighPay => estimatedPayout >= 150.0;

  List<String> get tags {
    if (requestType.toLowerCase() == 'vehicle transport') {
      return const ['Long Distance', 'SUV'];
    } else if (isUrgent) {
      return ['Urgent Priority', vehicleCategory.split(' ').first];
    } else {
      return ['Standard', vehicleCategory.split(' ').first];
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
      vehicleName: vehicleName,
      vehicleYear: vehicleYear,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehicleCategory: vehicleCategory,
      licensePlate: licensePlate,
      vehicleImage: vehicleImage,
      pickupAddress: pickupAddress,
      dropAddress: dropAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      customerLat: customerLat ?? this.customerLat,
      customerLng: customerLng ?? this.customerLng,
      driverLat: driverLat ?? this.driverLat,
      driverLng: driverLng ?? this.driverLng,
      driverHeading: driverHeading ?? this.driverHeading,
      distanceToPickup: distanceToPickup,
      pickupEta: pickupEta,
      tripDuration: tripDuration,
      customerName: customerName,
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

    final reqType = json['request_type'] ?? json['requestType'] ?? 'Accident Recovery';
    final payout = (json['estimated_payout'] as num?)?.toDouble() ?? 145.00;
    final pLat = (json['pickup_lat'] as num?)?.toDouble() ?? 37.7649;
    final pLng = (json['pickup_lng'] as num?)?.toDouble() ?? -122.4194;

    return TowJob(
      id: json['id']?.toString() ?? 'TOW-${DateTime.now().millisecondsSinceEpoch % 10000}',
      serviceTitle: json['serviceTitle'] ?? json['service_title'] ?? 'Emergency Flatbed Tow',
      requestType: reqType,
      vehicleName: json['vehicleName'] ?? json['vehicle_name'] ?? 'Tesla Model Y',
      vehicleYear: json['vehicle_year'] ?? '2023',
      vehicleMake: json['vehicle_make'] ?? 'Tesla',
      vehicleModel: json['vehicle_model'] ?? 'Model Y',
      vehicleCategory: json['vehicle_category'] ?? 'Electric AWD SUV',
      licensePlate: json['licensePlate'] ?? json['license_plate'] ?? '7XTR921',
      vehicleImage: json['vehicle_image'] ?? 'assets/vehicles/tesla-model-y.png',
      pickupAddress: json['pickupAddress'] ?? json['pickup_address'] ?? 'Mission St & 16th St, San Francisco, CA',
      dropAddress: json['dropAddress'] ?? json['drop_address'] ?? 'City View Auto Repair, SOMA, SF',
      pickupLat: pLat,
      pickupLng: pLng,
      dropLat: (json['drop_lat'] as num?)?.toDouble() ?? 37.7785,
      dropLng: (json['drop_lng'] as num?)?.toDouble() ?? -122.4056,
      customerLat: (json['customer_lat'] as num?)?.toDouble() ?? pLat,
      customerLng: (json['customer_lng'] as num?)?.toDouble() ?? pLng,
      driverLat: (json['driver_lat'] as num?)?.toDouble(),
      driverLng: (json['driver_lng'] as num?)?.toDouble(),
      driverHeading: (json['driver_heading'] as num?)?.toDouble(),
      distanceToPickup: json['distance_to_pickup'] ?? '1.8 mi',
      pickupEta: json['pickup_eta'] ?? '6 min',
      tripDuration: json['trip_duration'] ?? '24 min',
      customerName: json['customer_name'] ?? json['driverName'] ?? 'Sarah Jenkins',
      customerPhone: json['customer_phone'] ?? '+1 (555) 438-9922',
      customerRating: (json['customer_rating'] as num?)?.toDouble() ?? 4.95,
      totalCost: json['totalCost'] ?? json['total_cost'] ?? '\$145.00',
      estimatedPayout: payout,
      basePayout: (json['base_payout'] as num?)?.toDouble() ?? 75.00,
      mileagePayout: (json['mileage_payout'] as num?)?.toDouble() ?? 40.00,
      hazardFee: (json['hazard_fee'] as num?)?.toDouble() ?? 20.00,
      specialEquipmentFee: (json['special_equipment_fee'] as num?)?.toDouble() ?? 10.00,
      etaOrDuration: json['etaOrDuration'] ?? '6 min ETA (1.8 mi)',
      status: parseStatus(json['status']),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] ?? 'Vehicle has front axle lock. Flatbed required.',
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
