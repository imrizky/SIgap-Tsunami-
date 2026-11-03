/// Override per platform with --dart-define=API_BASE_URL=... .
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );
  static const timeout = Duration(seconds: 15);
}
