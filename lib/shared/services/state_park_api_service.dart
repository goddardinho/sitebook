import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/campground.dart';

/// Generic State Park API Service
/// 
/// This service provides a flexible foundation for integrating with various
/// state park reservation systems. Each state may have different API endpoints
/// and data structures, so this class can be extended or configured.
class StateParkApiService {
  final Dio _dio;
  final Logger _logger = Logger();
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  StateParkApiService({
    required this.baseUrl,
    this.defaultHeaders = const {},
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...defaultHeaders,
          },
        ));

  /// California State Parks API implementation
  static StateParkApiService california() {
    return StateParkApiService(
      baseUrl: 'https://www.reserveamerica.com/webservice/search/search',
      defaultHeaders: {
        'User-Agent': 'SiteBook/1.0',
      },
    );
  }

  /// Texas State Parks API implementation  
  static StateParkApiService texas() {
    return StateParkApiService(
      baseUrl: 'https://texasstateparks.reserveamerica.com/webservice',
      defaultHeaders: {
        'User-Agent': 'SiteBook/1.0',
      },
    );
  }

  /// Generic method to fetch campgrounds by state
  Future<List<Campground>> getCampgroundsByState(String stateCode) async {
    try {
      _logger.i('Fetching campgrounds for state: $stateCode');
      
      // This is a template implementation
      // Each state API will need specific endpoint and parameter mapping
      final response = await _dio.get('/facilities', queryParameters: {
        'state': stateCode,
        'facilityType': 'camping',
      });

      if (response.statusCode == 200) {
        return _parseCampgroundsResponse(response.data, stateCode);
      } else {
        throw Exception('Failed to fetch campgrounds: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      _logger.e('State park API error for $stateCode', error: e);
      throw _handleApiError(e);
    }
  }

  /// Search campgrounds by location
  Future<List<Campground>> searchByLocation({
    required double latitude,
    required double longitude,
    required double radiusMiles,
    String? stateCode,
  }) async {
    try {
      _logger.i('Searching campgrounds near ($latitude, $longitude) within $radiusMiles miles');

      final response = await _dio.get('/search', queryParameters: {
        'lat': latitude,
        'lng': longitude,
        'radius': radiusMiles,
        'type': 'camping',
        'state': ?stateCode,
      });

      if (response.statusCode == 200) {
        return _parseCampgroundsResponse(response.data, stateCode ?? 'Unknown');
      } else {
        throw Exception('Failed to search campgrounds: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      _logger.e('State park search API error', error: e);
      throw _handleApiError(e);
    }
  }

  /// Get detailed campground information
  Future<Campground?> getCampgroundDetails(String campgroundId) async {
    try {
      _logger.i('Fetching details for campground: $campgroundId');

      final response = await _dio.get('/facility/$campgroundId');

      if (response.statusCode == 200) {
        return _parseCampgroundDetails(response.data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch campground details: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      _logger.e('State park details API error for $campgroundId', error: e);
      throw _handleApiError(e);
    }
  }

  /// Check availability for a specific date range
  Future<Map<String, bool>> checkAvailability({
    required String campgroundId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _logger.i('Checking availability for $campgroundId from $startDate to $endDate');

      final response = await _dio.get('/availability/$campgroundId', queryParameters: {
        'start_date': _formatDate(startDate),
        'end_date': _formatDate(endDate),
      });

      if (response.statusCode == 200) {
        return _parseAvailabilityResponse(response.data);
      } else {
        throw Exception('Failed to check availability: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      _logger.e('State park availability API error for $campgroundId', error: e);
      throw _handleApiError(e);
    }
  }

  /// Parse campgrounds response - template implementation
  List<Campground> _parseCampgroundsResponse(dynamic data, String defaultState) {
    try {
      // This is a generic parser - each state API will need specific parsing logic
      if (data is Map<String, dynamic> && data.containsKey('facilities')) {
        final facilities = data['facilities'] as List;
        return facilities.map((facility) => _parseStateParkFacility(facility, defaultState)).toList();
      } else if (data is List) {
        return data.map((facility) => _parseStateParkFacility(facility, defaultState)).toList();
      } else {
        _logger.w('Unexpected campgrounds response format');
        return [];
      }
    } catch (e) {
      _logger.e('Error parsing campgrounds response', error: e);
      return [];
    }
  }

  /// Parse individual campground facility
  Campground _parseStateParkFacility(dynamic facility, String defaultState) {
    final facilityMap = facility as Map<String, dynamic>;
    
    return Campground(
      id: facilityMap['id']?.toString() ?? '',
      name: facilityMap['name'] ?? 'Unknown Campground',
      description: facilityMap['description'] ?? '',
      latitude: _parseDouble(facilityMap['latitude']),
      longitude: _parseDouble(facilityMap['longitude']),
      state: facilityMap['state'] ?? defaultState,
      parkName: facilityMap['parkName'] ?? facilityMap['agency'],
      reservationUrl: facilityMap['reservationUrl'] ?? facilityMap['bookingUrl'],
      phoneNumber: facilityMap['phone'] ?? facilityMap['phoneNumber'],
      email: facilityMap['email'],
      amenities: _parseStringList(facilityMap['amenities']),
      activities: _parseStringList(facilityMap['activities']),
      imageUrls: _parseStringList(facilityMap['images']),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Parse campground details
  Campground? _parseCampgroundDetails(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        return _parseStateParkFacility(data, data['state'] ?? 'Unknown');
      }
      return null;
    } catch (e) {
      _logger.e('Error parsing campground details', error: e);
      return null;
    }
  }

  /// Parse availability response
  Map<String, bool> _parseAvailabilityResponse(dynamic data) {
    try {
      final Map<String, bool> availability = {};
      
      if (data is Map<String, dynamic> && data.containsKey('availability')) {
        final availData = data['availability'] as Map<String, dynamic>;
        for (final entry in availData.entries) {
          availability[entry.key] = entry.value == true || entry.value == 'available';
        }
      }
      
      return availability;
    } catch (e) {
      _logger.e('Error parsing availability response', error: e);
      return {};
    }
  }

  // Helper methods
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    } else if (value is String) {
      // Handle comma-separated strings
      return value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Exception _handleApiError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Request timeout. Please check your internet connection.');
      case DioExceptionType.connectionError:
        return Exception('Connection error. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        return Exception('Server error ($statusCode). Please try again later.');
      default:
        return Exception('An unexpected error occurred. Please try again.');
    }
  }
}

/// State-specific implementations can extend this base class
class CaliforniaStateParksService extends StateParkApiService {
  CaliforniaStateParksService() : super(
    baseUrl: 'https://public-api.reservecalifornia.com/api',
    defaultHeaders: {
      'User-Agent': 'SiteBook-California/1.0',
    },
  );

  /// Get California-specific campgrounds
  Future<List<Campground>> getCaliforniaCampgrounds() async {
    return await getCampgroundsByState('CA');
  }
}

class TexasStateParksService extends StateParkApiService {
  TexasStateParksService() : super(
    baseUrl: 'https://texasstateparks.reserveamerica.com/api',
    defaultHeaders: {
      'User-Agent': 'SiteBook-Texas/1.0',
    },
  );

  /// Get Texas-specific campgrounds
  Future<List<Campground>> getTexasCampgrounds() async {
    return await getCampgroundsByState('TX');
  }
}