class DriverProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String truckModel;
  final String licensePlate;
  final double rating;
  final int totalTows;
  final double todayEarnings;
  final bool isOnline;
  final bool isVerified;

  const DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.truckModel,
    required this.licensePlate,
    required this.rating,
    required this.totalTows,
    required this.todayEarnings,
    required this.isOnline,
    required this.isVerified,
  });

  DriverProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? truckModel,
    String? licensePlate,
    double? rating,
    int? totalTows,
    double? todayEarnings,
    bool? isOnline,
    bool? isVerified,
  }) {
    return DriverProfile(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      truckModel: truckModel ?? this.truckModel,
      licensePlate: licensePlate ?? this.licensePlate,
      rating: rating ?? this.rating,
      totalTows: totalTows ?? this.totalTows,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  static DriverProfile mockDriver = const DriverProfile(
    id: 'DRV-7701',
    name: 'Marcus Vance',
    phone: '+1 (555) 782-9901',
    email: 'marcus.vance@roacstowing.com',
    truckModel: '2024 Peterbilt 337 Flatbed Heavy',
    licensePlate: 'TOW-PRO-88',
    rating: 4.94,
    totalTows: 284,
    todayEarnings: 345.50,
    isOnline: true,
    isVerified: true,
  );
}
