import 'package:logger/logger.dart';
import '../models/campsite.dart';
import '../models/campsite_monitoring_settings.dart';
import 'recreation_gov_api_service.dart';

/// Enhanced API service for campsite-level data and availability monitoring
class CampsiteApiService {
  final RecreationGovApiService _recreationGovApi;
  final Logger _logger = Logger();

  CampsiteApiService({RecreationGovApiService? recreationGovApi})
    : _recreationGovApi = recreationGovApi ?? RecreationGovApiService.create();

  /// Get all campsites for a campground with detailed information
  Future<List<Campsite>> getCampsitesByCampground(String campgroundId) async {
    try {
      _logger.i('Fetching campsites for campground: $campgroundId');

      final response = await _recreationGovApi.getCampsites(campgroundId);
      final campsites = <Campsite>[];

      for (final recGovCampsite in response.data) {
        // Get additional details for each campsite
        final campsite = await _enrichCampsiteData(
          campgroundId,
          recGovCampsite,
        );
        if (campsite != null) {
          campsites.add(campsite);
        }
      }

      _logger.i('Retrieved ${campsites.length} campsites for $campgroundId');
      return campsites;
    } catch (e) {
      _logger.e(
        'Error fetching campsites for campground $campgroundId',
        error: e,
      );
      return [];
    }
  }

