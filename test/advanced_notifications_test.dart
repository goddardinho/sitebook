import 'package:flutter_test/flutter_test.dart';
import 'package:sitebook_flutter/shared/services/advanced_notification_service.dart';
import 'package:sitebook_flutter/shared/services/availability_change_detection_service.dart';
import 'package:sitebook_flutter/shared/models/campground.dart';
import 'package:sitebook_flutter/shared/models/campsite.dart';
import 'package:sitebook_flutter/shared/models/campsite_monitoring_settings.dart';

void main() {
  group('Advanced Notification Service', () {
    late Campground testCampground;
    late List<Campsite> testSites;
    late CampsiteMonitoringSettings testSettings;

    setUpAll(() async {
      // Initialize the service
      await AdvancedNotificationService.initialize();
    });

    setUp(() {
      // Set up test data
      testCampground = const Campground(
        id: 'test_campground_001',
        name: 'Advanced Notifications Test Campground',
        description: 'Test campground for advanced notifications',
        latitude: 37.7749,
        longitude: -122.4194,
        state: 'CA',
        parkName: 'Test National Park',
        amenities: ['Restrooms', 'Potable Water'],
        activities: ['Hiking', 'Wildlife Viewing'],
        imageUrls: [],
        isMonitored: true,
      );

      testSites = [
        Campsite(
          id: 'test_site_001',
          campgroundId: testCampground.id,
          siteNumber: '015',
          siteType: 'Electric',
          maxOccupancy: 6,
          accessibility: true,
          amenities: ['Fire Ring', 'Picnic Table', 'Electric Hookup'],
          pricePerNight: 45.00,
          isAvailable: true,
          nextAvailableDate: DateTime.now().add(const Duration(days: 3)),
          monitoringCount: 3,
        ),
        Campsite(
          id: 'test_site_002',
          campgroundId: testCampground.id,
          siteNumber: '023',
          siteType: 'Standard',
          maxOccupancy: 4,
          accessibility: false,
          amenities: ['Fire Ring', 'Picnic Table'],
          pricePerNight: 35.00,
          isAvailable: true,
          nextAvailableDate: DateTime.now().add(const Duration(days: 5)),
          monitoringCount: 1,
        ),
      ];

      testSettings = CampsiteMonitoringSettings(
        id: 'test_monitoring_001',
        campgroundId: testCampground.id,
        userId: 'test_user',
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        guestCount: 4,
        sitePreference: SitePreference.specificSites,
        preferredSiteNumbers: ['015', '023'],
        maxPricePerNight: 50.00,
        alertOnPriceDrops: true,
        priority: MonitoringPriority.high,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );
    });

    test('should send site-specific notification without errors', () async {
      // Act & Assert - Should not throw
      await expectLater(
        AdvancedNotificationService.sendSiteSpecificNotification(
          campground: testCampground,
          availableSites: testSites,
          settings: testSettings,
        ),
        completes,
      );
    });

    test('should send price drop alert without errors', () async {
      // Act & Assert - Should not throw
      await expectLater(
        AdvancedNotificationService.sendPriceDropAlert(
          campground: testCampground,
          campsite: testSites.first,
          previousPrice: 65.00,
          currentPrice: 45.00,
          settings: testSettings,
        ),
        completes,
      );
    });

    test('should send alternative sites notification without errors', () async {
      // Arrange
      final alternatives = [
        AlternativeSiteSuggestion(
          campground: testCampground.copyWith(
            id: 'alternative_001',
            name: 'Alternative Test Campground',
          ),
          availableSites: testSites,
          distanceMiles: 15.2,
          reason: 'Similar amenities in nearby location',
        ),
      ];

      // Act & Assert - Should not throw
      await expectLater(
        AdvancedNotificationService.sendAlternativeSitesNotification(
          primaryCampground: testCampground,
          alternatives: alternatives,
          settings: testSettings,
        ),
        completes,
      );
    });

    test('should send enhanced details notification without errors', () async {
      // Act & Assert - Should not throw
      await expectLater(
        AdvancedNotificationService.sendEnhancedDetailsNotification(
          campground: testCampground,
          campsite: testSites.first,
          settings: testSettings,
          weatherInfo: {'summary': 'Sunny, 75°F'},
          crowdingInfo: {'level': 'Low'},
        ),
        completes,
      );
    });

    test('should handle service initialization correctly', () async {
      // Act & Assert - Should not throw and should complete
      await expectLater(AdvancedNotificationService.initialize(), completes);
    });

    test('should create alternative site suggestion correctly', () {
      // Arrange & Act
      final suggestion = AlternativeSiteSuggestion(
        campground: testCampground,
        availableSites: testSites,
        distanceMiles: 10.5,
        reason: 'Test reason',
      );

      // Assert
      expect(suggestion.campground.id, equals(testCampground.id));
      expect(suggestion.availableSites.length, equals(2));
      expect(suggestion.distanceMiles, equals(10.5));
      expect(suggestion.reason, equals('Test reason'));
    });
  });

  group('Availability Change Detection Service', () {
    late Campground testCampground;
    late List<Campsite> currentSites;
    late List<CampsiteMonitoringSettings> monitoring;

    setUp(() {
      testCampground = const Campground(
        id: 'detection_test_001',
        name: 'Detection Test Campground',
        description: 'Test campground for change detection',
        latitude: 37.7749,
        longitude: -122.4194,
        state: 'CA',
        amenities: [],
        activities: [],
        imageUrls: [],
      );

      currentSites = [
        Campsite(
          id: 'detection_site_001',
          campgroundId: testCampground.id,
          siteNumber: '001',
          siteType: 'Standard',
          maxOccupancy: 4,
          amenities: ['Fire Ring'],
          pricePerNight: 30.00,
          isAvailable: true,
          nextAvailableDate: DateTime.now().add(const Duration(days: 1)),
        ),
      ];

      monitoring = [
        CampsiteMonitoringSettings(
          id: 'detection_monitoring_001',
          campgroundId: testCampground.id,
          userId: 'test_user',
          startDate: DateTime.now().add(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 3)),
          guestCount: 2,
          maxPricePerNight: 40.00,
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('should process availability update without errors', () async {
      // Act & Assert - Should not throw
      await expectLater(
        AvailabilityChangeDetectionService.processAvailabilityUpdate(
          campground: testCampground,
          currentAvailability: currentSites,
          activeMonitoring: monitoring,
        ),
        completes,
      );
    });
  });
}
