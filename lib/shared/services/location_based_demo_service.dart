import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import '../models/campground.dart';
import '../../demo/demo_data_provider.dart';

/// UAT-friendly service that tests location services with reliable demo data
/// This allows us to verify location functionality without API dependencies
class LocationBasedDemoService {
  final Logger _logger = Logger();

  /// Get campgrounds with real location services but demo data
  Future<List<Campground>> getCampgroundsNearUser({
    double radiusInMiles = 50.0,
    int limit = 10,
  }) async {
    try {
      _logger.i('🎯 UAT: Starting location-based campground discovery...');

      // Test real location services first
      final position = await _getCurrentPosition();
      if (position == null) {
        _logger.w('⚠️ UAT: Location services unavailable, using demo data');
        return DemoDataProvider.getAllCampgrounds();
      }

      _logger.i(
        '✅ UAT: User location obtained: ${position.latitude}, ${position.longitude}',
      );

      // For UAT: Use demo campgrounds but sort them by distance from user
      final demoCampgrounds = DemoDataProvider.getAllCampgrounds();

      // Calculate distances and sort by proximity
      final campgroundsWithDistance = demoCampgrounds.map((campground) {
        final distance = _calculateDistance(
          position.latitude,
          position.longitude,
          campground.latitude,
          campground.longitude,
        );
        return {'campground': campground, 'distance': distance};
      }).toList();

      campgroundsWithDistance.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );

      final sortedCampgrounds = campgroundsWithDistance
          .map((item) => item['campground'] as Campground)
          .take(limit)
          .toList();

      _logger.i(
        '🎯 UAT: Returning ${sortedCampgrounds.length} campgrounds sorted by distance',
      );
      _logger.i('➡️ UAT: Closest campground: ${sortedCampgrounds.first.name}');

      return sortedCampgrounds;
    } catch (e) {
      _logger.e('❌ UAT: Error in location-based search', error: e);
      return DemoDataProvider.getAllCampgrounds();
    }
  }

  /// Test location permissions and services
  Future<Position?> _getCurrentPosition() async {
    try {
      _logger.i('📍 UAT: Checking location permissions...');

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      _logger.i('📍 UAT: Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        _logger.i('📍 UAT: Requesting location permission...');
        permission = await Geolocator.requestPermission();
        _logger.i('📍 UAT: Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          _logger.w('⚠️ UAT: Location permissions denied by user');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.e('❌ UAT: Location permissions permanently denied');
        return null;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _logger.i('📍 UAT: Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        _logger.w('⚠️ UAT: Location services are disabled on device');
        return null;
      }

      _logger.i('📍 UAT: Getting current position...');
      // Get current position with extended timeout for testing
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      _logger.i('✅ UAT: Position obtained successfully!');
      _logger.i(
        '📍 UAT: Coordinates: ${position.latitude}, ${position.longitude}',
      );
      _logger.i('📍 UAT: Accuracy: ${position.accuracy}m');

      return position;
    } catch (e) {
      _logger.e('❌ UAT: Error getting current position', error: e);
      return null;
    }
  }

  /// Calculate distance between two points in miles
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) *
        0.000621371; // Convert meters to miles
  }

  /// Test method for UAT verification
  Future<Map<String, dynamic>> getLocationTestResults() async {
    final results = <String, dynamic>{};

    try {
      // Test permission status
      final permission = await Geolocator.checkPermission();
      results['permission_status'] = permission.toString();

      // Test service availability
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      results['service_enabled'] = serviceEnabled;

      // Test position retrieval
      final position = await _getCurrentPosition();
      results['position_available'] = position != null;
      if (position != null) {
        results['latitude'] = position.latitude;
        results['longitude'] = position.longitude;
        results['accuracy'] = position.accuracy;
      }

      _logger.i('🎯 UAT Location Test Results: $results');
      return results;
    } catch (e) {
      _logger.e('❌ UAT: Error in location test', error: e);
      results['error'] = e.toString();
      return results;
    }
  }
}
