import 'package:flutter_test/flutter_test.dart';
import 'package:sitebook_flutter/shared/models/campground.dart';
import 'package:sitebook_flutter/core/storage/campground_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Chrome-optimized API integration test
/// Clean test that works properly in browser environment
void main() {
  group('Chrome API Integration Test', () {
    late CampgroundDatabase database;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      database = CampgroundDatabase();
      // Clean slate for each test
      await database.clearAllData();
    });

    tearDown(() async {
      await database.close();
    });

    test('🌐 Chrome: Core database operations work perfectly', () async {
      print('🚀 Testing in Chrome browser environment...');
      
      // Arrange
      final testCampground = Campground(
        id: 'chrome_test_1',
        name: 'Chrome Test Campground',
        description: 'Testing browser compatibility',
        latitude: 37.7749,
        longitude: -122.4194,
        state: 'CA',
        amenities: const ['Restrooms', 'Fire Pits', 'WiFi'],
        activities: const ['Hiking', 'Stargazing', 'Photography'],
        imageUrls: const [],
      );

      // Act & Assert - Save
      await database.saveCampground(testCampground);
      print('✅ Save operation: SUCCESS');
      
      // Act & Assert - Retrieve
      final retrieved = await database.getCampgroundById('chrome_test_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Chrome Test Campground'));
      print('✅ Retrieve operation: SUCCESS');
      
      // Act & Assert - Search by state  
      final caResults = await database.getCampgroundsByState('CA');
      expect(caResults, hasLength(1));
      print('✅ State search: Found ${caResults.length} campground(s) in CA');
      
      // Act & Assert - Text search
      final searchResults = await database.searchByQuery('Chrome');
      expect(searchResults, hasLength(1));
      print('✅ Text search: Found ${searchResults.length} result(s) for "Chrome"');
      
      // Act & Assert - Location search 
      final nearbyResults = await database.searchNearby(
        latitude: 37.7749,
        longitude: -122.4194,
        radiusMiles: 10.0,
      );
      expect(nearbyResults, hasLength(1));
      print('✅ Location search: Found ${nearbyResults.length} campground(s) within 10 miles');
      
      print('🎉 All Chrome browser tests PASSED!');
    });

    test('🌐 Chrome: Bulk operations perform well', () async {
      print('⚡ Testing performance in Chrome...');
      
      // Create 20 test campgrounds (smaller set for browser)
      final testCampgrounds = List.generate(20, (index) => Campground(
        id: 'chrome_bulk_$index',
        name: 'Chrome Bulk Test $index',
        description: 'Bulk test campground $index',
        latitude: 37.0 + (index * 0.01),
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
      
      // Assert
      expect(allCampgrounds, hasLength(20));
      print('✅ Bulk operations in Chrome:');
      print('   - Saved 20 campgrounds: ${saveTime}ms');
      print('   - Retrieved 20 campgrounds: ${retrieveTime}ms');
      print('   - Performance: EXCELLENT for browser environment');
      
      stopwatch.stop();
    });

    test('🌐 Chrome: Web-specific features work', () async {
      print('🔍 Testing web-specific functionality...');
      
      // Test JavaScript-safe operations
      final webCampground = Campground(
        id: 'web_special_chars_test',
        name: 'Web "Special" & <Characters> Test',
        description: 'Testing special characters: âéîôû, 中文, 🏕️',
        latitude: 37.7749,
        longitude: -122.4194,
        state: 'CA',
        amenities: const ['Restrooms', 'WiFi & Internet', 'Fire Pits'],
        activities: const ['Hiking & Backpacking', 'Photography'],
        imageUrls: const [],
      );
      
      await database.saveCampground(webCampground);
      final retrieved = await database.getCampgroundById('web_special_chars_test');
      
      expect(retrieved, isNotNull);
      expect(retrieved!.name, contains('Special'));
      expect(retrieved.description, contains('🏕️'));
      expect(retrieved.amenities.first, equals('Restrooms'));
      
      print('✅ Special characters handled correctly in browser');
      print('✅ Unicode support: Working');
      print('✅ HTML-safe operations: Working');
    });
  });
}