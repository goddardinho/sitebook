import '../models/campground.dart';

/// Abstract repository interface for campground data access
///
/// This interface defines the contract for accessing campground data
/// from various sources (APIs, local database, cache).
abstract class CampgroundRepository {
  /// Get all campgrounds from all sources
  Future<List<Campground>> getAllCampgrounds();

  /// Get campgrounds by state
  Future<List<Campground>> getCampgroundsByState(String stateCode);

  /// Search campgrounds by location
  Future<List<Campground>> searchNearby({
    required double latitude,
    required double longitude,
    required double radiusMiles,
    String? stateFilter,
  });

  /// Get campground by ID
  Future<Campground?> getCampgroundById(String id);

  /// Search campgrounds by text query
  Future<List<Campground>> searchByQuery(String query);

  /// Check availability for a campground
  Future<Map<String, bool>> checkAvailability({
    required String campgroundId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get monitored campgrounds
  Future<List<Campground>> getMonitoredCampgrounds();

  /// Update campground monitoring status
  Future<void> updateMonitoringStatus(String campgroundId, bool isMonitored);

  /// Save campground to local storage
  Future<void> saveCampground(Campground campground);

  /// Save multiple campgrounds to local storage
  Future<void> saveCampgrounds(List<Campground> campgrounds);

  /// Delete campground from local storage
  Future<void> deleteCampground(String campgroundId);

  /// Clear all cached campgrounds
  Future<void> clearCache();

  /// Refresh data from APIs
  Future<void> refresh();

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime();
}
