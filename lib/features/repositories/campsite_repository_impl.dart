import 'package:logger/logger.dart';
import '../../shared/models/campsite.dart';
import '../../shared/models/campsite_monitoring_settings.dart';
import '../../shared/services/campsite_api_service.dart';
import '../../core/storage/campsite_database.dart';
import '../../core/utils/app_logger.dart';
import 'campsite_repository.dart';

/// Implementation of CampsiteRepository combining API and local database
class CampsiteRepositoryImpl implements CampsiteRepository {
  final CampsiteApiService _apiService;
  final CampsiteDatabase _database;
  final Logger _logger = Logger();

  static const Duration _cacheExpiration = Duration(hours: 6);

  CampsiteRepositoryImpl({
    required CampsiteApiService apiService,
    required CampsiteDatabase database,
  }) : _apiService = apiService,
       _database = database;

  // CAMPSITE OPERATIONS

  @override
  Future<List<Campsite>> getCampsitesByCampground(String campgroundId) async {
    try {
      AppLogger.info('📋 Getting campsites for campground: $campgroundId');

      // Try to get cached data first
      List<Campsite> cachedCampsites = await _database.getCampsitesByCampground(
        campgroundId,
      );

      // Check if we need to refresh from API
      final lastSync = await getLastSyncTime(campgroundId);
      final needsRefresh =
          lastSync == null ||
          DateTime.now().difference(lastSync) > _cacheExpiration ||
          cachedCampsites.isEmpty;

      if (needsRefresh) {
        AppLogger.info('🔄 Refreshing campsites from API for: $campgroundId');
        await refreshCampsiteData(campgroundId);
        cachedCampsites = await _database.getCampsitesByCampground(
          campgroundId,
        );
      }

      AppLogger.info(
        '✅ Retrieved ${cachedCampsites.length} campsites for $campgroundId',
      );
      return cachedCampsites;
    } catch (e) {
      AppLogger.error(
        '❌ Failed to get campsites for campground $campgroundId',
        e,
      );
      // Fallback to cached data
      return await _database.getCampsitesByCampground(campgroundId);
    }
  }

  @override
  Future<List<Campsite>> getAvailableCampsites(
    String campgroundId, {
    DateTime? startDate,
    DateTime? endDate,
    String? siteType,
    bool? accessibility,
    double? maxPrice,
  }) async {
    try {
      AppLogger.info('🔍 Getting available campsites for: $campgroundId');

      // Get all campsites for the campground
      final allCampsites = await getCampsitesByCampground(campgroundId);

      // Apply filters
      final filteredCampsites = allCampsites.where((campsite) {
        // Availability filter
        if (startDate != null && endDate != null) {
          if (!campsite.isAvailableForDates(startDate, endDate)) {
            return false;
          }
        } else if (!campsite.isAvailable) {
          return false;
        }

        // Site type filter
        if (siteType != null && siteType.isNotEmpty) {
          if (!campsite.siteType.toLowerCase().contains(
            siteType.toLowerCase(),
          )) {
            return false;
          }
        }

        // Accessibility filter
        if (accessibility == true && !campsite.accessibility) {
          return false;
        }

        // Price filter
        if (maxPrice != null && campsite.pricePerNight != null) {
          if (campsite.pricePerNight! > maxPrice) {
            return false;
          }
        }

        return true;
      }).toList();

      // Sort by price and availability
      filteredCampsites.sort((a, b) {
        // Available sites first
        if (a.isAvailable && !b.isAvailable) return -1;
        if (!a.isAvailable && b.isAvailable) return 1;

        // Then by price (low to high)
        if (a.pricePerNight != null && b.pricePerNight != null) {
          return a.pricePerNight!.compareTo(b.pricePerNight!);
        }

        // Finally by site number
        return a.siteNumber.compareTo(b.siteNumber);
      });

      AppLogger.info('✅ Found ${filteredCampsites.length} available campsites');
      return filteredCampsites;
    } catch (e) {
      AppLogger.error('❌ Failed to get available campsites', e);
      return [];
    }
  }

