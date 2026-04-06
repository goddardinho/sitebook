import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/campsite.dart';
import '../../shared/models/campsite_monitoring_settings.dart';
import '../../shared/services/campsite_api_service.dart';
import '../../core/storage/campsite_database.dart';
import '../repositories/campsite_repository.dart';
import '../repositories/campsite_repository_impl.dart';
import '../../core/utils/app_logger.dart';

// REPOSITORIES
final campsiteDatabaseProvider = Provider<CampsiteDatabase>((ref) {
  return CampsiteDatabase();
});

final campsiteApiServiceProvider = Provider<CampsiteApiService>((ref) {
  return CampsiteApiService();
});

final campsiteRepositoryProvider = Provider<CampsiteRepository>((ref) {
  return CampsiteRepositoryImpl(
    apiService: ref.watch(campsiteApiServiceProvider),
    database: ref.watch(campsiteDatabaseProvider),
  );
});

// CAMPSITE DATA PROVIDERS

/// Get all campsites for a specific campground
final campsitesByCampgroundProvider =
    FutureProvider.family<List<Campsite>, String>((ref, campgroundId) async {
      AppLogger.info('🏕️ Loading campsites for campground: $campgroundId');
      final repository = ref.watch(campsiteRepositoryProvider);
      return await repository.getCampsitesByCampground(campgroundId);
    });

/// Get available campsites with filters
final availableCampsitesProvider =
    FutureProvider.family<List<Campsite>, CampsiteFilter>((ref, filter) async {
      AppLogger.info(
        '🔍 Searching available campsites with filter: ${filter.campgroundId}',
      );
      final repository = ref.watch(campsiteRepositoryProvider);
      return await repository.getAvailableCampsites(
        filter.campgroundId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        siteType: filter.siteType,
        accessibility: filter.accessibility,
        maxPrice: filter.maxPrice,
      );
    });

/// Get specific campsite details with availability
final campsiteDetailsProvider =
    FutureProvider.family<Campsite?, CampsiteDetailRequest>((
      ref,
      request,
    ) async {
      AppLogger.info('📋 Loading campsite details: ${request.campsiteId}');
      final repository = ref.watch(campsiteRepositoryProvider);
      return await repository.getCampsiteDetails(
        request.campgroundId,
        request.campsiteId,
        startDate: request.startDate,
        endDate: request.endDate,
      );
    });

/// Check realtime availability for a campsite
final campsiteAvailabilityProvider =
    FutureProvider.family<
      CampsiteAvailabilityData,
      CampsiteAvailabilityRequest
    >((ref, request) async {
      AppLogger.info(
        '⏰ Checking availability for campsite: ${request.campsiteId}',
      );
      final apiService = ref.watch(campsiteApiServiceProvider);
      return await apiService.checkCampsiteAvailability(
        request.campgroundId,
        request.campsiteId,
        request.startDate,
        request.endDate,
      );
    });

// MONITORING SETTINGS PROVIDERS

/// Get all monitoring settings for a user
final allMonitoringSettingsProvider =
    FutureProvider<List<CampsiteMonitoringSettings>>((ref) async {
      AppLogger.info('🔔 Loading all monitoring settings');
      final repository = ref.watch(campsiteRepositoryProvider);
      return await repository.getAllMonitoringSettings();
    });

/// Get monitoring settings for a specific campground
final monitoringSettingsByCampgroundProvider =
    FutureProvider.family<List<CampsiteMonitoringSettings>, String>((
      ref,
      campgroundId,
    ) async {
      AppLogger.info(
        '🏕️ Loading monitoring settings for campground: $campgroundId',
      );
      final repository = ref.watch(campsiteRepositoryProvider);
      return await repository.getMonitoringSettingsByCampground(campgroundId);
    });

/// Get active monitoring settings only
final activeMonitoringSettingsProvider =
    FutureProvider<List<CampsiteMonitoringSettings>>((ref) async {
      AppLogger.info('✅ Loading active monitoring settings');
      final repository = ref.watch(campsiteRepositoryProvider);
      return await repository.getActiveMonitoringSettings();
    });

// MONITORING ACTIONS

/// Provider for managing monitoring settings
final monitoringControllerProvider = Provider<MonitoringController>((ref) {
  return MonitoringController(
    repository: ref.watch(campsiteRepositoryProvider),
    ref: ref,
  );
});

// ALTERNATIVE SUGGESTIONS

/// Get alternative campsite suggestions
final alternativeCampsitesProvider =
    FutureProvider.family<List<Campsite>, AlternativeRequest>((
      ref,
      request,
    ) async {
      AppLogger.info(
        '🔄 Loading alternative campsites for: ${request.campgroundId}',
      );
      final apiService = ref.watch(campsiteApiServiceProvider);
      return await apiService.getAlternativeCampsites(
        request.campgroundId,
        request.settings,
        maxSuggestions: request.maxSuggestions,
      );
    });

/// Monitor campsites by criteria
final monitoredCampsitesProvider =
    FutureProvider.family<
      List<CampsiteAvailabilityData>,
      CampsiteMonitoringSettings
    >((ref, settings) async {
      AppLogger.info(
        '🎯 Monitoring campsites by criteria for: ${settings.campgroundId}',
      );
      final apiService = ref.watch(campsiteApiServiceProvider);
      return await apiService.monitorCampsitesByCriteria(
        settings.campgroundId,
        settings,
      );
    });

