import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preference.dart';
import '../models/campground.dart';
import '../models/campsite.dart';
import '../models/campsite_monitoring_settings.dart';

/// Comprehensive service for managing user preferences and campsite monitoring settings
class UserPreferenceService {
  static const String _keyUserPreference = 'user_preference';
  static const String _keyMonitoringSettings = 'monitoring_settings_';
  static const String _keyRecentSearches = 'recent_searches';
  static const String _keyFavoriteCampgrounds = 'favorite_campgrounds';
  static const String _keyCampsiteHistory = 'campsite_history_';
  static const String _keyBudgetSettings = 'budget_settings';
  static const String _keyRateLimitSettings = 'rate_limit_settings';
  static const String _keyNotificationFrequency = 'notification_frequency_';
  static const String _keyPreferenceSync = 'preference_sync_timestamp';

  SharedPreferences? _prefs;
  UserPreference? _cachedPreference;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCachedPreference();
    debugPrint('✅ UserPreferenceService initialized');
  }

  /// Load user preference from cache
  Future<void> _loadCachedPreference() async {
    try {
      final prefString = _prefs?.getString(_keyUserPreference);
      if (prefString != null) {
        final prefMap = jsonDecode(prefString) as Map<String, dynamic>;
        _cachedPreference = UserPreference.fromJson(prefMap);
        debugPrint('📱 Loaded cached user preferences');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading cached preferences: $e');
    }
  }

  /// Get current user preference (creates default if none exists)
  Future<UserPreference> getUserPreference() async {
    if (_cachedPreference != null) {
      return _cachedPreference!;
    }

    return _createDefaultPreference();
  }

  /// Create default user preference
  UserPreference _createDefaultPreference() {
    return UserPreference(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      preferredAmenities: const ['Restrooms', 'Potable Water', 'Fire Rings'],
      notificationsEnabled: true,
      autoReserveEnabled: false,
      maxDistance: 50.0,
      maxBudget: 75.0,
      createdAt: DateTime.now(),
    );
  }

  /// Save user preference
  Future<void> saveUserPreference(UserPreference preference) async {
    try {
      final prefMap = preference.copyWith(updatedAt: DateTime.now()).toJson();
      await _prefs?.setString(_keyUserPreference, jsonEncode(prefMap));
      _cachedPreference = preference;

      // Update sync timestamp
      await _prefs?.setInt(
        _keyPreferenceSync,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('💾 Saved user preferences');
    } catch (e) {
      debugPrint('❌ Error saving preferences: $e');
    }
  }

  /// Save campsite monitoring settings for a campground
  Future<void> saveMonitoringSettings(
    String campgroundId,
    CampsiteMonitoringSettings settings,
  ) async {
    try {
      final settingsMap = settings.toJson();
      await _prefs?.setString(
        '$_keyMonitoringSettings$campgroundId',
        jsonEncode(settingsMap),
      );
      debugPrint('🏕️ Saved monitoring settings for $campgroundId');
    } catch (e) {
      debugPrint('❌ Error saving monitoring settings: $e');
    }
  }

  /// Get campsite monitoring settings for a campground
  Future<CampsiteMonitoringSettings?> getMonitoringSettings(
    String campgroundId,
  ) async {
    try {
      final settingsString = _prefs?.getString(
        '$_keyMonitoringSettings$campgroundId',
      );
      if (settingsString != null) {
        final settingsMap = jsonDecode(settingsString) as Map<String, dynamic>;
        return CampsiteMonitoringSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('❌ Error loading monitoring settings: $e');
    }
    return null;
  }

  /// Get all saved monitoring settings
  Future<List<CampsiteMonitoringSettings>> getAllMonitoringSettings() async {
    final settings = <CampsiteMonitoringSettings>[];

    try {
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        if (key.startsWith(_keyMonitoringSettings)) {
          final settingsString = _prefs?.getString(key);
          if (settingsString != null) {
            final settingsMap =
                jsonDecode(settingsString) as Map<String, dynamic>;
            settings.add(CampsiteMonitoringSettings.fromJson(settingsMap));
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading all monitoring settings: $e');
    }

    return settings;
  }

  /// Save recent search queries
  Future<void> saveRecentSearch(String query) async {
    try {
      final recentSearches = getRecentSearches();

      // Remove if already exists and add to front
      recentSearches.remove(query);
      recentSearches.insert(0, query);

      // Keep only last 10 searches
      if (recentSearches.length > 10) {
        recentSearches.removeRange(10, recentSearches.length);
      }

      await _prefs?.setStringList(_keyRecentSearches, recentSearches);
      debugPrint('🔍 Saved recent search: $query');
    } catch (e) {
      debugPrint('❌ Error saving recent search: $e');
    }
  }

  /// Get recent search queries
  List<String> getRecentSearches() {
    return _prefs?.getStringList(_keyRecentSearches) ?? [];
  }

  /// Clear recent searches
  Future<void> clearRecentSearches() async {
    await _prefs?.remove(_keyRecentSearches);
    debugPrint('🗑️ Cleared recent searches');
  }

  /// Add campground to favorites
  Future<void> addFavoriteCampground(String campgroundId) async {
    try {
      final favorites = getFavoriteCampgrounds();
      if (!favorites.contains(campgroundId)) {
        favorites.add(campgroundId);
        await _prefs?.setStringList(_keyFavoriteCampgrounds, favorites);
        debugPrint('⭐ Added $campgroundId to favorites');
      }
    } catch (e) {
      debugPrint('❌ Error adding favorite: $e');
    }
  }

  /// Remove campground from favorites
  Future<void> removeFavoriteCampground(String campgroundId) async {
    try {
      final favorites = getFavoriteCampgrounds();
      favorites.remove(campgroundId);
      await _prefs?.setStringList(_keyFavoriteCampgrounds, favorites);
      debugPrint('💔 Removed $campgroundId from favorites');
    } catch (e) {
      debugPrint('❌ Error removing favorite: $e');
    }
  }

  /// Get favorite campgrounds
  List<String> getFavoriteCampgrounds() {
    return _prefs?.getStringList(_keyFavoriteCampgrounds) ?? [];
  }

  /// Check if campground is favorited
  bool isCampgroundFavorite(String campgroundId) {
    return getFavoriteCampgrounds().contains(campgroundId);
  }

  /// Save campsite interaction history
  Future<void> saveCampsiteHistory(
    String campgroundId,
    CampsiteHistoryEntry entry,
  ) async {
    try {
      final historyKey = '$_keyCampsiteHistory$campgroundId';
      final historyList = getCampsiteHistory(campgroundId);

      // Remove duplicate entries for the same campsite
      historyList.removeWhere((h) => h.campsiteId == entry.campsiteId);

      // Add new entry at the beginning
      historyList.insert(0, entry);

      // Keep only last 20 entries per campground
      if (historyList.length > 20) {
        historyList.removeRange(20, historyList.length);
      }

      // Convert to JSON and save
      final historyJson = historyList.map((e) => e.toJson()).toList();
      await _prefs?.setString(historyKey, jsonEncode(historyJson));

      debugPrint('📊 Saved campsite history for $campgroundId');
    } catch (e) {
      debugPrint('❌ Error saving campsite history: $e');
    }
  }

  /// Get campsite history for a campground
  List<CampsiteHistoryEntry> getCampsiteHistory(String campgroundId) {
    try {
      final historyKey = '$_keyCampsiteHistory$campgroundId';
      final historyString = _prefs?.getString(historyKey);

      if (historyString != null) {
        final historyJson = jsonDecode(historyString) as List<dynamic>;
        return historyJson
            .map(
              (json) =>
                  CampsiteHistoryEntry.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Error loading campsite history: $e');
    }

    return [];
  }

  /// Save budget settings
  Future<void> saveBudgetSettings(BudgetSettings settings) async {
    try {
      await _prefs?.setString(
        _keyBudgetSettings,
        jsonEncode(settings.toJson()),
      );
      debugPrint('💰 Saved budget settings');
    } catch (e) {
      debugPrint('❌ Error saving budget settings: $e');
    }
  }

  /// Get budget settings
  Future<BudgetSettings> getBudgetSettings() async {
    try {
      final settingsString = _prefs?.getString(_keyBudgetSettings);
      if (settingsString != null) {
        final settingsMap = jsonDecode(settingsString) as Map<String, dynamic>;
        return BudgetSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('❌ Error loading budget settings: $e');
    }

    return BudgetSettings.defaultSettings();
  }

  /// Save rate limit settings
  Future<void> saveRateLimitSettings(RateLimitSettings settings) async {
    try {
      await _prefs?.setString(
        _keyRateLimitSettings,
        jsonEncode(settings.toJson()),
      );
      debugPrint('⚡ Saved rate limit settings');
    } catch (e) {
      debugPrint('❌ Error saving rate limit settings: $e');
    }
  }

  /// Get rate limit settings
  Future<RateLimitSettings> getRateLimitSettings() async {
    try {
      final settingsString = _prefs?.getString(_keyRateLimitSettings);
      if (settingsString != null) {
        final settingsMap = jsonDecode(settingsString) as Map<String, dynamic>;
        return RateLimitSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('❌ Error loading rate limit settings: $e');
    }

    return RateLimitSettings.defaultSettings();
  }

  /// Set notification frequency for a campground
  Future<void> setNotificationFrequency(
    String campgroundId,
    NotificationFrequency frequency,
  ) async {
    try {
      await _prefs?.setInt(
        '$_keyNotificationFrequency$campgroundId',
        frequency.index,
      );
      debugPrint('🔔 Set notification frequency for $campgroundId: $frequency');
    } catch (e) {
      debugPrint('❌ Error setting notification frequency: $e');
    }
  }

  /// Get notification frequency for a campground
  NotificationFrequency getNotificationFrequency(String campgroundId) {
    final index =
        _prefs?.getInt('$_keyNotificationFrequency$campgroundId') ?? 1;
    return NotificationFrequency.values[index.clamp(
      0,
      NotificationFrequency.values.length - 1,
    )];
  }

  /// Get last sync timestamp
  DateTime? getLastSyncTimestamp() {
    final timestamp = _prefs?.getInt(_keyPreferenceSync);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Clear all preferences (for logout/reset)
  Future<void> clearAllPreferences() async {
    try {
      await _prefs?.clear();
      _cachedPreference = null;
      debugPrint('🗑️ Cleared all user preferences');
    } catch (e) {
      debugPrint('❌ Error clearing preferences: $e');
    }
  }

  /// Export preferences for backup/sync
  Future<Map<String, dynamic>> exportPreferences() async {
    final export = <String, dynamic>{};

    try {
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        final value = _prefs?.get(key);
        export[key] = value;
      }

      export['export_timestamp'] = DateTime.now().millisecondsSinceEpoch;
      debugPrint('📤 Exported ${export.length} preferences');
    } catch (e) {
      debugPrint('❌ Error exporting preferences: $e');
    }

    return export;
  }

  /// Import preferences from backup/sync
  Future<void> importPreferences(Map<String, dynamic> preferences) async {
    try {
      for (final entry in preferences.entries) {
        if (entry.key == 'export_timestamp') continue;

        final value = entry.value;
        if (value is String) {
          await _prefs?.setString(entry.key, value);
        } else if (value is int) {
          await _prefs?.setInt(entry.key, value);
        } else if (value is double) {
          await _prefs?.setDouble(entry.key, value);
        } else if (value is bool) {
          await _prefs?.setBool(entry.key, value);
        } else if (value is List<String>) {
          await _prefs?.setStringList(entry.key, value);
        }
      }

      await _loadCachedPreference();
      await _prefs?.setInt(
        _keyPreferenceSync,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('📥 Imported ${preferences.length} preferences');
    } catch (e) {
      debugPrint('❌ Error importing preferences: $e');
    }
  }
}

/// Data class for campsite interaction history
class CampsiteHistoryEntry {
  final String campsiteId;
  final String campgroundId;
  final String siteNumber;
  final DateTime viewedAt;
  final String action; // 'viewed', 'monitored', 'reserved'
  final Map<String, dynamic> metadata;

  const CampsiteHistoryEntry({
    required this.campsiteId,
    required this.campgroundId,
    required this.siteNumber,
    required this.viewedAt,
    required this.action,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'campsiteId': campsiteId,
    'campgroundId': campgroundId,
    'siteNumber': siteNumber,
    'viewedAt': viewedAt.millisecondsSinceEpoch,
    'action': action,
    'metadata': metadata,
  };

  factory CampsiteHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CampsiteHistoryEntry(
      campsiteId: json['campsiteId'] as String,
      campgroundId: json['campgroundId'] as String,
      siteNumber: json['siteNumber'] as String,
      viewedAt: DateTime.fromMillisecondsSinceEpoch(json['viewedAt'] as int),
      action: json['action'] as String,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }
}

/// Data class for budget settings
class BudgetSettings {
  final double maxPricePerNight;
  final double maxTotalBudget;
  final bool enableBudgetAlerts;
  final bool trackSpending;
  final double alertThreshold; // Percentage (0.0 - 1.0)

  const BudgetSettings({
    required this.maxPricePerNight,
    required this.maxTotalBudget,
    required this.enableBudgetAlerts,
    required this.trackSpending,
    required this.alertThreshold,
  });

  factory BudgetSettings.defaultSettings() => const BudgetSettings(
    maxPricePerNight: 75.0,
    maxTotalBudget: 500.0,
    enableBudgetAlerts: true,
    trackSpending: true,
    alertThreshold: 0.8, // 80%
  );

  Map<String, dynamic> toJson() => {
    'maxPricePerNight': maxPricePerNight,
    'maxTotalBudget': maxTotalBudget,
    'enableBudgetAlerts': enableBudgetAlerts,
    'trackSpending': trackSpending,
    'alertThreshold': alertThreshold,
  };

  factory BudgetSettings.fromJson(Map<String, dynamic> json) {
    return BudgetSettings(
      maxPricePerNight: (json['maxPricePerNight'] as num).toDouble(),
      maxTotalBudget: (json['maxTotalBudget'] as num).toDouble(),
      enableBudgetAlerts: json['enableBudgetAlerts'] as bool,
      trackSpending: json['trackSpending'] as bool,
      alertThreshold: (json['alertThreshold'] as num).toDouble(),
    );
  }
}

/// Data class for rate limiting settings
class RateLimitSettings {
  final int maxChecksPerHour;
  final int maxNotificationsPerDay;
  final bool respectQuietHours;
  final bool enableRateLimiting;

  const RateLimitSettings({
    required this.maxChecksPerHour,
    required this.maxNotificationsPerDay,
    required this.respectQuietHours,
    required this.enableRateLimiting,
  });

  factory RateLimitSettings.defaultSettings() => const RateLimitSettings(
    maxChecksPerHour: 6, // Every 10 minutes max
    maxNotificationsPerDay: 20,
    respectQuietHours: true,
    enableRateLimiting: true,
  );

  Map<String, dynamic> toJson() => {
    'maxChecksPerHour': maxChecksPerHour,
    'maxNotificationsPerDay': maxNotificationsPerDay,
    'respectQuietHours': respectQuietHours,
    'enableRateLimiting': enableRateLimiting,
  };

  factory RateLimitSettings.fromJson(Map<String, dynamic> json) {
    return RateLimitSettings(
      maxChecksPerHour: json['maxChecksPerHour'] as int,
      maxNotificationsPerDay: json['maxNotificationsPerDay'] as int,
      respectQuietHours: json['respectQuietHours'] as bool,
      enableRateLimiting: json['enableRateLimiting'] as bool,
    );
  }
}

/// Enum for notification frequency settings
enum NotificationFrequency {
  never,
  low, // Once per day max
  normal, // Few times per day
  high, // Multiple times per day
  instant, // Immediate notifications
}

extension NotificationFrequencyExtension on NotificationFrequency {
  String get displayName {
    switch (this) {
      case NotificationFrequency.never:
        return 'Never';
      case NotificationFrequency.low:
        return 'Low (Daily)';
      case NotificationFrequency.normal:
        return 'Normal';
      case NotificationFrequency.high:
        return 'High';
      case NotificationFrequency.instant:
        return 'Instant';
    }
  }

  String get description {
    switch (this) {
      case NotificationFrequency.never:
        return 'No notifications';
      case NotificationFrequency.low:
        return 'Maximum once per day';
      case NotificationFrequency.normal:
        return 'Few times per day';
      case NotificationFrequency.high:
        return 'Multiple notifications daily';
      case NotificationFrequency.instant:
        return 'Immediate notifications';
    }
  }
}
