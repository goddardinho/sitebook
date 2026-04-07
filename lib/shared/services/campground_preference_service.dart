import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_preference_service.dart';
import '../models/campsite_monitoring_settings.dart';

/// Service for managing campground-specific preferences and device synchronization
class CampgroundPreferenceService {
  static const String _keyCampgroundPreferences = 'campground_preferences_';
  static const String _keyGlobalSitePreferences = 'global_site_preferences';
  static const String _keyDeviceSyncSettings = 'device_sync_settings';
  static const String _keyPreferenceSyncQueue = 'preference_sync_queue';
  static const String _keyLastFullSync = 'last_full_sync';

  SharedPreferences? _prefs;
  final UserPreferenceService _userPreferenceService = UserPreferenceService();

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _userPreferenceService.initialize();
    debugPrint('✅ CampgroundPreferenceService initialized');
  }

  /// Save campground-specific preferences
  Future<void> saveCampgroundPreferences(
    String campgroundId,
    CampgroundSpecificPreferences preferences,
  ) async {
    try {
      final key = '$_keyCampgroundPreferences$campgroundId';
      final prefsJson = preferences.toJson();
      await _prefs?.setString(key, jsonEncode(prefsJson));

      // Add to sync queue for cross-device sync
      await _addToSyncQueue('update_campground_pref', {
        'campgroundId': campgroundId,
        'preferences': prefsJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('🏕️ Saved preferences for campground $campgroundId');
    } catch (e) {
      debugPrint('❌ Error saving campground preferences: $e');
    }
  }

  /// Get campground-specific preferences
  Future<CampgroundSpecificPreferences> getCampgroundPreferences(
    String campgroundId,
  ) async {
    try {
      final key = '$_keyCampgroundPreferences$campgroundId';
      final prefsString = _prefs?.getString(key);

      if (prefsString != null) {
        final prefsMap = jsonDecode(prefsString) as Map<String, dynamic>;
        return CampgroundSpecificPreferences.fromJson(prefsMap);
      }
    } catch (e) {
      debugPrint('❌ Error loading campground preferences: $e');
    }

    return CampgroundSpecificPreferences.defaultSettings(campgroundId);
  }

  /// Save global site preferences (apply to all campgrounds)
  Future<void> saveGlobalSitePreferences(
    GlobalSitePreferences preferences,
  ) async {
    try {
      final prefsJson = preferences.toJson();
      await _prefs?.setString(_keyGlobalSitePreferences, jsonEncode(prefsJson));

      await _addToSyncQueue('update_global_site_pref', {
        'preferences': prefsJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('🌍 Saved global site preferences');
    } catch (e) {
      debugPrint('❌ Error saving global site preferences: $e');
    }
  }

  /// Get global site preferences
  Future<GlobalSitePreferences> getGlobalSitePreferences() async {
    try {
      final prefsString = _prefs?.getString(_keyGlobalSitePreferences);
      if (prefsString != null) {
        final prefsMap = jsonDecode(prefsString) as Map<String, dynamic>;
        return GlobalSitePreferences.fromJson(prefsMap);
      }
    } catch (e) {
      debugPrint('❌ Error loading global site preferences: $e');
    }

    return GlobalSitePreferences.defaultSettings();
  }

  /// Get all campground preferences for backup/sync
  Future<Map<String, CampgroundSpecificPreferences>>
  getAllCampgroundPreferences() async {
    final allPreferences = <String, CampgroundSpecificPreferences>{};

    try {
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        if (key.startsWith(_keyCampgroundPreferences)) {
          final campgroundId = key.substring(_keyCampgroundPreferences.length);
          final preferences = await getCampgroundPreferences(campgroundId);
          allPreferences[campgroundId] = preferences;
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading all campground preferences: $e');
    }

    return allPreferences;
  }

  /// Apply monitoring preferences to settings based on campground and global preferences
  Future<CampsiteMonitoringSettings> applyPreferencesToSettings(
    CampsiteMonitoringSettings baseSettings,
    String campgroundId,
  ) async {
    final campgroundPrefs = await getCampgroundPreferences(campgroundId);
    final globalPrefs = await getGlobalSitePreferences();

    // Apply global preferences first, then campground-specific overrides
    var updatedSettings = baseSettings.copyWith(
      // Global site preferences
      preferredSiteTypes: globalPrefs.preferredSiteTypes.isNotEmpty
          ? globalPrefs.preferredSiteTypes
          : baseSettings.preferredSiteTypes,
      requireAccessibility:
          globalPrefs.requireAccessibility ?? baseSettings.requireAccessibility,
      maxPricePerNight:
          globalPrefs.maxPricePerNight ?? baseSettings.maxPricePerNight,
      priority: globalPrefs.defaultPriority ?? baseSettings.priority,
    );

    // Apply campground-specific preferences as overrides
    updatedSettings = updatedSettings.copyWith(
      preferredSiteNumbers: campgroundPrefs.preferredSiteNumbers.isNotEmpty
          ? campgroundPrefs.preferredSiteNumbers
          : updatedSettings.preferredSiteNumbers,
      maxNotificationsPerDay:
          campgroundPrefs.maxNotificationsPerDay ??
          updatedSettings.maxNotificationsPerDay,
      enableQuietHours:
          campgroundPrefs.respectQuietHours ?? updatedSettings.enableQuietHours,
      quietHourStart:
          campgroundPrefs.customQuietHourStart ??
          updatedSettings.quietHourStart,
      quietHourEnd:
          campgroundPrefs.customQuietHourEnd ?? updatedSettings.quietHourEnd,
    );

    // Apply campground-specific notification frequency
    final notificationFreq = _userPreferenceService.getNotificationFrequency(
      campgroundId,
    );
    updatedSettings = _applyNotificationFrequencyToSettings(
      updatedSettings,
      notificationFreq,
    );

    return updatedSettings;
  }

  /// Apply notification frequency to monitoring settings
  CampsiteMonitoringSettings _applyNotificationFrequencyToSettings(
    CampsiteMonitoringSettings settings,
    NotificationFrequency frequency,
  ) {
    switch (frequency) {
      case NotificationFrequency.never:
        return settings.copyWith(maxNotificationsPerDay: 0);
      case NotificationFrequency.low:
        return settings.copyWith(maxNotificationsPerDay: 1);
      case NotificationFrequency.normal:
        return settings.copyWith(maxNotificationsPerDay: 5);
      case NotificationFrequency.high:
        return settings.copyWith(maxNotificationsPerDay: 15);
      case NotificationFrequency.instant:
        return settings.copyWith(maxNotificationsPerDay: 50);
    }
  }

  /// Configure device synchronization settings
  Future<void> configureDeviceSync(DeviceSyncSettings settings) async {
    try {
      await _prefs?.setString(
        _keyDeviceSyncSettings,
        jsonEncode(settings.toJson()),
      );
      debugPrint('🔄 Configured device sync settings');
    } catch (e) {
      debugPrint('❌ Error configuring device sync: $e');
    }
  }

  /// Get device synchronization settings
  Future<DeviceSyncSettings> getDeviceSyncSettings() async {
    try {
      final settingsString = _prefs?.getString(_keyDeviceSyncSettings);
      if (settingsString != null) {
        final settingsMap = jsonDecode(settingsString) as Map<String, dynamic>;
        return DeviceSyncSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('❌ Error loading device sync settings: $e');
    }

    return DeviceSyncSettings.defaultSettings();
  }

  /// Add item to sync queue for cross-device synchronization
  Future<void> _addToSyncQueue(String action, Map<String, dynamic> data) async {
    try {
      final syncQueue = await _getSyncQueue();
      syncQueue.add({
        'action': action,
        'data': data,
        'deviceId': await _getDeviceId(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Keep only last 100 items in queue
      if (syncQueue.length > 100) {
        syncQueue.removeRange(0, syncQueue.length - 100);
      }

      await _prefs?.setString(_keyPreferenceSyncQueue, jsonEncode(syncQueue));
    } catch (e) {
      debugPrint('❌ Error adding to sync queue: $e');
    }
  }

  /// Get pending sync items
  Future<List<Map<String, dynamic>>> _getSyncQueue() async {
    try {
      final queueString = _prefs?.getString(_keyPreferenceSyncQueue);
      if (queueString != null) {
        final queueList = jsonDecode(queueString) as List<dynamic>;
        return queueList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('❌ Error loading sync queue: $e');
    }

    return [];
  }

  /// Simulate device sync (in real app would sync with cloud service)
  Future<void> performDeviceSync() async {
    final syncSettings = await getDeviceSyncSettings();
    if (!syncSettings.enableAutoSync) {
      debugPrint('⚠️ Auto-sync is disabled');
      return;
    }

    try {
      debugPrint('🔄 Starting device sync...');

      // Get all preferences for sync
      final userPrefs = await _userPreferenceService.exportPreferences();
      final campgroundPrefs = await getAllCampgroundPreferences();
      final globalPrefs = await getGlobalSitePreferences();

      // Simulate sync payload
      final syncPayload = {
        'deviceId': await _getDeviceId(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userPreferences': userPrefs,
        'campgroundPreferences': campgroundPrefs.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
        'globalSitePreferences': globalPrefs.toJson(),
      };

      debugPrint(
        '📤 Sync payload prepared with ${syncPayload.length} sections',
      );

      // In a real implementation, this would:
      // 1. Upload to cloud service (Firebase, AWS, etc.)
      // 2. Download updates from other devices
      // 3. Resolve conflicts
      // 4. Apply changes locally

      // Simulate successful sync
      await Future.delayed(const Duration(milliseconds: 500));
      await _prefs?.setInt(
        _keyLastFullSync,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('✅ Device sync completed successfully');
    } catch (e) {
      debugPrint('❌ Device sync failed: $e');
    }
  }

  /// Get device identifier for sync
  Future<String> _getDeviceId() async {
    // In a real app, you'd get actual device ID
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get last full sync timestamp
  DateTime? getLastFullSyncTimestamp() {
    final timestamp = _prefs?.getInt(_keyLastFullSync);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Check if sync is needed based on settings and last sync time
  Future<bool> isSyncNeeded() async {
    final syncSettings = await getDeviceSyncSettings();
    if (!syncSettings.enableAutoSync) return false;

    final lastSync = getLastFullSyncTimestamp();
    if (lastSync == null) return true;

    final timeSinceSync = DateTime.now().difference(lastSync);
    return timeSinceSync.inHours >= syncSettings.syncIntervalHours;
  }

  /// Clear all campground-specific preferences
  Future<void> clearAllCampgroundPreferences() async {
    try {
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        if (key.startsWith(_keyCampgroundPreferences)) {
          await _prefs?.remove(key);
        }
      }
      debugPrint('🗑️ Cleared all campground preferences');
    } catch (e) {
      debugPrint('❌ Error clearing campground preferences: $e');
    }
  }
}

/// Data class for campground-specific preferences
class CampgroundSpecificPreferences {
  final String campgroundId;
  final List<String> preferredSiteNumbers;
  final int? maxNotificationsPerDay;
  final bool? respectQuietHours;
  final int? customQuietHourStart;
  final int? customQuietHourEnd;
  final double? maxPriceOverride;
  final Map<String, dynamic> customSettings;
  final DateTime lastUpdated;

  const CampgroundSpecificPreferences({
    required this.campgroundId,
    required this.preferredSiteNumbers,
    this.maxNotificationsPerDay,
    this.respectQuietHours,
    this.customQuietHourStart,
    this.customQuietHourEnd,
    this.maxPriceOverride,
    this.customSettings = const {},
    required this.lastUpdated,
  });

  factory CampgroundSpecificPreferences.defaultSettings(String campgroundId) {
    return CampgroundSpecificPreferences(
      campgroundId: campgroundId,
      preferredSiteNumbers: [],
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'campgroundId': campgroundId,
    'preferredSiteNumbers': preferredSiteNumbers,
    'maxNotificationsPerDay': maxNotificationsPerDay,
    'respectQuietHours': respectQuietHours,
    'customQuietHourStart': customQuietHourStart,
    'customQuietHourEnd': customQuietHourEnd,
    'maxPriceOverride': maxPriceOverride,
    'customSettings': customSettings,
    'lastUpdated': lastUpdated.millisecondsSinceEpoch,
  };

  factory CampgroundSpecificPreferences.fromJson(Map<String, dynamic> json) {
    return CampgroundSpecificPreferences(
      campgroundId: json['campgroundId'] as String,
      preferredSiteNumbers: (json['preferredSiteNumbers'] as List<dynamic>)
          .cast<String>(),
      maxNotificationsPerDay: json['maxNotificationsPerDay'] as int?,
      respectQuietHours: json['respectQuietHours'] as bool?,
      customQuietHourStart: json['customQuietHourStart'] as int?,
      customQuietHourEnd: json['customQuietHourEnd'] as int?,
      maxPriceOverride: (json['maxPriceOverride'] as num?)?.toDouble(),
      customSettings: (json['customSettings'] as Map<String, dynamic>?) ?? {},
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        json['lastUpdated'] as int,
      ),
    );
  }

  CampgroundSpecificPreferences copyWith({
    String? campgroundId,
    List<String>? preferredSiteNumbers,
    int? maxNotificationsPerDay,
    bool? respectQuietHours,
    int? customQuietHourStart,
    int? customQuietHourEnd,
    double? maxPriceOverride,
    Map<String, dynamic>? customSettings,
    DateTime? lastUpdated,
  }) {
    return CampgroundSpecificPreferences(
      campgroundId: campgroundId ?? this.campgroundId,
      preferredSiteNumbers: preferredSiteNumbers ?? this.preferredSiteNumbers,
      maxNotificationsPerDay:
          maxNotificationsPerDay ?? this.maxNotificationsPerDay,
      respectQuietHours: respectQuietHours ?? this.respectQuietHours,
      customQuietHourStart: customQuietHourStart ?? this.customQuietHourStart,
      customQuietHourEnd: customQuietHourEnd ?? this.customQuietHourEnd,
      maxPriceOverride: maxPriceOverride ?? this.maxPriceOverride,
      customSettings: customSettings ?? this.customSettings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Data class for global site preferences (applied to all campgrounds)
class GlobalSitePreferences {
  final List<String> preferredSiteTypes;
  final bool? requireAccessibility;
  final double? maxPricePerNight;
  final MonitoringPriority? defaultPriority;
  final bool enableSmartDefaults;
  final DateTime lastUpdated;

  const GlobalSitePreferences({
    required this.preferredSiteTypes,
    this.requireAccessibility,
    this.maxPricePerNight,
    this.defaultPriority,
    required this.enableSmartDefaults,
    required this.lastUpdated,
  });

  factory GlobalSitePreferences.defaultSettings() {
    return GlobalSitePreferences(
      preferredSiteTypes: ['Standard', 'Electric'],
      requireAccessibility: false,
      maxPricePerNight: 50.0,
      defaultPriority: MonitoringPriority.normal,
      enableSmartDefaults: true,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'preferredSiteTypes': preferredSiteTypes,
    'requireAccessibility': requireAccessibility,
    'maxPricePerNight': maxPricePerNight,
    'defaultPriority': defaultPriority?.index,
    'enableSmartDefaults': enableSmartDefaults,
    'lastUpdated': lastUpdated.millisecondsSinceEpoch,
  };

  factory GlobalSitePreferences.fromJson(Map<String, dynamic> json) {
    return GlobalSitePreferences(
      preferredSiteTypes: (json['preferredSiteTypes'] as List<dynamic>)
          .cast<String>(),
      requireAccessibility: json['requireAccessibility'] as bool?,
      maxPricePerNight: (json['maxPricePerNight'] as num?)?.toDouble(),
      defaultPriority: json['defaultPriority'] != null
          ? MonitoringPriority.values[json['defaultPriority'] as int]
          : null,
      enableSmartDefaults: json['enableSmartDefaults'] as bool,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        json['lastUpdated'] as int,
      ),
    );
  }
}

/// Data class for device synchronization settings
class DeviceSyncSettings {
  final bool enableAutoSync;
  final int syncIntervalHours;
  final bool syncOverWifiOnly;
  final bool syncPreferences;
  final bool syncHistory;
  final bool syncFavorites;
  final String? cloudProvider; // 'firebase', 'aws', 'custom', etc.

  const DeviceSyncSettings({
    required this.enableAutoSync,
    required this.syncIntervalHours,
    required this.syncOverWifiOnly,
    required this.syncPreferences,
    required this.syncHistory,
    required this.syncFavorites,
    this.cloudProvider,
  });

  factory DeviceSyncSettings.defaultSettings() {
    return const DeviceSyncSettings(
      enableAutoSync: true,
      syncIntervalHours: 6,
      syncOverWifiOnly: false,
      syncPreferences: true,
      syncHistory: true,
      syncFavorites: true,
      cloudProvider: 'local', // For demo purposes
    );
  }

  Map<String, dynamic> toJson() => {
    'enableAutoSync': enableAutoSync,
    'syncIntervalHours': syncIntervalHours,
    'syncOverWifiOnly': syncOverWifiOnly,
    'syncPreferences': syncPreferences,
    'syncHistory': syncHistory,
    'syncFavorites': syncFavorites,
    'cloudProvider': cloudProvider,
  };

  factory DeviceSyncSettings.fromJson(Map<String, dynamic> json) {
    return DeviceSyncSettings(
      enableAutoSync: json['enableAutoSync'] as bool,
      syncIntervalHours: json['syncIntervalHours'] as int,
      syncOverWifiOnly: json['syncOverWifiOnly'] as bool,
      syncPreferences: json['syncPreferences'] as bool,
      syncHistory: json['syncHistory'] as bool,
      syncFavorites: json['syncFavorites'] as bool,
      cloudProvider: json['cloudProvider'] as String?,
    );
  }
}
