import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sitebook_flutter/shared/providers/campground_providers.dart';
import 'package:sitebook_flutter/shared/repositories/campground_repository.dart';
import 'package:sitebook_flutter/shared/models/campground.dart';

import 'provider_integration_test.mocks.dart';

@GenerateMocks([CampgroundRepository])
void main() {
  group('Campground Providers Integration Tests', () {
    late MockCampgroundRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockCampgroundRepository();
      container = ProviderContainer(
        overrides: [
          campgroundRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Basic Provider Functionality', () {
      test('should provide repository instance', () {
        // Act
        final repository = container.read(campgroundRepositoryProvider);

        // Assert
        expect(repository, equals(mockRepository));
      });

      test('should handle search query state changes', () {
        // Act
        final initialQuery = container.read(searchQueryProvider);
        container.read(searchQueryProvider.notifier).state = 'test query';
        final updatedQuery = container.read(searchQueryProvider);

        // Assert
        expect(initialQuery, equals(''));
        expect(updatedQuery, equals('test query'));
      });
    });

    group('Async Data Providers', () {
      test('should load all campgrounds successfully', () async {
        // Arrange
        final testCampgrounds = [
          _createTestCampground(id: '1', name: 'Camp 1'),
          _createTestCampground(id: '2', name: 'Camp 2'),
        ];
        when(mockRepository.getAllCampgrounds())
            .thenAnswer((_) async => testCampgrounds);

        // Act
        final asyncValue = await container.read(campgroundsProvider.future);

        // Assert
        expect(asyncValue, hasLength(2));
        expect(asyncValue.map((c) => c.name).toSet(),
            equals({'Camp 1', 'Camp 2'}));
        verify(mockRepository.getAllCampgrounds()).called(1);
      });

      test('should load campgrounds by state', () async {
        // Arrange
        final californiaCampgrounds = [
          _createTestCampground(id: 'ca1', name: 'CA Camp', state: 'CA'),
        ];
        when(mockRepository.getCampgroundsByState('CA'))
            .thenAnswer((_) async => californiaCampgrounds);

        // Act
        final asyncValue = await container.read(campgroundsByStateProvider('CA').future);

        // Assert
        expect(asyncValue, hasLength(1));
        expect(asyncValue.first.state, equals('CA'));
        verify(mockRepository.getCampgroundsByState('CA')).called(1);
      });

      test('should load monitored campgrounds', () async {
        // Arrange
        final monitoredCampgrounds = [
          _createTestCampground(id: 'm1', name: 'Monitored Camp', isMonitored: true),
        ];
        when(mockRepository.getMonitoredCampgrounds())
            .thenAnswer((_) async => monitoredCampgrounds);

        // Act
        final asyncValue = await container.read(monitoredCampgroundsProvider.future);

        // Assert
        expect(asyncValue, hasLength(1));
        expect(asyncValue.first.isMonitored, isTrue);
        verify(mockRepository.getMonitoredCampgrounds()).called(1);
      });

      test('should get monitored count', () async {
        // Arrange - Setup monitored campgrounds
        final monitoredCampgrounds = [
          _createTestCampground(id: 'm1', isMonitored: true),
          _createTestCampground(id: 'm2', isMonitored: true),
        ];
        when(mockRepository.getMonitoredCampgrounds())
            .thenAnswer((_) async => monitoredCampgrounds);

        // Act
        final count = await container.read(monitoredCountProvider.future);

        // Assert
        expect(count, equals(2));
      });
    });

    group('Search Functionality', () {
      test('should return all campgrounds when search query is empty', () async {
        // Arrange
        final allCampgrounds = [
          _createTestCampground(id: '1', name: 'All Camp 1'),
          _createTestCampground(id: '2', name: 'All Camp 2'),
        ];
        when(mockRepository.getAllCampgrounds())
            .thenAnswer((_) async => allCampgrounds);
        when(mockRepository.searchByQuery(any))
            .thenAnswer((_) async => []);

        // Ensure search query is empty
        container.read(searchQueryProvider.notifier).state = '';

        // Act
        final results = await container.read(searchResultsProvider.future);

        // Assert
        expect(results, hasLength(2));
        verify(mockRepository.getAllCampgrounds()).called(1);
        verifyNever(mockRepository.searchByQuery(any));
      });

      test('should search by query when query is not empty', () async {
        // Arrange
        final searchResults = [
          _createTestCampground(id: 'search1', name: 'Search Result'),
        ];
        when(mockRepository.searchByQuery('yosemite'))
            .thenAnswer((_) async => searchResults);

        // Set search query
        container.read(searchQueryProvider.notifier).state = 'yosemite';

        // Act
        final results = await container.read(searchResultsProvider.future);

        // Assert
        expect(results, hasLength(1));
        expect(results.first.name, equals('Search Result'));
        verify(mockRepository.searchByQuery('yosemite')).called(1);
        verifyNever(mockRepository.getAllCampgrounds());
      });

      test('should update search results when query changes', () async {
        // Arrange
        when(mockRepository.searchByQuery('query1'))
            .thenAnswer((_) async => [_createTestCampground(name: 'Result 1')]);
        when(mockRepository.searchByQuery('query2'))
            .thenAnswer((_) async => [_createTestCampground(name: 'Result 2')]);

        // Act - First search
        container.read(searchQueryProvider.notifier).state = 'query1';
        final results1 = await container.read(searchResultsProvider.future);

        // Act - Second search
        container.read(searchQueryProvider.notifier).state = 'query2';
        final results2 = await container.read(searchResultsProvider.future);

        // Assert
        expect(results1.first.name, equals('Result 1'));
        expect(results2.first.name, equals('Result 2'));
      });
    });

    group('Campground Details', () {
      test('should load campground details by ID', () async {
        // Arrange
        final testCampground = _createTestCampground(
          id: 'detail_test',
          name: 'Detail Test Camp',
        );
        when(mockRepository.getCampgroundById('detail_test'))
            .thenAnswer((_) async => testCampground);

        // Act
        final result = await container.read(
            campgroundDetailsProvider('detail_test').future);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('detail_test'));
        expect(result.name, equals('Detail Test Camp'));
        verify(mockRepository.getCampgroundById('detail_test')).called(1);
      });

      test('should return null for non-existent campground', () async {
        // Arrange
        when(mockRepository.getCampgroundById('nonexistent'))
            .thenAnswer((_) async => null);

        // Act
        final result = await container.read(
            campgroundDetailsProvider('nonexistent').future);

        // Assert
        expect(result, isNull);
        verify(mockRepository.getCampgroundById('nonexistent')).called(1);
      });
    });

    group('Location-Based Search', () {
      test('should search nearby campgrounds', () async {
        // Arrange
        final nearbyParams = NearbySearchParams(
          latitude: 37.7749,
          longitude: -122.4194,
          radiusMiles: 25.0,
          stateFilter: 'CA',
        );

        final nearbyResults = [
          _createTestCampground(
            id: 'nearby1',
            name: 'Nearby Camp',
            latitude: 37.7749,
            longitude: -122.4194,
          ),
        ];

        when(mockRepository.searchNearby(
          latitude: 37.7749,
          longitude: -122.4194,
          radiusMiles: 25.0,
          stateFilter: 'CA',
        )).thenAnswer((_) async => nearbyResults);

        // Act
        final results = await container.read(nearbySearchProvider(nearbyParams).future);

        // Assert
        expect(results, hasLength(1));
        expect(results.first.name, equals('Nearby Camp'));
        verify(mockRepository.searchNearby(
          latitude: 37.7749,
          longitude: -122.4194,
          radiusMiles: 25.0,
          stateFilter: 'CA',
        )).called(1);
      });
    });

    group('Availability Checking', () {
      test('should check campground availability', () async {
        // Arrange
        final availabilityParams = AvailabilityParams(
          campgroundId: 'test_camp',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 7),
        );

        final availabilityResult = {
          '2026-06-01': true,
          '2026-06-02': true,
          '2026-06-03': false,
          '2026-06-04': true,
        };

        when(mockRepository.checkAvailability(
          campgroundId: 'test_camp',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 7),
        )).thenAnswer((_) async => availabilityResult);

        // Act
        final result = await container.read(
            availabilityProvider(availabilityParams).future);

        // Assert
        expect(result, hasLength(4));
        expect(result['2026-06-01'], isTrue);
        expect(result['2026-06-03'], isFalse);
        verify(mockRepository.checkAvailability(
          campgroundId: 'test_camp',
          startDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 6, 7),
        )).called(1);
      });
    });

    group('Actions Provider', () {
      test('should provide campground actions instance', () {
        // Act
        final actions = container.read(campgroundActionsProvider);

        // Assert
        expect(actions, isNotNull);
        expect(actions, isA<CampgroundActions>());
      });

      test('should handle monitoring toggle action', () async {
        // Arrange
        when(mockRepository.updateMonitoringStatus('test_id', true))
            .thenAnswer((_) async {});

        // Act
        final actions = container.read(campgroundActionsProvider);
        await actions.toggleMonitoring('test_id', true);

        // Assert
        verify(mockRepository.updateMonitoringStatus('test_id', true)).called(1);
      });

      test('should update search query through actions', () {
        // Arrange
        final actions = container.read(campgroundActionsProvider);

        // Act
        actions.updateSearchQuery('new search');

        // Assert
        final currentQuery = container.read(searchQueryProvider);
        expect(currentQuery, equals('new search'));
      });
    });

    group('Error Handling', () {
      test('should handle repository errors in async providers', () async {
        // Arrange
        when(mockRepository.getAllCampgrounds())
            .thenThrow(Exception('Repository Error'));

        // Act & Assert
        expect(() => container.read(campgroundsProvider.future),
               throwsException);
      });

      test('should handle errors in action providers', () async {
        // Arrange
        when(mockRepository.updateMonitoringStatus(any, any))
            .thenThrow(Exception('Update Error'));

        // Act & Assert
        final actions = container.read(campgroundActionsProvider);
        expect(() => actions.toggleMonitoring('test_id', true),
               throwsException);
      });
    });

    group('Provider Caching and Invalidation', () {
      test('should cache provider results', () async {
        // Arrange
        final testCampgrounds = [_createTestCampground()];
        when(mockRepository.getAllCampgrounds())
            .thenAnswer((_) async => testCampgrounds);

        // Act - Read twice
        await container.read(campgroundsProvider.future);
        await container.read(campgroundsProvider.future);

        // Assert - Repository should be called only once due to caching
        verify(mockRepository.getAllCampgrounds()).called(1);
      });

      test('should refresh data when provider is invalidated', () async {
        // Arrange
        when(mockRepository.getAllCampgrounds())
            .thenAnswer((_) async => [_createTestCampground()]);

        // Act - Read, invalidate, read again
        await container.read(campgroundsProvider.future);
        container.invalidate(campgroundsProvider);
        await container.read(campgroundsProvider.future);

        // Assert - Repository should be called twice
        verify(mockRepository.getAllCampgrounds()).called(2);
      });
    });
  });
}

/// Helper method to create test campgrounds
Campground _createTestCampground({
  String id = 'test_campground',
  String name = 'Test Campground',
  String state = 'CA',
  double latitude = 37.7749,
  double longitude = -122.4194,
  bool isMonitored = false,
}) {
  return Campground(
    id: id,
    name: name,
    description: 'Test campground description',
    latitude: latitude,
    longitude: longitude,
    state: state,
    amenities: const ['Restrooms', 'Fire Pits'],
    activities: const ['Hiking', 'Fishing'],
    imageUrls: const [],
    isMonitored: isMonitored,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}