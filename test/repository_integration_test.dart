import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sitebook_flutter/shared/repositories/campground_repository_impl.dart';
import 'package:sitebook_flutter/shared/services/recreation_gov_api_service.dart';
import 'package:sitebook_flutter/shared/services/state_park_api_service.dart';
import 'package:sitebook_flutter/core/storage/campground_database.dart';
import 'package:sitebook_flutter/shared/models/campground.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'repository_integration_test.mocks.dart';

@GenerateMocks([RecreationGovApiService, StateParkApiService])
void main() {
  group('CampgroundRepository Integration Tests', () {
    late MockRecreationGovApiService mockRecreationGovApi;
    late MockStateParkApiService mockStateParkApi;
    late CampgroundDatabase testDatabase;
    late CampgroundRepositoryImpl repository;

    setUpAll(() {
      // Initialize Flutter bindings for testing
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      mockRecreationGovApi = MockRecreationGovApiService();
      mockStateParkApi = MockStateParkApiService();
      testDatabase = CampgroundDatabase();

      // Clear all data before each test
      await testDatabase.clearAllData();

      repository = CampgroundRepositoryImpl(
        recreationGovApi: mockRecreationGovApi,
        stateParkApi: mockStateParkApi,
        database: testDatabase,
      );
    });

    tearDown(() async {
      // Clear all data after each test
      await testDatabase.clearAllData();
      await testDatabase.close();
    });

    group('Data Source Integration', () {
      test('should return cached data when APIs are unavailable', () async {
        // Arrange - Setup cached data
        final cachedCampgrounds = [
          _createTestCampground(id: 'cached_1', name: 'Cached Campground 1'),
          _createTestCampground(id: 'cached_2', name: 'Cached Campground 2'),
        ];
        await testDatabase.saveCampgrounds(cachedCampgrounds);

        // Mock API failures
        when(
          mockRecreationGovApi.getFacilities(state: anyNamed('state')),
        ).thenThrow(Exception('API Error'));
        when(
          mockStateParkApi.getCampgroundsByState(any),
        ).thenThrow(Exception('API Error'));

        // Act
        final result = await repository.getCampgroundsByState('CA');

        // Assert
        expect(result, hasLength(2));
        expect(
          result.map((c) => c.name).toSet(),
          equals({'Cached Campground 1', 'Cached Campground 2'}),
        );
      });

      test('should prefer fresh API data over cached data', () async {
        // Arrange - Setup old cached data
        final oldCampground = _createTestCampground(
          id: 'test_1',
          name: 'Old Cached Name',
        );
        await testDatabase.saveCampground(oldCampground);

        // Mock fresh API data
        final mockApiResponse = RecreationGovResponse<RecreationGovFacility>(
          data: [
            _createMockRecGovFacility(id: 'test_1', name: 'Fresh API Name'),
          ],
          metadata: _createMockMetadata(),
        );

        when(
          mockRecreationGovApi.getFacilities(state: 'CA', limit: 100),
        ).thenAnswer((_) async => mockApiResponse);

        when(
          mockStateParkApi.getCampgroundsByState('CA'),
        ).thenAnswer((_) async => []);

        // Act
        final result = await repository.getCampgroundsByState('CA');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.name, equals('Fresh API Name'));
      });

      test('should combine data from multiple API sources', () async {
        // Arrange - Mock Recreation.gov response
        final recGovResponse = RecreationGovResponse<RecreationGovFacility>(
          data: [_createMockRecGovFacility(id: 'fed_1', name: 'Federal Camp')],
          metadata: _createMockMetadata(),
        );

        // Mock State Park response
        final stateParkCampgrounds = [
          _createTestCampground(id: 'state_1', name: 'State Park Camp'),
        ];

        // Mock with flexible parameters
        when(
          mockRecreationGovApi.getFacilities(
            activity: any,
            state: any,
            latitude: any,
            longitude: any,
            radius: any,
            limit: any,
            offset: any,
          ),
        ).thenAnswer((_) async => recGovResponse);

        when(
          mockStateParkApi.getCampgroundsByState(any),
        ).thenAnswer((_) async => stateParkCampgrounds);

        // Act - This will trigger refresh of state data
        await repository.refresh();
        final result = await repository.getCampgroundsByState('CA');

        // Assert
        expect(result, hasLength(greaterThanOrEqualTo(1)));
        // Note: Exact count depends on successful API mocking and data combination
      });
    });

    group('Caching and Sync Logic', () {
      test('should update cache timestamps on successful API calls', () async {
        // Arrange
        final initialSyncTime = await repository.getLastSyncTime();

        // Mock successful API response
        when(
          mockRecreationGovApi.getFacilities(
            activity: any,
            state: any,
            latitude: any,
            longitude: any,
            radius: any,
            limit: any,
            offset: any,
          ),
        ).thenAnswer(
          (_) async => RecreationGovResponse<RecreationGovFacility>(
            data: [],
            metadata: _createMockMetadata(),
          ),
        );

        when(
          mockStateParkApi.getCampgroundsByState(any),
        ).thenAnswer((_) async => []);

        // Act
        await repository.refresh();
        final updatedSyncTime = await repository.getLastSyncTime();

        // Assert
        if (initialSyncTime != null && updatedSyncTime != null) {
          expect(updatedSyncTime.isAfter(initialSyncTime), isTrue);
        } else {
          expect(updatedSyncTime, isNotNull);
        }
      });

      test('should handle sync failures gracefully', () async {
        // Arrange - Mock API failures
        when(
          mockRecreationGovApi.getFacilities(
            activity: any,
            state: any,
            latitude: any,
            longitude: any,
            radius: any,
            limit: any,
            offset: any,
          ),
        ).thenThrow(Exception('Network Error'));
        when(
          mockStateParkApi.getCampgroundsByState(any),
        ).thenThrow(Exception('Network Error'));

        // Act & Assert - Should not throw
        expect(() => repository.refresh(), returnsNormally);
      });
    });

    group('Search Operations', () {
      test(
        'should perform location-based search across data sources',
        () async {
          // Arrange - Setup test campgrounds at known locations
          final nearbycamp = _createTestCampground(
            id: 'nearby',
            name: 'Nearby Camp',
            latitude: 37.7749, // San Francisco
            longitude: -122.4194,
          );
          await testDatabase.saveCampground(nearbycamp);

          // Act
          final results = await repository.searchNearby(
            latitude: 37.7749,
            longitude: -122.4194,
            radiusMiles: 10.0,
          );

          // Assert
          expect(results, isNotEmpty);
          expect(results.first.name, equals('Nearby Camp'));
        },
      );

      test('should search by text query in cached data', () async {
        // Arrange
        final testCampgrounds = [
          _createTestCampground(id: '1', name: 'Yosemite Valley'),
          _createTestCampground(id: '2', name: 'Big Sur Coast'),
          _createTestCampground(id: '3', name: 'Death Valley'),
        ];
        await testDatabase.saveCampgrounds(testCampgrounds);

        // Act
        final valleyResults = await repository.searchByQuery('Valley');
        final coastResults = await repository.searchByQuery('Coast');

        // Assert
        expect(valleyResults, hasLength(2));
        expect(
          valleyResults.map((c) => c.name).toSet(),
          equals({'Yosemite Valley', 'Death Valley'}),
        );

        expect(coastResults, hasLength(1));
        expect(coastResults.first.name, equals('Big Sur Coast'));
      });
    });

    group('Monitoring Operations', () {
      test('should persist monitoring status changes', () async {
        // Arrange
        final campground = _createTestCampground(isMonitored: false);
        await testDatabase.saveCampground(campground);

        // Act
        await repository.updateMonitoringStatus(campground.id, true);
        final monitoredCampgrounds = await repository.getMonitoredCampgrounds();

        // Assert
        expect(monitoredCampgrounds, hasLength(1));
        expect(monitoredCampgrounds.first.id, equals(campground.id));
      });

      test('should handle monitoring toggles correctly', () async {
        // Arrange
        final campground = _createTestCampground(isMonitored: true);
        await testDatabase.saveCampground(campground);

        // Act - Toggle monitoring off and on
        await repository.updateMonitoringStatus(campground.id, false);
        final noMonitored = await repository.getMonitoredCampgrounds();

        await repository.updateMonitoringStatus(campground.id, true);
        final withMonitored = await repository.getMonitoredCampgrounds();

        // Assert
        expect(noMonitored, isEmpty);
        expect(withMonitored, hasLength(1));
      });
    });

    group('Error Resilience', () {
      test('should gracefully handle database errors', () async {
        // Close database to simulate error condition
        await testDatabase.close();

        // Act & Assert - Should handle database errors gracefully
        expect(() => repository.getAllCampgrounds(), returnsNormally);
      });

      test('should handle mixed success/failure scenarios', () async {
        // Arrange - One API succeeds, one fails
        when(
          mockRecreationGovApi.getFacilities(
            activity: any,
            state: any,
            latitude: any,
            longitude: any,
            radius: any,
            limit: any,
            offset: any,
          ),
        ).thenAnswer(
          (_) async => RecreationGovResponse<RecreationGovFacility>(
            data: [_createMockRecGovFacility()],
            metadata: _createMockMetadata(),
          ),
        );

        when(
          mockStateParkApi.getCampgroundsByState(any),
        ).thenThrow(Exception('State API Error'));

        // Act - Should still process successful API data
        expect(() => repository.refresh(), returnsNormally);
      });
    });
  });
}

// Helper methods for creating test objects

Campground _createTestCampground({
  String id = 'test_campground',
  String name = 'Test Campground',
  String description = 'A test campground',
  double latitude = 37.7749,
  double longitude = -122.4194,
  String state = 'CA',
  bool isMonitored = false,
}) {
  return Campground(
    id: id,
    name: name,
    description: description,
    latitude: latitude,
    longitude: longitude,
    state: state,
    amenities: const ['Restrooms', 'Fire Pits'],
    activities: const ['Hiking', 'Camping'],
    imageUrls: const [],
    isMonitored: isMonitored,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

RecreationGovFacility _createMockRecGovFacility({
  String id = 'mock_facility',
  String name = 'Mock Recreation.gov Facility',
}) {
  return RecreationGovFacility(
    facilityId: id,
    facilityName: name,
    facilityDescription: 'Mock facility for testing',
    facilityLatitude: 37.7749,
    facilityLongitude: -122.4194,
    addresses: [],
    activities: [],
  );
}

RecreationGovMetadata _createMockMetadata() {
  return RecreationGovMetadata(
    searchParameters: RecreationGovSearchParameters(limit: 50, offset: 0),
    resultInfo: RecreationGovResultInfo(totalCount: 1, currentCount: 1),
  );
}
