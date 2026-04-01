import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sitebook_flutter/shared/providers/campground_providers.dart';

void main() {
  group('Maps & Location Functionality Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('NearbySearchParams should create valid parameters', () {
      const params = NearbySearchParams(
        latitude: 37.7749,
        longitude: -122.4194,
        radiusMiles: 25.0,
        stateFilter: 'CA',
      );

      expect(params.latitude, equals(37.7749));
      expect(params.longitude, equals(-122.4194));
      expect(params.radiusMiles, equals(25.0));
      expect(params.stateFilter, equals('CA'));
    });

    test('NearbySearchParams should handle null state filter', () {
      const params = NearbySearchParams(
        latitude: 37.7749,
        longitude: -122.4194,
        radiusMiles: 25.0,
      );

      expect(params.stateFilter, isNull);
      expect(params.latitude, equals(37.7749));
      expect(params.longitude, equals(-122.4194));
      expect(params.radiusMiles, equals(25.0));
    });

    test('NearbySearchParams equality should work correctly', () {
      const params1 = NearbySearchParams(
        latitude: 37.7749,
        longitude: -122.4194,
        radiusMiles: 25.0,
        stateFilter: 'CA',
      );

      const params2 = NearbySearchParams(
        latitude: 37.7749,
        longitude: -122.4194,
        radiusMiles: 25.0,
        stateFilter: 'CA',
      );

      const params3 = NearbySearchParams(
        latitude: 37.7749,
        longitude: -122.4194,
        radiusMiles: 50.0,
        stateFilter: 'CA',
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
      expect(params1.hashCode, equals(params2.hashCode));
      expect(params1.hashCode, isNot(equals(params3.hashCode)));
    });

    test('Should validate LocationSettings parameters are accessible', () {
      // Test that LocationSettings can be created (our fix for deprecated desiredAccuracy)
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      expect(settings.accuracy, equals(LocationAccuracy.high));
      expect(settings.distanceFilter, equals(10));
    });

    test('Maps screen dependencies should be available', () {
      // Test that all providers needed by Maps screen are available
      expect(() => container.read(searchResultsProvider), returnsNormally);
      expect(() => container.read(campgroundsProvider), returnsNormally);
      expect(
        () => container.read(monitoredCampgroundsProvider),
        returnsNormally,
      );
    });
  });
}
