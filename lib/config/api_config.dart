// Example: lib/config/api_config.dart
class ApiConfig {
  static const bool isDevelopment = bool.fromEnvironment('DEVELOPMENT', defaultValue: true);
  
  // This should be loaded from environment or secure storage
  static String get googleMapsApiKey {
    if (isDevelopment) {
      return const String.fromEnvironment('GOOGLE_MAPS_DEV_API_KEY', 
             defaultValue: 'your-development-api-key-here');
    } else {
      return const String.fromEnvironment('GOOGLE_MAPS_PROD_API_KEY',
             defaultValue: 'your-production-api-key-here');
    }
  }
}