  /// Get detailed campsite information with availability and pricing
  Future<Campsite?> getCampsiteDetails(
    String campgroundId,
    String campsiteId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.d('Fetching details for campsite $campsiteId in $campgroundId');

      // Get basic campsite data
      final campsitesResponse = await _recreationGovApi.getCampsites(
        campgroundId,
      );
      final recGovCampsite = campsitesResponse.data
          .where((site) => site.campsiteId == campsiteId)
          .firstOrNull;

      if (recGovCampsite == null) {
        _logger.w('Campsite $campsiteId not found in $campgroundId');
        return null;
      }

      // Enrich with availability and pricing data
      final enrichedCampsite = await _enrichCampsiteData(
        campgroundId,
        recGovCampsite,
        startDate: startDate,
        endDate: endDate,
      );

      return enrichedCampsite;
    } catch (e) {
      _logger.e('Error fetching campsite details', error: e);
      return null;
    }
  }

  /// Check campsite availability for specific dates
  Future<CampsiteAvailabilityData> checkCampsiteAvailability(
    String campgroundId,
    String campsiteId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      _logger.d(
        'Checking availability for campsite $campsiteId from ${startDate.toIso8601String().substring(0, 10)} to ${endDate.toIso8601String().substring(0, 10)}',
      );

      final response = await _recreationGovApi.getCampsiteAvailability(
        campgroundId,
        campsiteId,
        startDate.toIso8601String().substring(0, 10), // YYYY-MM-DD
        endDate.toIso8601String().substring(0, 10),
      );

      return _parseAvailabilityResponse(response, startDate, endDate);
    } catch (e) {
      _logger.e('Error checking campsite availability', error: e);
      return CampsiteAvailabilityData(
        isAvailable: false,
        availableDates: [],
        ratePricing: {},
        lastChecked: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Monitor campsites based on specific criteria
  Future<List<CampsiteAvailabilityData>> monitorCampsitesByCriteria(
    String campgroundId,
    CampsiteMonitoringSettings settings,
  ) async {
    try {
      _logger.i(
        'Monitoring campsites for campground $campgroundId with criteria: ${settings.sitePreference}',
      );

      // Get all campsites for the campground
      final allCampsites = await getCampsitesByCampground(campgroundId);
      final monitoredCampsites = <CampsiteAvailabilityData>[];

      for (final campsite in allCampsites) {
        // Check if campsite matches monitoring criteria
        if (_matchesCriteria(campsite, settings)) {
          final availability = await checkCampsiteAvailability(
            campgroundId,
            campsite.id,
            settings.startDate,
            settings.endDate,
          );

          // Only include if available and matches price criteria
          if (availability.isAvailable &&
              _meetsPriceCriteria(availability, settings)) {
            monitoredCampsites.add(
              availability.copyWith(campsiteInfo: campsite),
            );
          }
        }
      }

      _logger.i(
        'Found ${monitoredCampsites.length} matching available campsites',
      );
      return monitoredCampsites;
    } catch (e) {
      _logger.e('Error monitoring campsites', error: e);
      return [];
    }
  }

  /// Get alternative campsite suggestions within same campground
  Future<List<Campsite>> getAlternativeCampsites(
    String campgroundId,
    CampsiteMonitoringSettings settings, {
    int maxSuggestions = 5,
  }) async {
    try {
      final allCampsites = await getCampsitesByCampground(campgroundId);
      final alternatives = <Campsite>[];

      // Sort by preference: same type, accessibility match, price
      allCampsites.sort((a, b) {
        int scoreA = _calculateAlternativeScore(a, settings);
        int scoreB = _calculateAlternativeScore(b, settings);
        return scoreB.compareTo(scoreA); // Higher score first
      });

      for (final campsite in allCampsites.take(maxSuggestions)) {
        final availability = await checkCampsiteAvailability(
          campgroundId,
          campsite.id,
          settings.startDate,
          settings.endDate,
        );

        if (availability.isAvailable) {
          alternatives.add(
            campsite.copyWith(
              isAvailable: true,
              availableDates: availability.availableDates,
              ratePricing: availability.ratePricing,
              lastAvailabilityCheck: DateTime.now(),
            ),
          );
        }
      }

      return alternatives;
    } catch (e) {
      _logger.e('Error getting alternative campsites', error: e);
      return [];
    }
  }

  /// Generate direct reservation URL for a campsite
  String generateReservationUrl(
    String campgroundId,
    String campsiteId,
    DateTime startDate,
    DateTime endDate,
    int guestCount,
  ) {
    // Recreation.gov reservation URL format
    final baseUrl = 'https://www.recreation.gov/camping/campsites';
    final startDateStr = startDate.toIso8601String().substring(0, 10);
    final endDateStr = endDate.toIso8601String().substring(0, 10);

    return '$baseUrl/$campsiteId?'
        'facilityId=$campgroundId&'
        'arrivalDate=$startDateStr&'
        'departureDate=$endDateStr&'
        'partySize=$guestCount';
  }

  /// Enhanced campsite data with additional details
  Future<Campsite?> _enrichCampsiteData(
    String campgroundId,
    RecreationGovCampsite recGovCampsite, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Map<String, double> ratePricing = {};
      List<DateTime> availableDates = [];
      bool isAvailable = false;

      // Get availability and pricing if date range provided
      if (startDate != null && endDate != null) {
        final availabilityData = await checkCampsiteAvailability(
          campgroundId,
          recGovCampsite.campsiteId,
          startDate,
          endDate,
        );

        ratePricing = availabilityData.ratePricing;
        availableDates = availabilityData.availableDates;
        isAvailable = availabilityData.isAvailable;
      }

      // Generate reservation URL
      final reservationUrl = startDate != null && endDate != null
          ? generateReservationUrl(
              campgroundId,
              recGovCampsite.campsiteId,
              startDate,
              endDate,
              2,
            )
          : null;

      return Campsite(
        id: recGovCampsite.campsiteId,
        campgroundId: campgroundId,
        siteNumber: recGovCampsite.campsiteName,
        siteType: recGovCampsite.campsiteType ?? 'Standard',
        maxOccupancy: _estimateMaxOccupancy(recGovCampsite.campsiteType),
        accessibility: recGovCampsite.campsiteAccessible,
        amenities: _extractCampsiteAmenities(recGovCampsite),
        pricePerNight: _getAveragePrice(ratePricing),
        isAvailable: isAvailable,
        availableDates: availableDates,
        ratePricing: ratePricing,
        reservationUrl: reservationUrl,
        lastAvailabilityCheck: DateTime.now(),
        notes: 'Loop: ${recGovCampsite.campsiteLoop}',
      );
    } catch (e) {
      _logger.e(
        'Error enriching campsite data for ${recGovCampsite.campsiteId}',
        error: e,
      );
      return null;
    }
  }

  /// Parse Recreation.gov availability response
  CampsiteAvailabilityData _parseAvailabilityResponse(
    RecreationGovAvailabilityResponse response,
    DateTime startDate,
    DateTime endDate,
  ) {
    final availability = response.availability;
    final availableDates = <DateTime>[];
    final ratePricing = <String, double>{};

    // Parse availability data structure
    if (availability['availabilities'] != null) {
      final availabilities =
          availability['availabilities'] as Map<String, dynamic>;

      availabilities.forEach((dateStr, dayData) {
        try {
          final date = DateTime.parse(dateStr);
          if (date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              date.isBefore(endDate.add(const Duration(days: 1)))) {
            if (dayData is Map<String, dynamic>) {
              // Check availability status
              final status = dayData['status'] ?? '';
              if (status == 'Available' || status == 'Reservable') {
                availableDates.add(date);

                // Extract pricing if available
                final price = dayData['price']?.toDouble();
                if (price != null) {
                  ratePricing[dateStr] = price;
                }
              }
            }
          }
        } catch (e) {
          _logger.w('Error parsing availability for date $dateStr', error: e);
        }
      });
    }

    final isAvailable = availableDates.isNotEmpty;

    return CampsiteAvailabilityData(
      isAvailable: isAvailable,
      availableDates: availableDates,
      ratePricing: ratePricing,
      lastChecked: DateTime.now(),
    );
  }

  /// Check if campsite matches monitoring criteria
  bool _matchesCriteria(
    Campsite campsite,
    CampsiteMonitoringSettings settings,
  ) {
    switch (settings.sitePreference) {
      case SitePreference.specificSites:
        return settings.preferredSiteNumbers.contains(campsite.siteNumber);
      case SitePreference.siteType:
        return settings.preferredSiteTypes.contains(campsite.siteType);
      case SitePreference.accessibleOnly:
        return campsite.accessibility;
      case SitePreference.anyAvailable:
        return true;
    }
  }

  /// Check if availability meets price criteria
  bool _meetsPriceCriteria(
    CampsiteAvailabilityData availability,
    CampsiteMonitoringSettings settings,
  ) {
    if (settings.maxPricePerNight == null) return true;

    final maxPrice = availability.ratePricing.values.fold<double>(
      0,
      (max, price) => price > max ? price : max,
    );
    return maxPrice <= settings.maxPricePerNight!;
  }

  /// Calculate alternative score for campsite ranking
  int _calculateAlternativeScore(
    Campsite campsite,
    CampsiteMonitoringSettings settings,
  ) {
    int score = 0;

    // Prefer same site type
    if (settings.preferredSiteTypes.contains(campsite.siteType)) {
      score += 10;
    }

    // Accessibility match
    if (settings.requireAccessibility && campsite.accessibility) {
      score += 5;
    }

    // Price bonus
    if (settings.maxPricePerNight != null &&
        campsite.pricePerNight != null &&
        campsite.pricePerNight! <= settings.maxPricePerNight!) {
      score += 3;
    }

    return score;
  }

  /// Extract campsite amenities from Recreation.gov data
  List<String> _extractCampsiteAmenities(RecreationGovCampsite recGovCampsite) {
    final amenities = <String>[];

    if (recGovCampsite.campsiteAccessible) {
      amenities.add('Accessible');
    }

    if (recGovCampsite.campsiteType != null) {
      amenities.add(recGovCampsite.campsiteType!);
    }

    return amenities;
  }

  /// Estimate max occupancy based on site type
  int _estimateMaxOccupancy(String? siteType) {
    switch (siteType?.toLowerCase()) {
      case 'rv':
      case 'rv only':
        return 8;
      case 'tent':
      case 'tent only':
        return 6;
      case 'group':
        return 20;
      default:
        return 6; // Standard tent site default
    }
  }

  /// Get average price from rate pricing map
  double? _getAveragePrice(Map<String, double> ratePricing) {
    if (ratePricing.isEmpty) return null;

    final total = ratePricing.values.fold<double>(
      0,
      (sum, price) => sum + price,
    );
    return total / ratePricing.length;
  }
}

