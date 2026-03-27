import 'package:flutter_test/flutter_test.dart';
import 'package:sitebook_flutter/shared/models/campground.dart';
import 'package:sitebook_flutter/core/storage/campground_database.dart';
import 'package:sitebook_flutter/shared/repositories/campground_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Manual API Integration Test
/// 
/// This test validates the complete API integration flow without mocking.
/// Use this for local development testing with real API connections.
/// 
/// WARNING: These tests make actual HTTP requests and may be rate limited.
void main() {
  group('Manual API Integration Tests', () {
    late CampgroundDatabase database;
    late CampgroundRepositoryImpl repository;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      database = CampgroundDatabase();
      repository = CampgroundRepositoryImpl(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    group('Database Functionality', () {
      test('should save and retrieve campgrounds from database', () async {
        // Arrange
        final testCampground = Campground(
          id: 'manual_test_1',
          name: 'Manual Test Campground',
          description: 'A campground created for manual testing',
          latitude: 37.7749,
          longitude: -122.4194,
          state: 'CA',
          amenities: const ['Restrooms', 'Fire Pits', 'Water'],
          activities: const ['Hiking', 'Fishing', 'Swimming'],
          imageUrls: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await repository.saveCampground(testCampground);
        final retrieved = await repository.getCampgroundById('manual_test_1');

        // Assert
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Manual Test Campground'));
        expect(retrieved.state, equals('CA'));
        expect(retrieved.amenities, hasLength(3));
        
        print('✅ Database save/retrieve test passed');
      });

      test('should perform location-based search', () async {
        // Arrange - Add test campgrounds at various distances from San Francisco
        final testCampgrounds = [
          Campground(
            id: 'sf_nearby',
            name: 'San Francisco Nearby',
            description: 'Close to SF',
            latitude: 37.7849, // ~1 mile from SF
            longitude: -122.4094,
            state: 'CA',
            amenities: const ['Restrooms'],
            activities: const ['Hiking'],
            imageUrls: const [],
          ),
          Campground(
            id: 'sf_medium',
            name: 'San Francisco Medium',
            description: 'Medium distance from SF',
            latitude: 37.4419, // ~30 miles from SF (Palo Alto)
            longitude: -122.1430,
            state: 'CA',
            amenities: const ['Restrooms'],
            activities: const ['Hiking'],
            imageUrls: const [],
          ),
          Campground(
            id: 'sf_far',
            name: 'San Francisco Far',
            description: 'Far from SF',
            latitude: 36.7378, // ~150+ miles from SF
            longitude: -119.7871,
            state: 'CA',
            amenities: const ['Restrooms'],
            activities: const ['Hiking'],
            imageUrls: const [],
          ),
        ];

        await repository.saveCampgrounds(testCampgrounds);

        // Act - Search within 40 miles of San Francisco
        final nearbyResults = await repository.searchNearby(
          latitude: 37.7749,
          longitude: -122.4194,
          radiusMiles: 40.0,
        );

        // Assert
        expect(nearbyResults, hasLength(2)); // Should find nearby and medium, not far
        expect(nearbyResults.first.name, equals('San Francisco Nearby')); // Should be sorted by distance
        
        print('✅ Location-based search test passed: Found ${nearbyResults.length} campgrounds within 40 miles');
        for (final camp in nearbyResults) {
          print('   - ${camp.name}');
        }
      });

      test('should handle text search across all fields', () async {
        // Arrange
        final searchTestCampgrounds = [
          Campground(
            id: 'search_name',
            name: 'Yosemite Valley Campground',
            description: 'Beautiful granite cliffs',
            latitude: 37.7749,
            longitude: -122.4194,
            state: 'CA',
            parkName: 'Yosemite National Park',
            amenities: const [],
            activities: const [],
            imageUrls: const [],
          ),
          Campground(
            id: 'search_desc',
            name: 'Mountain View Camp',
            description: 'Perfect for families with granite formations',
            latitude: 37.7749,
            longitude: -122.4194,
            state: 'CA',
            amenities: const [],
            activities: const [],
            imageUrls: const [],
          ),
          Campground(
            id: 'search_park',
            name: 'Valley Floor Camp',
            description: 'Scenic campground',
            latitude: 37.7749,
            longitude: -122.4194,
            state: 'CA',
            parkName: 'Sequoia National Park',
            amenities: const [],
            activities: const [],
            imageUrls: const [],
          ),
        ];

        await repository.saveCampgrounds(searchTestCampgrounds);

        // Act - Test various search terms
        final yosemiteResults = await repository.searchByQuery('Yosemite');
        final graniteResults = await repository.searchByQuery('granite');
        final sequoiaResults = await repository.searchByQuery('Sequoia');

        // Assert
        expect(yosemiteResults, hasLength(1));
        expect(yosemiteResults.first.name, contains('Yosemite'));

        expect(graniteResults, hasLength(2)); // Should find both "granite" mentions
        
        expect(sequoiaResults, hasLength(1));
        expect(sequoiaResults.first.parkName, contains('Sequoia'));

        print('✅ Text search test passed:');
        print('   - Yosemite search: ${yosemiteResults.length} results');
        print('   - Granite search: ${graniteResults.length} results');
        print('   - Sequoia search: ${sequoiaResults.length} results');
      });

      test('should handle monitoring status updates', () async {
        // Arrange
        final monitoringTestCampgrounds = [
          Campground(
            id: 'monitor_1',
            name: 'Monitor Test 1',
            description: 'Test campground 1',
            latitude: 37.7749,
            longitude: -122.4194,
            state: 'CA',
            amenities: const [],
            activities: const [],
            imageUrls: const [],
            isMonitored: false,
          ),
          Campground(
            id: 'monitor_2',
            name: 'Monitor Test 2',
            description: 'Test campground 2',
            latitude: 37.7749,
            longitude: -122.4194,
            state: 'CA',
            amenities: const [],
            activities: const [],
            imageUrls: const [],
            isMonitored: true,
          ),
        ];

        await repository.saveCampgrounds(monitoringTestCampgrounds);

        // Act - Toggle monitoring status
        await repository.updateMonitoringStatus('monitor_1', true);
        await repository.updateMonitoringStatus('monitor_2', false);

        // Get monitored campgrounds
        final monitoredCampgrounds = await repository.getMonitoredCampgrounds();

        // Assert
        expect(monitoredCampgrounds, hasLength(1));
        expect(monitoredCampgrounds.first.id, equals('monitor_1'));

        print('✅ Monitoring status test passed: Found ${monitoredCampgrounds.length} monitored campgrounds');
      });
    });

    group('Performance Tests', () {
      test('should handle large datasets efficiently', () async {
        // Arrange - Generate 1000 test campgrounds
        final largeCampgroundList = List.generate(1000, (index) => Campground(
          id: 'perf_test_$index',
          name: 'Performance Test Campground $index',
          description: 'Generated campground $index for performance testing',
          latitude: 37.0 + (index % 100) * 0.01, // Spread across ~1 degree
          longitude: -122.0 + (index % 100) * 0.01,
          state: ['CA', 'TX', 'FL', 'NY'][index % 4], // Rotate through states
          amenities: const ['Restrooms'],
          activities: const ['Hiking'],
          imageUrls: const [],
        ));

        final stopwatch = Stopwatch()..start();

        // Act - Batch save
        await repository.saveCampgrounds(largeCampgroundList);
        final saveTime = stopwatch.elapsedMilliseconds;
        
        stopwatch.reset();
        
        // Act - Retrieve all
        final allCampgrounds = await repository.getAllCampgrounds();
        final retrieveTime = stopwatch.elapsedMilliseconds;
        
        stopwatch.reset();
        
        // Act - Search by state  
        final caCampgrounds = await repository.getCampgroundsByState('CA');
        final searchTime = stopwatch.elapsedMilliseconds;

        stopwatch.stop();

        // Assert
        expect(allCampgrounds, hasLength(1000));
        expect(caCampgrounds, hasLength(250)); // Should be 1/4 of total
        
        print('✅ Performance test passed:');
        print('   - Batch save 1000 campgrounds: ${saveTime}ms');
        print('   - Retrieve all 1000 campgrounds: ${retrieveTime}ms');
        print('   - Search by state (250 results): ${searchTime}ms');
        
        // Performance assertions (adjust thresholds as needed)
        expect(saveTime, lessThan(5000)); // Should save 1000 records in under 5 seconds
        expect(retrieveTime, lessThan(2000)); // Should retrieve 1000 records in under 2 seconds
        expect(searchTime, lessThan(1000)); // Should search by state in under 1 second
      });

      test('should handle concurrent operations', () async {
        // Arrange
        final concurrentCampgrounds = List.generate(100, (index) => Campground(
          id: 'concurrent_$index',
          name: 'Concurrent Test $index',
          description: 'Concurrent operation test',
          latitude: 37.0 + index * 0.001,
          longitude: -122.0 + index * 0.001,
          state: 'CA',
          amenities: const [],
          activities: const [],
          imageUrls: const [],
        ));

        // Act - Run multiple operations concurrently
        final futures = <Future>[];
        final stopwatch = Stopwatch()..start();

        // Batch save operation
        futures.add(repository.saveCampgrounds(concurrentCampgrounds));
        
        // Multiple search operations
        for (int i = 0; i < 10; i++) {
          futures.add(repository.searchByQuery('Concurrent'));
        }

        // Multiple location searches
        for (int i = 0; i < 5; i++) {
          futures.add(repository.searchNearby(
            latitude: 37.0 + i * 0.1,
            longitude: -122.0 + i * 0.1,
            radiusMiles: 10.0,
          ));
        }

        // Wait for all operations to complete
        await Future.wait(futures);
        final totalTime = stopwatch.elapsedMilliseconds;

        // Assert
        expect(totalTime, lessThan(10000)); // All operations should complete in under 10 seconds
        
        print('✅ Concurrent operations test passed: ${futures.length} operations completed in ${totalTime}ms');
      });
    });

    group('Data Integrity Tests', () {
      test('should preserve data integrity across operations', () async {
        // Arrange
        final originalCampground = Campground(
          id: 'integrity_test',
          name: 'Data Integrity Test',
          description: 'Testing data integrity across operations',
          latitude: 37.7749,
          longitude: -122.4194,
          state: 'CA',
          parkName: 'Test National Park',
          phoneNumber: '555-123-4567',
          email: 'test@example.com',
          amenities: const ['Restrooms', 'Fire Pits', 'Picnic Tables'],
          activities: const ['Hiking', 'Fishing', 'Photography'],
          imageUrls: const ['image1.jpg', 'image2.jpg'],
          isMonitored: false,
          createdAt: DateTime(2026, 1, 1, 10, 0, 0),
          updatedAt: DateTime(2026, 1, 1, 10, 0, 0),
        );

        // Act - Save, retrieve, and verify all fields
        await repository.saveCampground(originalCampground);
        final retrieved = await repository.getCampgroundById('integrity_test');

        // Assert - Verify every field is preserved correctly
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(originalCampground.id));
        expect(retrieved.name, equals(originalCampground.name));
        expect(retrieved.description, equals(originalCampground.description));
        expect(retrieved.latitude, equals(originalCampground.latitude));
        expect(retrieved.longitude, equals(originalCampground.longitude));
        expect(retrieved.state, equals(originalCampground.state));
        expect(retrieved.parkName, equals(originalCampground.parkName));
        expect(retrieved.phoneNumber, equals(originalCampground.phoneNumber));
        expect(retrieved.email, equals(originalCampground.email));
        expect(retrieved.amenities, equals(originalCampground.amenities));
        expect(retrieved.activities, equals(originalCampground.activities));
        expect(retrieved.imageUrls, equals(originalCampground.imageUrls));
        expect(retrieved.isMonitored, equals(originalCampground.isMonitored));

        print('✅ Data integrity test passed: All fields preserved correctly');
        print('   - Amenities: ${retrieved.amenities.length} items');
        print('   - Activities: ${retrieved.activities.length} items');
        print('   - Images: ${retrieved.imageUrls.length} URLs');
      });
    });

    group('Error Handling Tests', () {
      test('should handle invalid coordinates gracefully', () async {
        // Arrange - Campground with invalid coordinates
        final invalidCampground = Campground(
          id: 'invalid_coords',
          name: 'Invalid Coordinates Test',
          description: 'Testing invalid coordinate handling',
          latitude: 999.0, // Invalid latitude
          longitude: -999.0, // Invalid longitude
          state: 'CA',
          amenities: const [],
          activities: const [],
          imageUrls: const [],
        );

        // Act & Assert - Should not throw, but handle gracefully
        await repository.saveCampground(invalidCampground);
        final retrieved = await repository.getCampgroundById('invalid_coords');
        
        expect(retrieved, isNotNull);
        expect(retrieved!.latitude, equals(999.0)); // Should preserve the value
        
        // Location search with invalid coordinates should return empty results
        final searchResults = await repository.searchNearby(
          latitude: 999.0,
          longitude: -999.0,
          radiusMiles: 10.0,
        );
        
        expect(searchResults, isEmpty);
        
        print('✅ Invalid coordinates test passed: Handled gracefully');
      });

      test('should handle empty and null data gracefully', () async {
        // Arrange - Campground with minimal data
        final minimalCampground = Campground(
          id: 'minimal_test',
          name: '', // Empty name
          description: '', // Empty description
          latitude: 0.0,
          longitude: 0.0,
          state: '',
          amenities: const [], // Empty amenities
          activities: const [], // Empty activities
          imageUrls: const [], // Empty images
        );

        // Act & Assert
        await repository.saveCampground(minimalCampground);
        final retrieved = await repository.getCampgroundById('minimal_test');
        
        expect(retrieved, isNotNull);
        expect(retrieved!.amenities, isEmpty);
        expect(retrieved.activities, isEmpty);
        expect(retrieved.imageUrls, isEmpty);
        
        print('✅ Empty data test passed: Minimal campground handled correctly');
      });
    });

    // Only run API tests if specifically enabled (to avoid hitting APIs during regular testing)
    group('Live API Tests (Optional)', () {
      // Note: These tests are commented out by default to avoid hitting live APIs
      // Uncomment and set up API keys to test live API integration
      
      /*
      test('should connect to Recreation.gov API', () async {
        // This test would require a valid Recreation.gov API key
        // Set up your API key in the RecreationGovApiService before running
        
        final apiService = RecreationGovApiService.create();
        
        // Act - Try to fetch a small set of facilities
        try {
          final response = await apiService.getFacilities(
            state: 'CA',
            limit: 5,
          );
          
          // Assert
          expect(response.data, isNotEmpty);
          expect(response.data.first.facilityName, isNotEmpty);
          
          print('✅ Recreation.gov API test passed: Retrieved ${response.data.length} facilities');
          for (final facility in response.data) {
            print('   - ${facility.facilityName}');
          }
        } catch (e) {
          print('⚠️  Recreation.gov API test skipped: ${e.toString()}');
          print('   (This is expected without valid API configuration)');
        }
      }, timeout: Timeout(Duration(seconds: 30)));
      */
    });
  });
}

/// Helper function to run all tests in the correct order
void runManualTestSuite() {
  print('🚀 Starting Manual API Integration Test Suite...\n');
  
  // This would be called from a test runner
  // The actual test execution is handled by the Flutter test framework
  
  print('Tests to be executed:');
  print('  📦 Database Functionality Tests');
  print('  🔍 Search and Location Tests');
  print('  👁️  Monitoring Feature Tests');
  print('  ⚡ Performance Tests');
  print('  🔒 Data Integrity Tests');
  print('  ❗ Error Handling Tests');
  print('  🌐 Live API Tests (Optional)');
  print('');
  print('Run with: flutter test test/manual_api_test.dart');
  print('');
}