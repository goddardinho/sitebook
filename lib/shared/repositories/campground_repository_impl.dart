import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/campground.dart';
import '../services/recreation_gov_api_service.dart';
import '../services/state_park_api_service.dart';
import '../../core/storage/campground_database.dart';
import 'campground_repository.dart';

/// Concrete implementation of CampgroundRepository
/// 
/// This repository combines data from multiple sources:
/// - Recreation.gov API (federal campgrounds)
/// - State park APIs (state campgrounds)  
/// - Local SQLite database (offline storage and monitoring)
class CampgroundRepositoryImpl implements CampgroundRepository {
  final RecreationGovApiService _recreationGovApi;
  final StateParkApiService _stateParkApi;
  final CampgroundDatabase _database;
  final Logger _logger = Logger();

  static const String _lastSyncKey = 'campgrounds_last_sync';
  static const Duration _syncInterval = Duration(hours: 6); // Refresh every 6 hours

  CampgroundRepositoryImpl({
    RecreationGovApiService? recreationGovApi,
    StateParkApiService? stateParkApi,
    CampgroundDatabase? database,
  })  : _recreationGovApi = recreationGovApi ?? RecreationGovApiService.create(),
        _stateParkApi = stateParkApi ?? StateParkApiService.california(),
        _database = database ?? CampgroundDatabase();

  @override
  Future<List<Campground>> getAllCampgrounds() async {
    try {
      // Check if we need to sync with APIs
      final lastSync = await getLastSyncTime();
      final needsRefresh = lastSync == null || 
          DateTime.now().difference(lastSync) > _syncInterval;

      if (needsRefresh) {
        await refresh();
      }

      // Return cached campgrounds from database
      return await _database.getAllCampgrounds();
    } catch (e) {
      _logger.e('Error getting all campgrounds', error: e);
      // Fallback to database only
      return await _database.getAllCampgrounds();
    }
  }

  @override
  Future<List<Campground>> getCampgroundsByState(String stateCode) async {
    try {
      _logger.i('Getting campgrounds for state: $stateCode');

      // Get cached campgrounds first
      List<Campground> campgrounds = await _database.getCampgroundsByState(stateCode);

      // Check if we need to refresh data for this state
      final lastSync = await getLastSyncTime();
      final needsRefresh = lastSync == null || 
          DateTime.now().difference(lastSync) > _syncInterval;

      if (needsRefresh || campgrounds.isEmpty) {
        _logger.i('Refreshing campgrounds for $stateCode from APIs');
        await _refreshStateData(stateCode);
        campgrounds = await _database.getCampgroundsByState(stateCode);
      }

      return campgrounds;
    } catch (e) {
      _logger.e('Error getting campgrounds for state $stateCode', error: e);
      // Fallback to cached data
      return await _database.getCampgroundsByState(stateCode);
    }
  }

  @override
  Future<List<Campground>> searchNearby({
    required double latitude,
    required double longitude,
    required double radiusMiles,
    String? stateFilter,
  }) async {
    try {
      _logger.i('Searching campgrounds near ($latitude, $longitude) within $radiusMiles miles');

      // Try to get fresh data from APIs
      List<Campground> apiResults = [];

      try {
        // Search Recreation.gov API
        final response = await _recreationGovApi.getFacilities(
          latitude: latitude,
          longitude: longitude,
          radius: radiusMiles,
          state: stateFilter,
        );
        apiResults.addAll(response.data.map((facility) => facility.toCampground()));

        // Search state park API if no state filter or matches state API
        if (stateFilter == null || stateFilter == 'CA') {
          final stateResults = await _stateParkApi.searchByLocation(
            latitude: latitude,
            longitude: longitude,
            radiusMiles: radiusMiles,
            stateCode: stateFilter,
          );
          apiResults.addAll(stateResults);
        }

        // Save fresh results to database
        if (apiResults.isNotEmpty) {
          await _database.saveCampgrounds(apiResults);
        }
      } catch (e) {
        _logger.w('API search failed, using cached data', error: e);
      }

      // Fallback to database search if API fails or no results
      if (apiResults.isEmpty) {
        apiResults = await _database.searchNearby(
          latitude: latitude,
          longitude: longitude,
          radiusMiles: radiusMiles,
          stateFilter: stateFilter,
        );
      }

      return apiResults;
    } catch (e) {
      _logger.e('Error searching nearby campgrounds', error: e);
      return [];
    }
  }

  @override
  Future<Campground?> getCampgroundById(String id) async {
    try {
      // Try database first (faster)
      Campground? campground = await _database.getCampgroundById(id);

      if (campground != null) {
        return campground;
      }

      // Try Recreation.gov API
      try {
        final facility = await _recreationGovApi.getFacilityDetails(id);
        campground = facility.toCampground();
        await _database.saveCampground(campground);
        return campground;
      } catch (e) {
        _logger.w('Recreation.gov API call failed for ID $id', error: e);
      }

      // Try state park API
      try {
        campground = await _stateParkApi.getCampgroundDetails(id);
        if (campground != null) {
          await _database.saveCampground(campground);
          return campground;
        }
      } catch (e) {
        _logger.w('State park API call failed for ID $id', error: e);
      }

      return null;
    } catch (e) {
      _logger.e('Error getting campground by ID $id', error: e);
      return null;
    }
  }

  @override
  Future<List<Campground>> searchByQuery(String query) async {
    try {
      // Search local database first (fast)
      final localResults = await _database.searchByQuery(query);

      // If we have recent data and results, return them
      final lastSync = await getLastSyncTime();
      if (lastSync != null && 
          DateTime.now().difference(lastSync) < _syncInterval &&
          localResults.isNotEmpty) {
        return localResults;
      }

      // Otherwise, combine with API search if needed
      return localResults; // For now, rely on cached data for text search
    } catch (e) {
      _logger.e('Error searching by query: $query', error: e);
      return [];
    }
  }

