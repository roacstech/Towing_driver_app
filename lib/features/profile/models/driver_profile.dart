
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
  final int monthsActive;

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
    this.monthsActive = 5,
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
    int? monthsActive,
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
      monthsActive: monthsActive ?? this.monthsActive,
    );
  }

  static DriverProfile mockDriver = const DriverProfile(
    id: 'DRV-7701',
    name: 'YOGESHWARAN M',
    phone: '+91 98765 43210',
    email: 'yogeshwaran.m@roacstowing.com',
    truckModel: '2024 Peterbilt 337 Flatbed Heavy',
    licensePlate: 'TOW-PRO-88',
    rating: 4.9,
    totalTows: 546,
    todayEarnings: 345.50,
    isOnline: true,
    isVerified: true,
    monthsActive: 5,
  );
}
