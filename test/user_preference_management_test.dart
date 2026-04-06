import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sitebook_flutter/shared/services/user_preference_service.dart';
import 'package:sitebook_flutter/shared/services/campground_preference_service.dart';
import 'package:sitebook_flutter/shared/models/user_preference.dart';

void main() {
  group('User Preference Management Tests', () {
    late UserPreferenceService userPreferenceService;
    late CampgroundPreferenceService campgroundPreferenceService;

    setUp(() async {
      // Clear SharedPreferences mock for each test to avoid state bleed
      SharedPreferences.setMockInitialValues({});
      userPreferenceService = UserPreferenceService();
      campgroundPreferenceService = CampgroundPreferenceService();

      await userPreferenceService.initialize();
      await campgroundPreferenceService.initialize();
    });

    tearDown(() async {
      // Extra cleanup to ensure no state bleed
      await userPreferenceService.clearAllPreferences();
    });

    group('UserPreferenceService Tests', () {
      test('should initialize without crashing', () async {
        expect(userPreferenceService, isNotNull);
        expect(campgroundPreferenceService, isNotNull);
      });

      test('should get user preference with proper structure', () async {
        final userPreference = await userPreferenceService.getUserPreference();

        expect(userPreference, isNotNull);
        expect(userPreference.id, isNotEmpty);
        expect(userPreference.notificationsEnabled, isA<bool>());
        expect(userPreference.preferredAmenities, isA<List<String>>());
      });

      test('should save and retrieve user preferences', () async {
        final originalUserPreference = await userPreferenceService
            .getUserPreference();

        final updatedUserPreference = originalUserPreference.copyWith(
          firstName: 'Test',
          lastName: 'User',
          email: 'test@example.com',
          preferredState: 'California',
          maxDistance: 100.0,
          notificationsEnabled: false,
          maxBudget: 500.0,
        );

        await userPreferenceService.saveUserPreference(updatedUserPreference);
        final retrievedPreference = await userPreferenceService
            .getUserPreference();

        expect(retrievedPreference.firstName, equals('Test'));
        expect(retrievedPreference.lastName, equals('User'));
        expect(retrievedPreference.email, equals('test@example.com'));
        expect(retrievedPreference.preferredState, equals('California'));
        expect(retrievedPreference.maxDistance, equals(100.0));
        expect(retrievedPreference.notificationsEnabled, isFalse);
        expect(retrievedPreference.maxBudget, equals(500.0));
      });

      test('should handle budget settings', () async {
        const budgetSettings = BudgetSettings(
          maxPricePerNight: 85.0,
          maxTotalBudget: 600.0,
          enableBudgetAlerts: false,
          trackSpending: true,
          alertThreshold: 0.75,
        );

        await userPreferenceService.saveBudgetSettings(budgetSettings);
        final retrievedSettings = await userPreferenceService
            .getBudgetSettings();

        expect(retrievedSettings.maxPricePerNight, equals(85.0));
        expect(retrievedSettings.maxTotalBudget, equals(600.0));
        expect(retrievedSettings.enableBudgetAlerts, isFalse);
        expect(retrievedSettings.trackSpending, isTrue);
        expect(retrievedSettings.alertThreshold, equals(0.75));
      });

      test('should handle rate limit settings', () async {
        const rateLimitSettings = RateLimitSettings(
          maxChecksPerHour: 8,
          maxNotificationsPerDay: 15,
          respectQuietHours: false,
          enableRateLimiting: true,
        );

        await userPreferenceService.saveRateLimitSettings(rateLimitSettings);
        final retrievedSettings = await userPreferenceService
            .getRateLimitSettings();

        expect(retrievedSettings.maxChecksPerHour, equals(8));
        expect(retrievedSettings.maxNotificationsPerDay, equals(15));
        expect(retrievedSettings.respectQuietHours, isFalse);
        expect(retrievedSettings.enableRateLimiting, isTrue);
      });

      test('should manage notification frequency settings', () async {
        await userPreferenceService.setNotificationFrequency(
          'unique_test_campground',
          NotificationFrequency.high,
        );

        final frequency = userPreferenceService.getNotificationFrequency(
          'unique_test_campground',
        );
        expect(frequency, equals(NotificationFrequency.high));

        final defaultFrequency = userPreferenceService.getNotificationFrequency(
          'unknown_campground',
        );
        expect(defaultFrequency, equals(NotificationFrequency.normal));
      });

      test('should manage favorite campgrounds', () async {
        await userPreferenceService.addFavoriteCampground('campground_123');

        expect(
          userPreferenceService.isCampgroundFavorite('campground_123'),
          isTrue,
        );
        expect(
          userPreferenceService.getFavoriteCampgrounds(),
          contains('campground_123'),
        );

        await userPreferenceService.removeFavoriteCampground('campground_123');
        expect(
          userPreferenceService.isCampgroundFavorite('campground_123'),
          isFalse,
        );
      });

      test('should manage recent searches', () async {
        await userPreferenceService.saveRecentSearch('Yosemite');
        await userPreferenceService.saveRecentSearch('Grand Canyon');

        final searches = userPreferenceService.getRecentSearches();
        expect(searches, contains('Yosemite'));
        expect(searches, contains('Grand Canyon'));

        await userPreferenceService.clearRecentSearches();
        final clearedSearches = userPreferenceService.getRecentSearches();
        expect(clearedSearches, isEmpty);
      });

      test('should handle campsite history', () async {
        final historyEntry = CampsiteHistoryEntry(
          campsiteId: 'site_001',
          campgroundId: 'campground_001',
          siteNumber: 'A-15',
          viewedAt: DateTime.now(),
          action: 'viewed',
        );

        await userPreferenceService.saveCampsiteHistory(
          'campground_001',
          historyEntry,
        );
        final history = userPreferenceService.getCampsiteHistory(
          'campground_001',
        );

        expect(history, isNotEmpty);
        expect(history.first.campsiteId, equals('site_001'));
        expect(history.first.siteNumber, equals('A-15'));
      });

      test('should export and import preferences', () async {
        // Set some preferences
        await userPreferenceService.addFavoriteCampground(
          'export_test_campground',
        );
        await userPreferenceService.setNotificationFrequency(
          'export_test_campground',
          NotificationFrequency.low,
        );

        // Export
        final exportedData = await userPreferenceService.exportPreferences();
        expect(exportedData, isNotNull);

        // Clear and verify cleared
        await userPreferenceService.clearAllPreferences();
        expect(userPreferenceService.getFavoriteCampgrounds(), isEmpty);

        // Import and verify restored
        await userPreferenceService.importPreferences(exportedData);
        expect(
          userPreferenceService.getFavoriteCampgrounds(),
          contains('export_test_campground'),
        );
        expect(
          userPreferenceService.getNotificationFrequency(
            'export_test_campground',
          ),
          equals(NotificationFrequency.low),
        );
      });
    });

    group('CampgroundPreferenceService Tests', () {
      test('should handle campground-specific preferences', () async {
        final preferences = CampgroundSpecificPreferences(
          campgroundId: 'test_campground',
          preferredSiteNumbers: ['A-15', 'B-22'],
          maxNotificationsPerDay: 10,
          respectQuietHours: true,
          customQuietHourStart: 22,
          customQuietHourEnd: 8,
          lastUpdated: DateTime.now(),
        );

        await campgroundPreferenceService.saveCampgroundPreferences(
          'test_campground',
          preferences,
        );
        final retrieved = await campgroundPreferenceService
            .getCampgroundPreferences('test_campground');

        expect(retrieved.preferredSiteNumbers, equals(['A-15', 'B-22']));
        expect(retrieved.maxNotificationsPerDay, equals(10));
        expect(retrieved.respectQuietHours, isTrue);
        expect(retrieved.customQuietHourStart, equals(22));
        expect(retrieved.customQuietHourEnd, equals(8));
      });

      test('should handle global site preferences', () async {
        final globalPreferences = GlobalSitePreferences(
          preferredSiteTypes: ['Electric', 'Water/Electric'],
          requireAccessibility: true,
          maxPricePerNight: 75.0,
          enableSmartDefaults: false,
          lastUpdated: DateTime.now(),
        );

        await campgroundPreferenceService.saveGlobalSitePreferences(
          globalPreferences,
        );
        final retrieved = await campgroundPreferenceService
            .getGlobalSitePreferences();

        expect(
          retrieved.preferredSiteTypes,
          equals(['Electric', 'Water/Electric']),
        );
        expect(retrieved.requireAccessibility, isTrue);
        expect(retrieved.maxPricePerNight, equals(75.0));
        expect(retrieved.enableSmartDefaults, isFalse);
      });

      test('should handle device sync settings', () async {
        const syncSettings = DeviceSyncSettings(
          enableAutoSync: false,
          syncIntervalHours: 12,
          syncOverWifiOnly: true,
          syncPreferences: true,
          syncHistory: false,
          syncFavorites: true,
          cloudProvider: 'test',
        );

        await campgroundPreferenceService.configureDeviceSync(syncSettings);
        final retrieved = await campgroundPreferenceService
            .getDeviceSyncSettings();

        expect(retrieved.enableAutoSync, isFalse);
        expect(retrieved.syncIntervalHours, equals(12));
        expect(retrieved.syncOverWifiOnly, isTrue);
      });

      test('should perform device sync without errors', () async {
        // This should not throw
        await campgroundPreferenceService.performDeviceSync();

        // Check sync timestamp is set
        final lastSync = campgroundPreferenceService.getLastFullSyncTimestamp();
        expect(lastSync, isNotNull);
      });

      test('should detect sync needs correctly', () async {
        // Initially should need sync
        var needsSync = await campgroundPreferenceService.isSyncNeeded();
        expect(needsSync, isTrue);

        // After sync, should not need sync
        await campgroundPreferenceService.performDeviceSync();
        needsSync = await campgroundPreferenceService.isSyncNeeded();
        expect(needsSync, isFalse);
      });

      test('should manage multiple campground preferences', () async {
        final prefs1 = CampgroundSpecificPreferences.defaultSettings(
          'campground_1',
        );
        final prefs2 = CampgroundSpecificPreferences.defaultSettings(
          'campground_2',
        );

        await campgroundPreferenceService.saveCampgroundPreferences(
          'campground_1',
          prefs1,
        );
        await campgroundPreferenceService.saveCampgroundPreferences(
          'campground_2',
          prefs2,
        );

        final allPrefs = await campgroundPreferenceService
            .getAllCampgroundPreferences();
        expect(allPrefs.length, equals(2));
        expect(allPrefs.containsKey('campground_1'), isTrue);
        expect(allPrefs.containsKey('campground_2'), isTrue);

        // Test clearing
        await campgroundPreferenceService.clearAllCampgroundPreferences();
        final clearedPrefs = await campgroundPreferenceService
            .getAllCampgroundPreferences();
        expect(clearedPrefs, isEmpty);
      });
    });

    group('Data Serialization Tests', () {
      test('CampgroundSpecificPreferences serialization', () {
        final original = CampgroundSpecificPreferences(
          campgroundId: 'test_id',
          preferredSiteNumbers: ['A-1', 'B-2'],
          maxNotificationsPerDay: 5,
          respectQuietHours: true,
          customQuietHourStart: 22,
          customQuietHourEnd: 7,
          lastUpdated: DateTime(2024, 1, 1, 12, 0),
        );

        final json = original.toJson();
        final deserialized = CampgroundSpecificPreferences.fromJson(json);

        expect(deserialized.campgroundId, equals(original.campgroundId));
        expect(
          deserialized.preferredSiteNumbers,
          equals(original.preferredSiteNumbers),
        );
        expect(
          deserialized.maxNotificationsPerDay,
          equals(original.maxNotificationsPerDay),
        );
      });

      test('GlobalSitePreferences serialization', () {
        final original = GlobalSitePreferences(
          preferredSiteTypes: ['Electric'],
          requireAccessibility: false,
          maxPricePerNight: 50.0,
          enableSmartDefaults: true,
          lastUpdated: DateTime(2024, 1, 1, 12, 0),
        );

        final json = original.toJson();
        final deserialized = GlobalSitePreferences.fromJson(json);

        expect(
          deserialized.preferredSiteTypes,
          equals(original.preferredSiteTypes),
        );
        expect(
          deserialized.requireAccessibility,
          equals(original.requireAccessibility),
        );
        expect(
          deserialized.maxPricePerNight,
          equals(original.maxPricePerNight),
        );
      });
    });
  });
}
