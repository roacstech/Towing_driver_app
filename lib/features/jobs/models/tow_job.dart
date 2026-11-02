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
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropLat: dropLat,
      dropLng: dropLng,
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
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 37.7649,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? -122.4194,
      dropLat: (json['drop_lat'] as num?)?.toDouble() ?? 37.7785,
      dropLng: (json['drop_lng'] as num?)?.toDouble() ?? -122.4056,
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

  /// Curated realistic mock jobs representing the 5 core towing & roadside categories.
  static List<TowJob> sampleRequests = [
    TowJob(
      id: 'TOW-1001',
      serviceTitle: 'Vehicle Transport',
      requestType: 'Vehicle Transport',
      vehicleName: 'Ford F-150',
      vehicleYear: '2023',
      vehicleMake: 'Ford',
      vehicleModel: 'F-150',
      vehicleCategory: 'Pickup',
      licensePlate: 'MD-8492',
      vehicleImage: 'assets/vehicles/ford-f150.png',
      pickupAddress: '7800 Georgia Ave, Silver Spring, MD',
      dropAddress: '4521 Lee Hwy, Arlington, VA',
      pickupLat: 38.9877,
      pickupLng: -77.0270,
      dropLat: 38.8950,
      dropLng: -77.1150,
      distanceToPickup: '4.4 mi',
      pickupEta: '12 min',
      tripDuration: '28 min',
      customerName: 'Marcus Bennett',
      customerPhone: '+1 (555) 782-1200',
      customerRating: 4.95,
      totalCost: '\$180.00',
      estimatedPayout: 180.00,
      basePayout: 95.00,
      mileagePayout: 55.00,
      hazardFee: 15.00,
      specialEquipmentFee: 15.00,
      etaOrDuration: '12 min ETA (4.4 mi)',
      status: JobStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      notes: 'Vehicle transport. Long distance run, flatbed carrier required.',
      isUrgent: false,
      urgencyReason: 'High Pay',
      equipmentRequirements: const [
        'Flatbed Carrier',
        'Wheel Straps',
        'Heavy Duty Winch',
      ],
    ),
    TowJob(
      id: 'TOW-9041',
      serviceTitle: 'Emergency Accident Recovery',
      requestType: 'Accident Recovery',
      vehicleName: 'Tesla Model Y Long Range',
      vehicleYear: '2023',
      vehicleMake: 'Tesla',
      vehicleModel: 'Model Y',
      vehicleCategory: 'Electric AWD SUV',
      licensePlate: '7XTR921',
      vehicleImage: 'assets/vehicles/tesla-model-y.png',
      pickupAddress: 'US-101 Northbound @ Exit 432B, San Francisco',
      dropAddress: 'City Collision & Frame Repair, 1450 Folsom St',
      pickupLat: 37.7680,
      pickupLng: -122.4095,
      dropLat: 37.7735,
      dropLng: -122.4130,
      distanceToPickup: '1.4 mi',
      pickupEta: '5 min',
      tripDuration: '26 min',
      customerName: 'Sarah Jenkins',
      customerPhone: '+1 (555) 438-9922',
      customerRating: 4.96,
      totalCost: '\$185.00',
      estimatedPayout: 185.00,
      basePayout: 85.00,
      mileagePayout: 45.00,
      hazardFee: 35.00,
      specialEquipmentFee: 20.00,
      etaOrDuration: '5 min ETA (1.4 mi)',
      status: JobStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      notes: 'Collision with guardrail. Left front suspension damaged. Vehicle in drive-lock, flatbed with skates required.',
      isUrgent: true,
      urgencyReason: 'HIGHWAY SHOULDER HAZARD · CHP DISPATCHED',
      equipmentRequirements: const [
        'Flatbed Carrier',
        'GoJaks / Wheel Skates',
        'Snatch Block Winch',
        'High-Vis Road Flares'
      ],
    ),
    TowJob(
      id: 'TOW-8824',
      serviceTitle: 'Luxury Vehicle Transport',
      requestType: 'Vehicle Transport',
      vehicleName: 'BMW X5 xDrive40i',
      vehicleYear: '2022',
      vehicleMake: 'BMW',
      vehicleModel: 'X5',
      vehicleCategory: 'Luxury Mid-Size SUV',
      licensePlate: '9BMX204',
      vehicleImage: 'assets/vehicles/bmw-x5.png',
      pickupAddress: '450 Sutter St, Union Square, San Francisco',
      dropAddress: 'Pacific European Auto Werks, 880 Bryant St',
      pickupLat: 37.7895,
      pickupLng: -122.4082,
      dropLat: 37.7745,
      dropLng: -122.4040,
      distanceToPickup: '2.1 mi',
      pickupEta: '8 min',
      tripDuration: '32 min',
      customerName: 'David Miller',
      customerPhone: '+1 (555) 782-1200',
      customerRating: 4.88,
      totalCost: '\$155.00',
      estimatedPayout: 155.00,
      basePayout: 75.00,
      mileagePayout: 50.00,
      hazardFee: 0.00,
      specialEquipmentFee: 30.00,
      etaOrDuration: '8 min ETA (2.1 mi)',
      status: JobStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
      notes: 'Transmission fault light on. Gearbox stuck in Park. Manual release tool required for flatbed loading.',
      isUrgent: false,
      urgencyReason: 'Parking Garage Ramp',
      equipmentRequirements: const [
        'Flatbed Carrier',
        'BMW Neutral Lever Tool',
        'Soft Non-Marring Wheel Straps',
        'Low-Clearance Winch'
      ],
    ),
    TowJob(
      id: 'TOW-7751',
      serviceTitle: 'Highway Flat Tire Assistance',
      requestType: 'Flat Tire',
      vehicleName: 'Ford F-150 SuperCrew 4x4',
      vehicleYear: '2021',
      vehicleMake: 'Ford',
      vehicleModel: 'F-150',
      vehicleCategory: 'Full-Size Pickup Truck',
      licensePlate: '8TRK612',
      vehicleImage: 'assets/vehicles/ford-f150.png',
      pickupAddress: 'I-80 Westbound @ Fremont St Ramp, San Francisco',
      dropAddress: 'Big O Tires & Alignment, 1200 4th St',
      pickupLat: 37.7880,
      pickupLng: -122.3950,
      dropLat: 37.7710,
      dropLng: -122.3910,
      distanceToPickup: '2.8 mi',
      pickupEta: '9 min',
      tripDuration: '22 min',
      customerName: 'Robert Vance',
      customerPhone: '+1 (555) 304-9811',
      customerRating: 4.92,
      totalCost: '\$135.00',
      estimatedPayout: 135.00,
      basePayout: 70.00,
      mileagePayout: 35.00,
      hazardFee: 20.00,
      specialEquipmentFee: 10.00,
      etaOrDuration: '9 min ETA (2.8 mi)',
      status: JobStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
      notes: 'Right rear tire shredded. Spare is underneath truck bed with rusty hoist mechanism. May require flatbed if hoist fails.',
      isUrgent: true,
      urgencyReason: 'BUSY BRIDGE APPROACH · NARROW SHOULDER',
      equipmentRequirements: const [
        '4-Ton Hydraulic Jack',
        'Heavy Duty Impact Gun',
        'Spare Hoist Key Kit',
        'Traffic Safety Cones'
      ],
    ),
    TowJob(
      id: 'TOW-6632',
      serviceTitle: 'Dead Battery Fast Jumpstart',
      requestType: 'Dead Battery',
      vehicleName: 'Audi A6 Premium Plus',
      vehicleYear: '2024',
      vehicleMake: 'Audi',
      vehicleModel: 'A6',
      vehicleCategory: 'Executive Sedan',
      licensePlate: 'AUD-8831',
      vehicleImage: 'assets/vehicles/audi_test.png',
      pickupAddress: '555 California St (Garage P2), Financial District',
      dropAddress: 'On-Site Boost / Battery Diagnostic',
      pickupLat: 37.7928,
      pickupLng: -122.4042,
      dropLat: 37.7928,
      dropLng: -122.4042,
      distanceToPickup: '1.1 mi',
      pickupEta: '4 min',
      tripDuration: '14 min',
      customerName: 'Elena Rostova',
      customerPhone: '+1 (555) 219-7456',
      customerRating: 5.0,
      totalCost: '\$95.00',
      estimatedPayout: 95.00,
      basePayout: 65.00,
      mileagePayout: 15.00,
      hazardFee: 0.00,
      specialEquipmentFee: 15.00,
      etaOrDuration: '4 min ETA (1.1 mi)',
      status: JobStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 9)),
      notes: 'Parked in underground garage Level P2 (clearance 6ft 9in). 12V AGM auxiliary system discharged. Lights flashing dimly.',
      isUrgent: false,
      urgencyReason: 'Garage Stall P2-44',
      equipmentRequirements: const [
        '2500A Commercial Jump Starter',
        'Digital Battery & Alternator Analyzer',
        'Low-Clearance Utility Unit'
      ],
    ),
    TowJob(
      id: 'TOW-5510',
      serviceTitle: 'Emergency Lockout Assistance',
      requestType: 'Lockout',
      vehicleName: 'Hyundai Tucson Limited',
      vehicleYear: '2022',
      vehicleMake: 'Hyundai',
      vehicleModel: 'Tucson',
      vehicleCategory: 'Compact Crossover',
      licensePlate: 'HYN-5109',
      vehicleImage: 'assets/vehicles/hyundai_test.png',
      pickupAddress: 'Stonestown Galleria, 3251 20th Ave, SF',
      dropAddress: 'On-Site Lockout Service',
      pickupLat: 37.7285,
      pickupLng: -122.4760,
      dropLat: 37.7285,
      dropLng: -122.4760,
      distanceToPickup: '3.6 mi',
      pickupEta: '12 min',
      tripDuration: '18 min',
      customerName: 'Marcus Bennett',
      customerPhone: '+1 (555) 890-3321',
      customerRating: 4.82,
      totalCost: '\$85.00',
      estimatedPayout: 85.00,
      basePayout: 60.00,
      mileagePayout: 25.00,
      hazardFee: 0.00,
      specialEquipmentFee: 0.00,
      etaOrDuration: '12 min ETA (3.6 mi)',
      status: JobStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(minutes: 11)),
      notes: 'Key fob locked in center console cup holder. Engine is off. Customer has photo ID matching registration.',
      isUrgent: false,
      urgencyReason: 'Shopping Center Parking Area D',
      equipmentRequirements: const [
        'Long Reach In-Car Tool',
        'Dual Air Jack Wedges',
        'Non-Marring Window Shim'
      ],
    ),
  ];
}
