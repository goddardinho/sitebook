import 'package:flutter_test/flutter_test.dart';
import 'package:sitebook_flutter/shared/models/campground.dart';
import 'package:sitebook_flutter/core/storage/campground_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('CampgroundDatabase Tests', () {
    late CampgroundDatabase database;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      database = CampgroundDatabase();
    });

    tearDown(() async {
      await database.close();
    });

    group('Basic CRUD Operations', () {
      test('should save and retrieve a campground', () async {
        // Arrange
        final campground = _createTestCampground();

        // Act
        await database.saveCampground(campground);
        final retrieved = await database.getCampgroundById(campground.id);

        // Assert
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(campground.id));
        expect(retrieved.name, equals(campground.name));
        expect(retrieved.latitude, equals(campground.latitude));
        expect(retrieved.longitude, equals(campground.longitude));
      });

      test('should save multiple campgrounds at once', () async {
        // Arrange
        final campgrounds = [
          _createTestCampground(id: '1', name: 'Campground 1'),
          _createTestCampground(id: '2', name: 'Campground 2'),
          _createTestCampground(id: '3', name: 'Campground 3'),
        ];

        // Act
        await database.saveCampgrounds(campgrounds);
        final allCampgrounds = await database.getAllCampgrounds();

        // Assert
        expect(allCampgrounds.length, equals(3));
        expect(
          allCampgrounds.map((c) => c.name).toSet(),
          equals({'Campground 1', 'Campground 2', 'Campground 3'}),
        );
      });

      test('should update existing campground on duplicate save', () async {
        // Arrange
        final original = _createTestCampground(name: 'Original Name');
        final updated = original.copyWith(name: 'Updated Name');

        // Act
        await database.saveCampground(original);
        await database.saveCampground(updated);
        final retrieved = await database.getCampgroundById(original.id);

        // Assert
        expect(retrieved!.name, equals('Updated Name'));
      });

      test('should delete campground', () async {
        // Arrange
        final campground = _createTestCampground();
        await database.saveCampground(campground);

        // Act
        await database.deleteCampground(campground.id);
        final retrieved = await database.getCampgroundById(campground.id);

        // Assert
        expect(retrieved, isNull);
      });
    });

    group('Search and Filtering', () {
      setUp(() async {
        // Setup test data
        final testCampgrounds = [
          _createTestCampground(
            id: '1',
            name: 'Yosemite Valley Campground',
            state: 'CA',
            parkName: 'Yosemite National Park',
            description: 'Beautiful valley setting with granite cliffs',
          ),
          _createTestCampground(
            id: '2',
            name: 'Big Bend River Camp',
            state: 'TX',
            parkName: 'Big Bend National Park',
            description: 'Desert campground along the Rio Grande',
          ),
          _createTestCampground(
            id: '3',
            name: 'California Beach Camp',
            state: 'CA',
            description: 'Oceanside camping with beach access',
          ),
        ];
        await database.saveCampgrounds(testCampgrounds);
      });

      test('should filter campgrounds by state', () async {
        // Act
        final caCampgrounds = await database.getCampgroundsByState('CA');
        final txCampgrounds = await database.getCampgroundsByState('TX');

        // Assert
        expect(caCampgrounds.length, equals(2));
        expect(txCampgrounds.length, equals(1));
        expect(caCampgrounds.every((c) => c.state == 'CA'), isTrue);
        expect(txCampgrounds.every((c) => c.state == 'TX'), isTrue);
      });

      test('should search campgrounds by text query', () async {
        // Act
        final yosemiteResults = await database.searchByQuery('Yosemite');
        final beachResults = await database.searchByQuery('beach');
        final desertResults = await database.searchByQuery('desert');

        // Assert
        expect(yosemiteResults.length, equals(1));
        expect(yosemiteResults.first.name, contains('Yosemite'));

        expect(beachResults.length, equals(1));
        expect(beachResults.first.description, contains('beach'));

        expect(desertResults.length, equals(1));
        expect(desertResults.first.description, contains('Desert'));
      });

      test('should return empty list for no matches', () async {
        // Act
        final results = await database.searchByQuery('nonexistent');

        // Assert
        expect(results, isEmpty);
      });
    });

    group('Location-Based Search', () {
      setUp(() async {
        // Setup campgrounds at known locations
        final testCampgrounds = [
          _createTestCampground(
            id: 'nearby',
            name: 'Nearby Camp',
            latitude: 37.7749, // San Francisco
            longitude: -122.4194,
          ),
          _createTestCampground(
            id: 'medium',
            name: 'Medium Distance Camp',
            latitude: 37.4419, // Palo Alto (~30 miles)
            longitude: -122.1430,
          ),
          _createTestCampground(
            id: 'far',
            name: 'Far Camp',
            latitude: 36.7378, // San Jose (~50 miles)
            longitude: -119.7871,
          ),
        ];
        await database.saveCampgrounds(testCampgrounds);
      });

      test('should find campgrounds within radius', () async {
        // Act - Search within 40 miles of San Francisco
        final results = await database.searchNearby(
          latitude: 37.7749,
          longitude: -122.4194,
          radiusMiles: 40.0,
        );

        // Assert
        expect(results.length, equals(2));
        expect(
          results.map((c) => c.name).toSet(),
          equals({'Nearby Camp', 'Medium Distance Camp'}),
        );
      });

      test('should sort results by distance', () async {
        // Act - Search from San Francisco
        final results = await database.searchNearby(
          latitude: 37.7749,
          longitude: -122.4194,
          radiusMiles: 100.0, // Include all campgrounds
        );

        // Assert - Results should be sorted by distance (closest first)
        expect(results.length, equals(3));
        expect(results.first.name, equals('Nearby Camp'));
        expect(results.last.name, equals('Far Camp'));
      });

      test('should filter by state within radius', () async {
        // Add out-of-state campground at similar distance
        await database.saveCampground(
          _createTestCampground(
            id: 'nevada',
            name: 'Nevada Camp',
            state: 'NV',
            latitude: 37.4419,
            longitude: -122.1430,
          ),
        );

        // Act - Search with state filter
        final results = await database.searchNearby(
          latitude: 37.7749,
          longitude: -122.4194,
          radiusMiles: 40.0,
          stateFilter: 'CA',
        );

        // Assert - Should only return CA campgrounds
        expect(results.every((c) => c.state == 'CA'), isTrue);
      });
    });

    group('Monitoring Features', () {
      test('should update and retrieve monitored campgrounds', () async {
        // Arrange
        final campgrounds = [
          _createTestCampground(
            id: '1',
            name: 'Regular Camp',
            isMonitored: false,
          ),
          _createTestCampground(
            id: '2',
            name: 'Monitored Camp',
            isMonitored: true,
          ),
        ];
        await database.saveCampgrounds(campgrounds);

        // Act - Update monitoring status
        await database.updateMonitoringStatus('1', true);
        await database.updateMonitoringStatus('2', false);

        final monitored = await database.getMonitoredCampgrounds();

        // Assert
        expect(monitored.length, equals(1));
        expect(monitored.first.id, equals('1'));
      });

      test('should get correct monitored count', () async {
        // Arrange
        final campgrounds = [
          _createTestCampground(id: '1', isMonitored: true),
          _createTestCampground(id: '2', isMonitored: true),
          _createTestCampground(id: '3', isMonitored: false),
        ];
        await database.saveCampgrounds(campgrounds);

        // Act
        final stats = await database.getStats();

        // Assert
        expect(stats['total'], equals(3));
        expect(stats['monitored'], equals(2));
      });
    });

    group('Database Management', () {
      test('should clear all campgrounds', () async {
        // Arrange
        final campgrounds = [
          _createTestCampground(id: '1'),
          _createTestCampground(id: '2'),
        ];
        await database.saveCampgrounds(campgrounds);

        // Act
        await database.clearCache();
        final remaining = await database.getAllCampgrounds();

        // Assert
        expect(remaining, isEmpty);
      });

      test('should handle database statistics', () async {
        // Arrange
        await database.saveCampgrounds([
          _createTestCampground(id: '1', isMonitored: true),
          _createTestCampground(id: '2', isMonitored: false),
        ]);

        // Act
        final stats = await database.getStats();

        // Assert
        expect(stats.containsKey('total'), isTrue);
        expect(stats.containsKey('monitored'), isTrue);
        expect(stats['total'], equals(2));
        expect(stats['monitored'], equals(1));
      });
    });
  });
}

/// Helper method to create test campgrounds
Campground _createTestCampground({
  String id = 'test_campground_1',
  String name = 'Test Campground',
  String description = 'A beautiful test campground',
  double latitude = 37.7749,
  double longitude = -122.4194,
  String state = 'CA',
  String? parkName,
  List<String> amenities = const ['Restrooms', 'Picnic Tables'],
  List<String> activities = const ['Hiking', 'Fishing'],
  List<String> imageUrls = const [],
  bool isMonitored = false,
}) {
  return Campground(
    id: id,
    name: name,
    description: description,
    latitude: latitude,
    longitude: longitude,
    state: state,
    parkName: parkName,
    amenities: amenities,
    activities: activities,
    imageUrls: imageUrls,
    isMonitored: isMonitored,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
