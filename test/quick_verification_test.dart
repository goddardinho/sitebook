import 'package:flutter_test/flutter_test.dart';
import 'package:sitebook_flutter/shared/models/campground.dart';
import 'package:sitebook_flutter/core/storage/campground_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Quick API integration verification test
/// Tests only the core database functionality without mocking
void main() {
  group('Quick API Integration Check', () {
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

    test('Core database operations work', () async {
      // Arrange
      final testCampground = Campground(
        id: 'test_campground_1',
        name: 'Test Valley Campground',
        description: 'A beautiful test campground in the mountains',
        latitude: 37.7749,
        longitude: -122.4194,
        state: 'CA',
        amenities: const ['Restrooms', 'Fire Pits', 'Picnic Tables'],
        activities: const ['Hiking', 'Fishing', 'Photography'],
        imageUrls: const [],
      );

      // Act - Save campground
      await database.saveCampground(testCampground);
      
      // Act - Retrieve campground
      final retrieved = await database.getCampgroundById('test_campground_1');
      
      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Test Valley Campground'));
      expect(retrieved.state, equals('CA'));
      expect(retrieved.amenities, hasLength(3));
      expect(retrieved.activities, hasLength(3));
      
      print('✅ Database save/retrieve: SUCCESS');
      print('   - Campground: ${retrieved.name}');
      print('   - Location: ${retrieved.state} (${retrieved.latitude}, ${retrieved.longitude})');
      print('   - Amenities: ${retrieved.amenities.join(", ")}');
      
      // Act - Search by state
      final caResults = await database.getCampgroundsByState('CA');
      
      // Assert
      expect(caResults, hasLength(1));
      expect(caResults.first.name, equals('Test Valley Campground'));
      
      print('✅ Search by state: SUCCESS');
      print('   - Found ${caResults.length} campground(s) in CA');
      
      // Act - Text search
      final searchResults = await database.searchByQuery('Valley');
      
      // Assert  
      expect(searchResults, hasLength(1));
      expect(searchResults.first.name, contains('Valley'));
      
      print('✅ Text search: SUCCESS');
      print('   - Query "Valley" found ${searchResults.length} result(s)');

      // Act - Location search (within 50 miles of San Francisco)
      final nearbyResults = await database.searchNearby(
        latitude: 37.7749,
        longitude: -122.4194,
        radiusMiles: 50.0,
      );
      
      // Assert
      expect(nearbyResults, hasLength(1));
      
      print('✅ Location search: SUCCESS');
      print('   - Found ${nearbyResults.length} campground(s) within 50 miles');
      
      // Act - Monitor status
      await database.updateMonitoringStatus('test_campground_1', true);
      final monitored = await database.getMonitoredCampgrounds();
      
      // Assert
      expect(monitored, hasLength(1));
      expect(monitored.first.isMonitored, isTrue);
      
      print('✅ Monitoring status: SUCCESS');
      print('   - ${monitored.length} campground(s) being monitored');
    });

    test('Database handles multiple records efficiently', () async {
      // Arrange - Create 50 test campgrounds
      final testCampgrounds = List.generate(50, (index) => Campground(
        id: 'bulk_test_$index',
        name: 'Bulk Test Campground $index',
        description: 'Test campground number $index',
        latitude: 37.0 + (index * 0.01), // Spread them out
        longitude: -122.0 + (index * 0.01),
        state: ['CA', 'TX', 'FL', 'NY'][index % 4],
        amenities: const ['Restrooms'],
        activities: const ['Hiking'],
        imageUrls: const [],
      ));

      final stopwatch = Stopwatch()..start();
      
      // Act - Batch save
      await database.saveCampgrounds(testCampgrounds);
      final saveTime = stopwatch.elapsedMilliseconds;
      
      stopwatch.reset();
      
      // Act - Retrieve all
      final allCampgrounds = await database.getAllCampgrounds();
      final retrieveTime = stopwatch.elapsedMilliseconds;
      
      stopwatch.stop();

      // Assert
      expect(allCampgrounds, hasLength(50));
      expect(saveTime, lessThan(3000)); // Should be fast
      expect(retrieveTime, lessThan(1000)); // Should be very fast
      
      print('✅ Bulk operations: SUCCESS');
      print('   - Saved 50 campgrounds in ${saveTime}ms');
      print('   - Retrieved 50 campgrounds in ${retrieveTime}ms');
      
      // Test search performance
      stopwatch.start();
      final caResults = await database.getCampgroundsByState('CA');
      final searchTime = stopwatch.elapsedMilliseconds;
      stopwatch.stop();
      
      expect(caResults, hasLength(13)); // Should be roughly 1/4 of 50
      expect(searchTime, lessThan(500)); // Should be very fast
      
      print('✅ Search performance: SUCCESS');
      print('   - Found ${caResults.length} CA campgrounds in ${searchTime}ms');
    });
  });
}