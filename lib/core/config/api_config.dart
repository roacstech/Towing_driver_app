class ApiConfig {
  /// Live Production Dart Backend on Easypanel VPS
  static const String baseUrl = 'https://bec-api-towing-backend.3t5o2t.easypanel.host';

  static String get profileEndpoint => '$baseUrl/api/profile';
  static String get usersEndpoint => '$baseUrl/api/users';
  static String get vehiclesEndpoint => '$baseUrl/api/vehicles';
  static String get towsEndpoint => '$baseUrl/api/tows';
  static String get healthEndpoint => '$baseUrl/health';
}