// CONTROLLER CLASS
class MonitoringController {
  final CampsiteRepository repository;
  final Ref ref;

  MonitoringController({required this.repository, required this.ref});

  /// Save new monitoring settings
  Future<void> saveMonitoringSettings(
    CampsiteMonitoringSettings settings,
  ) async {
    try {
      AppLogger.info('💾 Saving monitoring settings: ${settings.id}');
      await repository.saveMonitoringSettings(settings);

      // Invalidate relevant providers
      ref.invalidate(
        monitoringSettingsByCampgroundProvider(settings.campgroundId),
      );
      ref.invalidate(allMonitoringSettingsProvider);
      ref.invalidate(activeMonitoringSettingsProvider);

      AppLogger.info('✅ Monitoring settings saved successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to save monitoring settings', e);
      rethrow;
    }
  }

  /// Update monitoring settings
  Future<void> updateMonitoringSettings(
    CampsiteMonitoringSettings settings,
  ) async {
    try {
      AppLogger.info('📝 Updating monitoring settings: ${settings.id}');
      await repository.updateMonitoringSettings(settings);

      // Invalidate relevant providers
      ref.invalidate(
        monitoringSettingsByCampgroundProvider(settings.campgroundId),
      );
      ref.invalidate(allMonitoringSettingsProvider);
      ref.invalidate(activeMonitoringSettingsProvider);

      AppLogger.info('✅ Monitoring settings updated successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to update monitoring settings', e);
      rethrow;
    }
  }

  /// Toggle monitoring active status
  Future<void> toggleMonitoringStatus(String settingsId, bool isActive) async {
    try {
      AppLogger.info('🔄 Toggling monitoring status: $settingsId -> $isActive');
      await repository.updateMonitoringSettingsStatus(settingsId, isActive);

      // Invalidate all monitoring providers
      ref.invalidate(allMonitoringSettingsProvider);
      ref.invalidate(activeMonitoringSettingsProvider);

      AppLogger.info('✅ Monitoring status updated successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to toggle monitoring status', e);
      rethrow;
    }
  }

  /// Delete monitoring settings
  Future<void> deleteMonitoringSettings(String settingsId) async {
    try {
      AppLogger.info('🗑️ Deleting monitoring settings: $settingsId');
      await repository.deleteMonitoringSettings(settingsId);

      // Invalidate all monitoring providers
      ref.invalidate(allMonitoringSettingsProvider);
      ref.invalidate(activeMonitoringSettingsProvider);

      AppLogger.info('✅ Monitoring settings deleted successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to delete monitoring settings', e);
      rethrow;
    }
  }

  /// Update campsite monitoring status
  Future<void> updateCampsiteMonitoring(
    String campsiteId,
    bool isMonitored,
  ) async {
    try {
      AppLogger.info(
        '🏕️ Updating campsite monitoring: $campsiteId -> $isMonitored',
      );
      await repository.updateCampsiteMonitoring(campsiteId, isMonitored);

      AppLogger.info('✅ Campsite monitoring updated successfully');
    } catch (e) {
      AppLogger.error('❌ Failed to update campsite monitoring', e);
      rethrow;
    }
  }

  /// Run monitoring check for specific settings
  Future<List<CampsiteAvailabilityData>> runMonitoringCheck(
    CampsiteMonitoringSettings settings,
  ) async {
    try {
      AppLogger.info('🔍 Running monitoring check: ${settings.id}');
      final apiService = ref.read(campsiteApiServiceProvider);
      final results = await apiService.monitorCampsitesByCriteria(
        settings.campgroundId,
        settings,
      );

      // Update last checked timestamp
      final updatedSettings = settings.copyWith(
        lastCheckedAt: DateTime.now(),
        successfulChecks: settings.successfulChecks + 1,
      );
      await repository.updateMonitoringSettings(updatedSettings);

      AppLogger.info('✅ Monitoring check completed: ${results.length} results');
      return results;
    } catch (e) {
      AppLogger.error('❌ Monitoring check failed', e);

      // Update failed checks counter
      final updatedSettings = settings.copyWith(
        lastCheckedAt: DateTime.now(),
        failedChecks: settings.failedChecks + 1,
      );
      await repository.updateMonitoringSettings(updatedSettings);

      rethrow;
    }
  }
}

// DATA CLASSES FOR PROVIDER PARAMETERS

class CampsiteFilter {
  final String campgroundId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? siteType;
  final bool? accessibility;
  final double? maxPrice;

  CampsiteFilter({
    required this.campgroundId,
    this.startDate,
    this.endDate,
    this.siteType,
    this.accessibility,
    this.maxPrice,
  });
}

class CampsiteDetailRequest {
  final String campgroundId;
  final String campsiteId;
  final DateTime? startDate;
  final DateTime? endDate;

  CampsiteDetailRequest({
    required this.campgroundId,
    required this.campsiteId,
    this.startDate,
    this.endDate,
  });
}

class CampsiteAvailabilityRequest {
  final String campgroundId;
  final String campsiteId;
  final DateTime startDate;
  final DateTime endDate;

  CampsiteAvailabilityRequest({
    required this.campgroundId,
    required this.campsiteId,
    required this.startDate,
    required this.endDate,
  });
}

class AlternativeRequest {
  final String campgroundId;
  final CampsiteMonitoringSettings settings;
  final int maxSuggestions;

  AlternativeRequest({
    required this.campgroundId,
    required this.settings,
    this.maxSuggestions = 5,
  });
}
