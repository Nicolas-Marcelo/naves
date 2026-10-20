abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'NAVESCENCE_API_URL',
    defaultValue: 'http://192.168.0.100:3000',
  );

  static const navigationConfig = '$baseUrl/api/navigation/config';
}
