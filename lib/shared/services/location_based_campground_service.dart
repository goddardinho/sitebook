import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import '../models/campground.dart';
import '../services/recreation_gov_api_service.dart';

/// Service for fetching campgrounds based on user's current location
class LocationBasedCampgroundService {
  final RecreationGovApiService _apiService;
  final Logger _logger = Logger();

  LocationBasedCampgroundService({RecreationGovApiService? apiService})
    : _apiService = apiService ?? RecreationGovApiService.create();

  /// Get campgrounds near user's current location
  Future<List<Campground>> getCampgroundsNearUser({
    double radiusInMiles = 50.0,
    int limit = 5,
  }) async {
    try {
      _logger.i('Starting location-based campground search...');

      // Get user's current location
      final position = await _getCurrentPosition();
      if (position == null) {
        _logger.w('Could not get user location, using fallback');
        return _getFallbackCampgrounds();
      }

      _logger.i('User location: ${position.latitude}, ${position.longitude}');

      // Search for campgrounds near user - removed activity filter to include National Parks
      final response = await _apiService.getFacilities(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: radiusInMiles,
        limit: limit,
        // No activity filter to include National Park campgrounds and other camping facilities
      );

      _logger.i('Found ${response.data.length} facilities from API');

      // Filter for camping-related facilities (includes National Parks)
      final campingFacilities = response.data.where((facility) {
        final name = facility.facilityName.toLowerCase();
        final description = facility.facilityDescription?.toLowerCase() ?? '';
        final activities = facility.activities
            .map((a) => a.activityName.toLowerCase())
            .toList();

        // Include facilities that are clearly camping-related
        return name.contains('camp') ||
            name.contains('rv') ||
            name.contains('trailer') ||
            description.contains('camp') ||
            description.contains('rv') ||
            description.contains('tent') ||
            activities.any(
              (activity) =>
                  activity.contains('camp') ||
                  activity.contains('rv') ||
                  activity.contains('tent') ||
                  activity.contains('overnight'),
            ) ||
            // Include National Park facilities and other common camping terms
            name.contains('national park') ||
            name.contains('state park') ||
            name.contains('recreation area') ||
            description.contains('national park') ||
            description.contains('state park') ||
            description.contains('recreation area') ||
            // Include facilities with generic camping-related activities
            activities
                .isNotEmpty; // Many camping facilities have various activities
      }).toList();

      _logger.i(
        'Filtered to ${campingFacilities.length} camping-related facilities',
      );

      // Convert Recreation.gov facilities to our Campground model
      final campgrounds = campingFacilities
          .map((facility) => _convertFacilityToCampground(facility, position))
          .where((campground) => campground != null)
          .cast<Campground>()
          .toList();

      // Sort by distance from user
      campgrounds.sort((a, b) {
        final distanceA = _calculateDistance(
          position.latitude,
          position.longitude,
          a.latitude,
          a.longitude,
        );
        final distanceB = _calculateDistance(
          position.latitude,
          position.longitude,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      _logger.i('Returning ${campgrounds.length} processed campgrounds');
      return campgrounds.take(limit).toList();
    } catch (e) {
      _logger.e('Error in location-based search', error: e);
      return _getFallbackCampgrounds();
    }
  }

  /// Get current user position with proper permissions
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
        // For web browsers, show instruction to user
        _logger.w(
          '💡 UAT: On web, please allow location access when prompted by browser',
        );
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
      _logger.e(
        '💡 UAT: If using web browser, ensure location permission is granted',
      );
      return null;
    }
  }

  /// Convert Recreation.gov facility to our Campground model
  Campground? _convertFacilityToCampground(
    RecreationGovFacility facility,
    Position userPosition,
  ) {
    try {
      // Skip if facility is missing essential data
      if (facility.facilityId.isEmpty) {
        _logger.w('Skipping facility with empty ID');
        return null;
      }

      // Skip if no coordinates
      if (facility.facilityLatitude == null ||
          facility.facilityLongitude == null) {
        _logger.w(
          'Skipping facility ${facility.facilityId} - missing coordinates',
        );
        return null;
      }

      // Use built-in conversion method then enhance with location data
      final campground = facility.toCampground();

      // Calculate distance from user (used for sorting)
      _calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        facility.facilityLatitude!,
        facility.facilityLongitude!,
      );

      // Enhanced campground with better images
      return campground.copyWith(
        imageUrls: _extractImages(facility),
        amenities: [
          ...campground.amenities,
          ...(_extractEnhancedAmenities(facility)),
        ],
      );
    } catch (e) {
      _logger.e(
        'Error converting facility ${facility.facilityId}: $e',
        error: e,
      );
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
    final distanceInMeters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return distanceInMeters * 0.000621371; // Convert to miles
  }

  /// Extract enhanced amenities from Recreation.gov facility data
  List<String> _extractEnhancedAmenities(RecreationGovFacility facility) {
    final amenities = <String>[];

    // Add enhanced amenities based on facility data analysis
    final name = facility.facilityName.toLowerCase();
    final desc = (facility.facilityDescription ?? '').toLowerCase();

    if (name.contains('rv') || desc.contains('rv')) {
      amenities.add('RV Sites');
    }

    if (name.contains('tent') || desc.contains('tent')) {
      amenities.add('Tent Sites');
    }

    if (name.contains('cabin') || desc.contains('cabin')) {
      amenities.add('Cabins');
    }

    if (desc.contains('shower')) {
      amenities.add('Showers');
    }
    if (desc.contains('wifi') || desc.contains('internet')) {
      amenities.add('Wi-Fi');
    }
    if (desc.contains('store') || desc.contains('shop')) {
      amenities.add('Camp Store');
    }
    if (desc.contains('beach') || desc.contains('lake')) {
      amenities.add('Beach Access');
    }

    return amenities;
  }

  /// Extract images from Recreation.gov facility data with consistency
  List<String> _extractImages(RecreationGovFacility facility) {
    // Let the facility's toCampground method handle image extraction
    // so we get consistent, cleaned images across the app
    if (facility.facilityId.isNotEmpty) {
      final seed1 = facility.facilityId.hashCode.abs() % 1000;
      final seed2 =
          (facility.facilityId.hashCode + facility.facilityName.hashCode)
              .abs() %
          1000;

      return [
        'https://picsum.photos/seed/$seed1/400/240',
        'https://picsum.photos/seed/$seed2/400/240',
      ];
    }
    return [];
  }

  /// Fallback campgrounds if location fails or API is unavailable
  List<Campground> _getFallbackCampgrounds() {
    _logger.i('Using fallback campgrounds (demo data)');

    // Return a few generic campgrounds as fallback
    return [
      const Campground(
        id: 'fallback_1',
        name: 'Local Area Campground',
        description:
            'Unable to determine your location. Please enable location services for personalized results.',
        latitude: 37.7749,
        longitude: -122.4194,
        state: '',
        amenities: ['Restrooms', 'Picnic Tables', 'Fire Rings'],
        activities: ['Camping', 'Hiking'],
        imageUrls: ['https://picsum.photos/400/240?random=fallback1'],
        isMonitored: false,
      ),
    ];
  }
}
