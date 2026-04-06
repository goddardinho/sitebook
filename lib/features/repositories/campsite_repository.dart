import '../../shared/models/campsite.dart';
import '../../shared/models/campsite_monitoring_settings.dart';
import '../../shared/services/campsite_api_service.dart';

/// Repository interface for campsite data access
abstract class CampsiteRepository {
  // CAMPSITE OPERATIONS

  /// Get all campsites for a campground
  Future<List<Campsite>> getCampsitesByCampground(String campgroundId);

  /// Get available campsites with filters
  Future<List<Campsite>> getAvailableCampsites(
    String campgroundId, {
    DateTime? startDate,
    DateTime? endDate,
    String? siteType,
    bool? accessibility,
    double? maxPrice,
  });

  /// Get detailed campsite information
  Future<Campsite?> getCampsiteDetails(
    String campgroundId,
    String campsiteId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Save campsite to local storage
  Future<void> saveCampsite(Campsite campsite);

  /// Save multiple campsites to local storage
  Future<void> saveCampsites(List<Campsite> campsites);

  /// Update campsite monitoring status
  Future<void> updateCampsiteMonitoring(String campsiteId, bool isMonitored);

  /// Get monitored campsites
  Future<List<Campsite>> getMonitoredCampsites();

  // MONITORING SETTINGS OPERATIONS

  /// Save monitoring settings
  Future<void> saveMonitoringSettings(CampsiteMonitoringSettings settings);

  /// Update monitoring settings
  Future<void> updateMonitoringSettings(CampsiteMonitoringSettings settings);

  /// Get all monitoring settings
  Future<List<CampsiteMonitoringSettings>> getAllMonitoringSettings();

  /// Get monitoring settings for a campground
  Future<List<CampsiteMonitoringSettings>> getMonitoringSettingsByCampground(
    String campgroundId,
  );

  /// Get active monitoring settings
  Future<List<CampsiteMonitoringSettings>> getActiveMonitoringSettings();

  /// Update monitoring settings active status
  Future<void> updateMonitoringSettingsStatus(String settingsId, bool isActive);

  /// Delete monitoring settings
  Future<void> deleteMonitoringSettings(String settingsId);

  // AVAILABILITY TRACKING

  /// Record availability check
  Future<void> recordAvailabilityCheck(
    String campsiteId,
    bool wasAvailable,
    double? price,
    String? monitoringSettingsId,
  );

  /// Check campsite availability from API
  Future<CampsiteAvailabilityData> checkCampsiteAvailability(
    String campgroundId,
    String campsiteId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Monitor campsites by criteria
  Future<List<CampsiteAvailabilityData>> monitorCampsitesByCriteria(
    String campgroundId,
    CampsiteMonitoringSettings settings,
  );

  /// Get alternative campsite suggestions
  Future<List<Campsite>> getAlternativeCampsites(
    String campgroundId,
    CampsiteMonitoringSettings settings, {
    int maxSuggestions = 5,
  });

  // DATA MANAGEMENT

  /// Refresh campsite data from API
  Future<void> refreshCampsiteData(String campgroundId);

  /// Clear cached campsite data
  Future<void> clearCampsiteCache();

  /// Get last sync time for campground
  Future<DateTime?> getLastSyncTime(String campgroundId);
}
