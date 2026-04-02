import 'package:flutter/foundation.dart';

class ApiConfig {
  // Google Maps API Keys from environment variables
  static String get googleMapsApiKey {
    const String envKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (envKey.isNotEmpty) return envKey;

    // Fallback during development - never commit real keys!
    if (kDebugMode) {
      return 'DEMO_KEY_REPLACE_WITH_REAL_KEY'; // Safe placeholder
    }

    throw Exception(
      'Google Maps API key not provided! Use --dart-define GOOGLE_MAPS_API_KEY=your_key',
    );
  }

  // Recreation.gov API configuration
  static String get recreationGovApiKey {
    const String envKey = String.fromEnvironment(
      'RECREATION_GOV_API_KEY',
      defaultValue: 'YOUR_API_KEY_HERE',
    );
    return envKey;
  }

  // Base URLs
  static const String recreationGovBaseUrl =
      'https://ridb.recreation.gov/api/v1';
  static const String stateParkApiBaseUrl = 'https://api.parks.ca.gov/api/v1';
}
