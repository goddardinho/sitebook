import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/campground.dart';
import '../services/location_based_campground_service.dart';

// Live providers for location-based campground discovery
final locationBasedCampgroundServiceProvider = Provider(
  (ref) => LocationBasedCampgroundService(),
);

// Provider for nearby campgrounds based on user location
final nearbyyCampgroundsProvider = FutureProvider<List<Campground>>((
  ref,
) async {
  final service = ref.read(locationBasedCampgroundServiceProvider);
  return service.getCampgroundsNearUser();
});

// Provider for search query state - properly reactive
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void updateQuery(String newQuery) {
    state = newQuery;
  }

  void clearQuery() {
    state = '';
  }
}

// Provider for campground search results - enhanced with broader search
final searchResultsProvider = FutureProvider<List<Campground>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final selectedAmenities = ref.watch(amenityFiltersProvider);
  final searchRadius = ref.watch(searchRadiusProvider);

  if (query.isEmpty && selectedAmenities.isEmpty) {
    return ref.watch(nearbyyCampgroundsProvider.future);
  }

  // If search query is entered, use the selected search radius
  if (query.isNotEmpty) {
    final service = ref.read(locationBasedCampgroundServiceProvider);
    final expandedResults = await service.getCampgroundsNearUser(
      radiusInMiles: searchRadius, // Use user-selected radius
      limit: 20, // More results for search
    );

    // Apply text search filter
    var filteredResults = expandedResults.where((campground) {
      final searchTerm = query.toLowerCase();
      return campground.name.toLowerCase().contains(searchTerm) ||
          campground.description.toLowerCase().contains(searchTerm) ||
          campground.state.toLowerCase().contains(searchTerm) ||
          (campground.parkName?.toLowerCase().contains(searchTerm) ?? false);
    }).toList();

    // Apply amenity filters if selected
    if (selectedAmenities.isNotEmpty) {
      filteredResults = _filterByAmenities(filteredResults, selectedAmenities);
    }

    return filteredResults;
  }

  // If only amenity filters are applied, use nearby campgrounds
  final nearbyCampgrounds = await ref.watch(nearbyyCampgroundsProvider.future);
  return _filterByAmenities(nearbyCampgrounds, selectedAmenities);
});

// Helper function to filter by amenities
List<Campground> _filterByAmenities(
  List<Campground> campgrounds,
  Set<String> selectedAmenities,
) {
  if (selectedAmenities.isEmpty) return campgrounds;

  return campgrounds.where((campground) {
    // Check if campground has ALL selected amenities
    return selectedAmenities.every(
      (amenity) => campground.amenities.any(
        (campAmenity) =>
            campAmenity.toLowerCase().contains(amenity.toLowerCase()),
      ),
    );
  }).toList();
}

// Provider for amenity filter state
final amenityFiltersProvider =
    NotifierProvider<AmenityFiltersNotifier, Set<String>>(() {
      return AmenityFiltersNotifier();
    });

class AmenityFiltersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return <String>{};
  }

  void toggleAmenity(String amenity) {
    final newFilters = Set<String>.from(state);
    if (newFilters.contains(amenity)) {
      newFilters.remove(amenity);
    } else {
      newFilters.add(amenity);
    }
    state = newFilters;
  }

  void clearFilters() {
    state = <String>{};
  }
}

// Provider for search radius
final searchRadiusProvider = NotifierProvider<SearchRadiusNotifier, double>(() {
  return SearchRadiusNotifier();
});

class SearchRadiusNotifier extends Notifier<double> {
  @override
  double build() {
    return 50.0; // Default 50 mile radius
  }

  void updateRadius(double radius) {
    state = radius;
  }

  void resetRadius() {
    state = 50.0;
  }
}

// Common amenities for filtering
final commonAmenitiesProvider = Provider<List<String>>((ref) {
  return [
    'Restrooms',
    'Showers',
    'Picnic Tables',
    'Fire Rings',
    'Drinking Water',
    'RV Hookups',
    'Dump Station',
    'Beach Access',
    'Boat Launch',
    'Hiking Trails',
    'WiFi',
    'Store',
    'Laundry',
    'Playground',
    'Swimming',
    'Fishing',
    'Pet Friendly',
    'Handicap Accessible',
  ];
});

// Simple Set-based monitoring system
class MonitoredCampgroundIds {
  final Set<String> _monitoredIds = <String>{};

  Set<String> get ids => Set.unmodifiable(_monitoredIds);

  void toggleMonitoring(String campgroundId) {
    if (_monitoredIds.contains(campgroundId)) {
      _monitoredIds.remove(campgroundId);
    } else {
      _monitoredIds.add(campgroundId);
    }
  }

  bool isMonitored(String campgroundId) {
    return _monitoredIds.contains(campgroundId);
  }

  int get count => _monitoredIds.length;
}

final monitoredCampgroundIdsProvider = Provider(
  (ref) => MonitoredCampgroundIds(),
);

// Provider for monitored count
final monitoredCountProvider = Provider<int>((ref) {
  final monitoredIds = ref.watch(monitoredCampgroundIdsProvider);
  return monitoredIds.count;
});

// Provider for actions
final campgroundActionsProvider = Provider((ref) => CampgroundActions(ref));

class CampgroundActions {
  final Ref ref;

  CampgroundActions(this.ref);

  void updateSearchQuery(String query) {
    ref.read(searchQueryProvider.notifier).updateQuery(query);
  }

  void clearSearchQuery() {
    ref.read(searchQueryProvider.notifier).clearQuery();
  }

  void toggleMonitoring(String campgroundId) {
    final monitoredIds = ref.read(monitoredCampgroundIdsProvider);
    monitoredIds.toggleMonitoring(campgroundId);
  }

  void toggleAmenityFilter(String amenity) {
    ref.read(amenityFiltersProvider.notifier).toggleAmenity(amenity);
  }

  void clearAllFilters() {
    ref.read(searchQueryProvider.notifier).clearQuery();
    ref.read(amenityFiltersProvider.notifier).clearFilters();
    ref.read(searchRadiusProvider.notifier).resetRadius();
  }

  void updateSearchRadius(double radius) {
    ref.read(searchRadiusProvider.notifier).updateRadius(radius);
  }

  void resetSearchRadius() {
    ref.read(searchRadiusProvider.notifier).resetRadius();
  }
}

// Helper providers for UI state management
final campgroundLoadingProvider = Provider((ref) => UIStateNotifier());
final campgroundErrorProvider = Provider((ref) => ErrorStateNotifier());

class UIStateNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
  }
}

class ErrorStateNotifier {
  String? _errorMessage;

  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void setError(String? error) {
    _errorMessage = error;
  }

  void clearError() {
    _errorMessage = null;
  }
}
