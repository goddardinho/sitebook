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

      // Search for campgrounds near user
      final response = await _apiService.getFacilities(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: radiusInMiles,
        limit: limit,
        activity: 'CAMPING', // Filter for camping facilities
      );

      _logger.i('Found ${response.data.length} campgrounds from API');

      // Convert Recreation.gov facilities to our Campground model
      final campgrounds = response.data
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
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.w('Location permissions denied by user');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.e('Location permissions permanently denied');
        return null;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location services are disabled');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      _logger.e('Error getting current position', error: e);
      return null;
    }
  }

  /// Convert Recreation.gov facility to our Campground model
  Campground? _convertFacilityToCampground(
    RecreationGovFacility facility,
    Position userPosition,
  ) {
    try {
      // Skip if no coordinates
      if (facility.facilityLatitude == null ||
          facility.facilityLongitude == null) {
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
      _logger.e('Error converting facility ${facility.facilityId}', error: e);
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

  /// Extract images from Recreation.gov facility data
  List<String> _extractImages(RecreationGovFacility facility) {
    // For now, use placeholder images similar to demo
    // Recreation.gov API may provide media URLs that we can parse
    return [
      'https://picsum.photos/400/240?random=${facility.facilityId.hashCode.abs()}',
      'https://picsum.photos/400/240?random=${(facility.facilityId.hashCode + 1).abs()}',
    ];
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