/// Campsite availability data structure
class CampsiteAvailabilityData {
  final bool isAvailable;
  final List<DateTime> availableDates;
  final Map<String, double> ratePricing;
  final DateTime lastChecked;
  final String? error;
  final Campsite? campsiteInfo;

  CampsiteAvailabilityData({
    required this.isAvailable,
    required this.availableDates,
    required this.ratePricing,
    required this.lastChecked,
    this.error,
    this.campsiteInfo,
  });

  CampsiteAvailabilityData copyWith({
    bool? isAvailable,
    List<DateTime>? availableDates,
    Map<String, double>? ratePricing,
    DateTime? lastChecked,
    String? error,
    Campsite? campsiteInfo,
  }) {
    return CampsiteAvailabilityData(
      isAvailable: isAvailable ?? this.isAvailable,
      availableDates: availableDates ?? this.availableDates,
      ratePricing: ratePricing ?? this.ratePricing,
      lastChecked: lastChecked ?? this.lastChecked,
      error: error ?? this.error,
      campsiteInfo: campsiteInfo ?? this.campsiteInfo,
    );
  }

  /// Get total cost for all available dates
  double get totalCost {
    return ratePricing.values.fold<double>(0, (sum, price) => sum + price);
  }

  /// Get average price per night
  double? get averagePricePerNight {
    if (ratePricing.isEmpty) return null;
    return totalCost / ratePricing.length;
  }

  /// Check if availability has changed since last check
  bool hasChanged(CampsiteAvailabilityData previous) {
    return isAvailable != previous.isAvailable ||
        availableDates.length != previous.availableDates.length ||
        totalCost != previous.totalCost;
  }

  @override
  String toString() {
    return 'CampsiteAvailabilityData(isAvailable: $isAvailable, '
        'dates: ${availableDates.length}, avgPrice: \$${averagePricePerNight?.toStringAsFixed(2)})';
  }
}