  @override
  Future<Map<String, bool>> checkAvailability({
    required String campgroundId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _logger.i('Checking availability for $campgroundId from $startDate to $endDate');

      // Try Recreation.gov first
      try {
        // Get campsites for the facility
        final campsitesResponse = await _recreationGovApi.getCampsites(campgroundId);
        if (campsitesResponse.data.isNotEmpty) {
          final campsite = campsitesResponse.data.first;
          final availability = await _recreationGovApi.getCampsiteAvailability(
            campgroundId,
            campsite.campsiteId,
            _formatDate(startDate),
            _formatDate(endDate),
          );
          return _parseRecreationGovAvailability(availability.availability);
        }
      } catch (e) {
        _logger.w('Recreation.gov availability check failed', error: e);
      }

      // Try state park API
      try {
        return await _stateParkApi.checkAvailability(
          campgroundId: campgroundId,
          startDate: startDate,
          endDate: endDate,
        );
      } catch (e) {
        _logger.w('State park availability check failed', error: e);
      }

      // Return empty if all APIs fail
      return {};
    } catch (e) {
      _logger.e('Error checking availability for $campgroundId', error: e);
      return {};
    }
  }

  @override
  Future<List<Campground>> getMonitoredCampgrounds() async {
    try {
      return await _database.getMonitoredCampgrounds();
    } catch (e) {
      _logger.e('Error getting monitored campgrounds', error: e);
      return [];
    }
  }

  @override
  Future<void> updateMonitoringStatus(String campgroundId, bool isMonitored) async {
    try {
      await _database.updateMonitoringStatus(campgroundId, isMonitored);
      _logger.i('Updated monitoring status for $campgroundId: $isMonitored');
    } catch (e) {
      _logger.e('Error updating monitoring status for $campgroundId', error: e);
      rethrow;
    }
  }

  @override
  Future<void> saveCampground(Campground campground) async {
    try {
      await _database.saveCampground(campground);
    } catch (e) {
      _logger.e('Error saving campground ${campground.id}', error: e);
      rethrow;
    }
  }

  @override
  Future<void> saveCampgrounds(List<Campground> campgrounds) async {
    try {
      await _database.saveCampgrounds(campgrounds);
      _logger.i('Saved ${campgrounds.length} campgrounds to database');
    } catch (e) {
      _logger.e('Error saving campgrounds', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteCampground(String campgroundId) async {
    try {
      await _database.deleteCampground(campgroundId);
    } catch (e) {
      _logger.e('Error deleting campground $campgroundId', error: e);
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _database.clearCache();
      await _clearLastSyncTime();
      _logger.i('Cleared campground cache');
    } catch (e) {
      _logger.e('Error clearing cache', error: e);
      rethrow;
    }
  }

  @override
  Future<void> refresh() async {
    try {
      _logger.i('Refreshing campground data from APIs');

      // Popular states to preload
      const popularStates = ['CA', 'TX', 'FL', 'NY', 'WA', 'CO', 'UT', 'AZ'];

      for (final state in popularStates) {
        try {
          await _refreshStateData(state);
        } catch (e) {
          _logger.w('Failed to refresh data for state $state', error: e);
          // Continue with other states
        }
      }

      await _setLastSyncTime(DateTime.now());
      _logger.i('Campground data refresh completed');
    } catch (e) {
      _logger.e('Error during campground data refresh', error: e);
      rethrow;
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      _logger.e('Error getting last sync time', error: e);
      return null;
    }
  }

  // Private helper methods

  Future<void> _refreshStateData(String stateCode) async {
    List<Campground> stateCampgrounds = [];

    try {
      // Get Recreation.gov facilities for this state
      final response = await _recreationGovApi.getFacilities(
        state: stateCode,
        limit: 100,
      );
      stateCampgrounds.addAll(response.data.map((facility) => facility.toCampground()));
    } catch (e) {
      _logger.w('Failed to get Recreation.gov data for $stateCode', error: e);
    }

    try {
      // Get state park data
      final stateParks = await _stateParkApi.getCampgroundsByState(stateCode);
      stateCampgrounds.addAll(stateParks);
    } catch (e) {
      _logger.w('Failed to get state park data for $stateCode', error: e);
    }

    // Save to database if we got any data
    if (stateCampgrounds.isNotEmpty) {
      await _database.saveCampgrounds(stateCampgrounds);
      _logger.i('Saved ${stateCampgrounds.length} campgrounds for $stateCode');
    }
  }

  Future<void> _setLastSyncTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
    } catch (e) {
      _logger.e('Error setting last sync time', error: e);
    }
  }

  Future<void> _clearLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      _logger.e('Error clearing last sync time', error: e);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, bool> _parseRecreationGovAvailability(Map<String, dynamic> data) {
    // Recreation.gov availability format varies - this is a placeholder
    final Map<String, bool> availability = {};
    
    try {
      // Parse the specific Recreation.gov availability response format
      if (data.containsKey('campsites')) {
        final campsites = data['campsites'] as Map<String, dynamic>;
        for (final entry in campsites.entries) {
          final siteData = entry.value as Map<String, dynamic>;
          if (siteData.containsKey('availabilities')) {
            final availabilities = siteData['availabilities'] as Map<String, dynamic>;
            for (final availEntry in availabilities.entries) {
              availability[availEntry.key] = availEntry.value == 'Available';
            }
          }
        }
      }
    } catch (e) {
      _logger.w('Error parsing Recreation.gov availability', error: e);
    }
    
    return availability;
  }
}