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
        return 'Arrived at Vehicle';
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
        return const Color(0xFFFF521B);
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
  final String vehicleName;
  final String licensePlate;
  final String pickupAddress;
  final String dropAddress;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final String customerName;
  final String customerPhone;
  final String totalCost;
  final String etaOrDuration;
  final JobStatus status;
  final DateTime createdAt;
  final String notes;

  const TowJob({
    required this.id,
    required this.serviceTitle,
    required this.vehicleName,
    required this.licensePlate,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    required this.customerName,
    required this.customerPhone,
    required this.totalCost,
    required this.etaOrDuration,
    required this.status,
    required this.createdAt,
    this.notes = 'Standard roadside recovery',
  });

  TowJob copyWith({
    JobStatus? status,
    String? etaOrDuration,
    String? notes,
  }) {
    return TowJob(
      id: id,
      serviceTitle: serviceTitle,
      vehicleName: vehicleName,
      licensePlate: licensePlate,
      pickupAddress: pickupAddress,
      dropAddress: dropAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropLat: dropLat,
      dropLng: dropLng,
      customerName: customerName,
      customerPhone: customerPhone,
      totalCost: totalCost,
      etaOrDuration: etaOrDuration ?? this.etaOrDuration,
      status: status ?? this.status,
      createdAt: createdAt,
      notes: notes ?? this.notes,
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

    return TowJob(
      id: json['id']?.toString() ?? 'TOW-${DateTime.now().millisecondsSinceEpoch % 10000}',
      serviceTitle: json['serviceTitle'] ?? json['service_title'] ?? 'Emergency Flatbed Tow',
      vehicleName: json['vehicleName'] ?? json['vehicle_name'] ?? 'Passenger Vehicle',
      licensePlate: json['licensePlate'] ?? json['license_plate'] ?? 'TBD',
      pickupAddress: json['pickupAddress'] ?? json['pickup_address'] ?? 'Customer Location',
      dropAddress: json['dropAddress'] ?? json['drop_address'] ?? 'Designated Repair Facility',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? 37.7749,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? -122.4194,
      dropLat: (json['drop_lat'] as num?)?.toDouble() ?? 37.7849,
      dropLng: (json['drop_lng'] as num?)?.toDouble() ?? -122.4094,
      customerName: json['customer_name'] ?? json['driverName'] ?? 'John Doe',
      customerPhone: json['customer_phone'] ?? '+1 (555) 923-4411',
      totalCost: json['totalCost'] ?? json['total_cost'] ?? '\$120.00',
      etaOrDuration: json['etaOrDuration'] ?? '8 mins (3.1 mi)',
      status: parseStatus(json['status']),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] ?? 'Vehicle has front axle lock. Flatbed required.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_title': serviceTitle,
      'vehicle_name': vehicleName,
      'license_plate': licensePlate,
      'pickup_address': pickupAddress,
      'drop_address': dropAddress,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'drop_lat': dropLat,
      'drop_lng': dropLng,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_cost': totalCost,
      'etaOrDuration': etaOrDuration,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
    };
  }
}