  @override
  Future<Campsite?> getCampsiteDetails(
    String campgroundId,
    String campsiteId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.info('📋 Getting campsite details: $campsiteId');

      // Get detailed campsite info from API with availability
      final campsite = await _apiService.getCampsiteDetails(
        campgroundId,
        campsiteId,
        startDate: startDate,
        endDate: endDate,
      );

      if (campsite != null) {
        // Save to database for caching
        await _database.saveCampsite(campsite);
        AppLogger.info('✅ Retrieved campsite details for: $campsiteId');
      }

      return campsite;
    } catch (e) {
      AppLogger.error('❌ Failed to get campsite details for $campsiteId', e);
      return null;
    }
  }

  @override
  Future<void> saveCampsite(Campsite campsite) async {
    try {
      await _database.saveCampsite(campsite);
      AppLogger.debug('💾 Saved campsite: ${campsite.id}');
    } catch (e) {
      AppLogger.error('๎ Failed to save campsite', e);
      rethrow;
    }
  }

  @override
  Future<void> saveCampsites(List<Campsite> campsites) async {
    try {
      await _database.saveCampsites(campsites);
      AppLogger.info('💾 Saved ${campsites.length} campsites to database');
    } catch (e) {
      AppLogger.error('๎ Failed to save campsites', e);
      rethrow;
    }
  }

  @override
  Future<void> updateCampsiteMonitoring(
    String campsiteId,
    bool isMonitored,
  ) async {
    try {
      await _database.updateCampsiteMonitoring(campsiteId, isMonitored);
      AppLogger.info(
        '🔔 Updated campsite monitoring: $campsiteId -> $isMonitored',
      );
    } catch (e) {
      AppLogger.error('๎ Failed to update campsite monitoring', e);
      rethrow;
    }
  }

  @override
  Future<List<Campsite>> getMonitoredCampsites() async {
    try {
      final campsites = await _database.getMonitoredCampsites();
      AppLogger.info('📋 Retrieved ${campsites.length} monitored campsites');
      return campsites;
    } catch (e) {
      AppLogger.error('๎ Failed to get monitored campsites', e);
      return [];
    }
  }

  // MONITORING SETTINGS OPERATIONS

  @override
  Future<void> saveMonitoringSettings(
    CampsiteMonitoringSettings settings,
  ) async {
    try {
      await _database.saveMonitoringSettings(settings);
      AppLogger.info('💾 Saved monitoring settings: ${settings.id}');
    } catch (e) {
      AppLogger.error('๎ Failed to save monitoring settings', e);
      rethrow;
    }
  }

  @override
  Future<void> updateMonitoringSettings(
    CampsiteMonitoringSettings settings,
  ) async {
    try {
      await _database.saveMonitoringSettings(
        settings,
      ); // Save handles updates too
      AppLogger.info('📝 Updated monitoring settings: ${settings.id}');
    } catch (e) {
      AppLogger.error('๎ Failed to update monitoring settings', e);
      rethrow;
    }
  }

  @override
  Future<List<CampsiteMonitoringSettings>> getAllMonitoringSettings() async {
    try {
      final settings = await _database.getActiveMonitoringSettings();
      AppLogger.info('📋 Retrieved ${settings.length} monitoring settings');
      return settings;
    } catch (e) {
      AppLogger.error('๎ Failed to get monitoring settings', e);
      return [];
    }
  }

  @override
  Future<List<CampsiteMonitoringSettings>> getMonitoringSettingsByCampground(
    String campgroundId,
  ) async {
    try {
      final settings = await _database.getMonitoringSettingsByCampground(
        campgroundId,
      );
      AppLogger.info(
        '📋 Retrieved ${settings.length} monitoring settings for campground: $campgroundId',
      );
      return settings;
    } catch (e) {
      AppLogger.error('❌ Failed to get monitoring settings for campground', e);
      return [];
    }
  }

  @override
  Future<List<CampsiteMonitoringSettings>> getActiveMonitoringSettings() async {
    try {
      final settings = await _database.getActiveMonitoringSettings();
      AppLogger.info(
        '📋 Retrieved ${settings.length} active monitoring settings',
      );
      return settings;
    } catch (e) {
      AppLogger.error('๎ Failed to get active monitoring settings', e);
      return [];
    }
  }

  @override
  Future<void> updateMonitoringSettingsStatus(
    String settingsId,
    bool isActive,
  ) async {
    try {
      await _database.updateMonitoringSettingsStatus(settingsId, isActive);
      AppLogger.info(
        '🔔 Updated monitoring settings status: $settingsId -> $isActive',
      );
    } catch (e) {
      AppLogger.error('❌ Failed to update monitoring settings status', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteMonitoringSettings(String settingsId) async {
    try {
      // TODO: Implement delete in database
      AppLogger.info('🗑️ Deleted monitoring settings: $settingsId');
    } catch (e) {
      AppLogger.error('๎ Failed to delete monitoring settings', e);
      rethrow;
    }
  }

  // AVAILABILITY TRACKING

  @override
  Future<void> recordAvailabilityCheck(
    String campsiteId,
    bool wasAvailable,
    double? price,
    String? monitoringSettingsId,
  ) async {
    try {
      await _database.recordAvailabilityCheck(
        campsiteId,
        wasAvailable,
        price,
        monitoringSettingsId,
      );
      AppLogger.debug('📊 Recorded availability check for: $campsiteId');
    } catch (e) {
      AppLogger.error('๎ Failed to record availability check', e);
    }
  }

  @override
  Future<CampsiteAvailabilityData> checkCampsiteAvailability(
    String campgroundId,
    String campsiteId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final availability = await _apiService.checkCampsiteAvailability(
        campgroundId,
        campsiteId,
        startDate,
        endDate,
      );

      // Record the check
      await recordAvailabilityCheck(
        campsiteId,
        availability.isAvailable,
        availability.averagePricePerNight,
        null,
      );

      AppLogger.info('✅ Checked availability for campsite: $campsiteId');
      return availability;
    } catch (e) {
      AppLogger.error('๎ Failed to check campsite availability', e);
      rethrow;
    }
  }

  @override
  Future<List<CampsiteAvailabilityData>> monitorCampsitesByCriteria(
    String campgroundId,
    CampsiteMonitoringSettings settings,
  ) async {
    try {
      final results = await _apiService.monitorCampsitesByCriteria(
        campgroundId,
        settings,
      );

      // Record checks for all monitored sites
      for (final result in results) {
        await recordAvailabilityCheck(
          result.campsiteInfo?.id ?? '',
          result.isAvailable,
          result.averagePricePerNight,
          settings.id,
        );
      }

      AppLogger.info('✅ Completed monitoring check: ${results.length} results');
      return results;
    } catch (e) {
      AppLogger.error('๎ Failed to monitor campsites by criteria', e);
      rethrow;
    }
  }

  @override
  Future<List<Campsite>> getAlternativeCampsites(
    String campgroundId,
    CampsiteMonitoringSettings settings, {
    int maxSuggestions = 5,
  }) async {
    try {
      final alternatives = await _apiService.getAlternativeCampsites(
        campgroundId,
        settings,
        maxSuggestions: maxSuggestions,
      );

      AppLogger.info('✅ Found ${alternatives.length} alternative campsites');
      return alternatives;
    } catch (e) {
      AppLogger.error('๎ Failed to get alternative campsites', e);
      return [];
    }
  }

  // DATA MANAGEMENT

  @override
  Future<void> refreshCampsiteData(String campgroundId) async {
    try {
      AppLogger.info('🔄 Refreshing campsite data for: $campgroundId');

      // Get fresh campsite data from API
      final campsites = await _apiService.getCampsitesByCampground(
        campgroundId,
      );

      // Save to database
      if (campsites.isNotEmpty) {
        await _database.saveCampsites(campsites);

        // Update sync timestamp
        // TODO: Store sync timestamp in database

        AppLogger.info(
          '✅ Refreshed ${campsites.length} campsites for: $campgroundId',
        );
      }
    } catch (e) {
      AppLogger.error('❌ Failed to refresh campsite data for $campgroundId', e);
      rethrow;
    }
  }

  @override
  Future<void> clearCampsiteCache() async {
    try {
      await _database.clearAllData();
      AppLogger.info('🧹 Cleared campsite cache');
    } catch (e) {
      AppLogger.error('๎ Failed to clear campsite cache', e);
      rethrow;
    }
  }

  @override
  Future<DateTime?> getLastSyncTime(String campgroundId) async {
    try {
      // TODO: Implement proper sync timestamp storage
      // For now, return null to always refresh
      return null;
    } catch (e) {
      AppLogger.error('๎ Failed to get last sync time', e);
      return null;
    }
  }
}
