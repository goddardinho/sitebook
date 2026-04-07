import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Provider for search query state
final searchQueryProvider = Provider((ref) => SearchQueryNotifier());

class SearchQueryNotifier {
  String _query = '';

  String get query => _query;
  bool get isEmpty => _query.isEmpty;
  bool get isNotEmpty => _query.isNotEmpty;

  void updateQuery(String newQuery) {
    _query = newQuery;
  }

  @override
  String toString() => _query;
}

// Provider for campground search results
final searchResultsProvider = FutureProvider.family<List<Campground>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) {
    return ref.watch(nearbyyCampgroundsProvider.future);
  }
  // For now, use local filtering of nearby campgrounds
  // In future, could implement server-side search
  final nearbyCampgrounds = await ref.watch(nearbyyCampgroundsProvider.future);
  return nearbyCampgrounds.where((campground) {
    final searchTerm = query.toLowerCase();
    return campground.name.toLowerCase().contains(searchTerm) ||
        campground.description.toLowerCase().contains(searchTerm) ||
        campground.state.toLowerCase().contains(searchTerm) ||
        (campground.parkName?.toLowerCase().contains(searchTerm) ?? false);
  }).toList();
});

// Simple Set-based monitoring system
final monitoredCampgroundIdsProvider = Provider(
  (ref) => MonitoredCampgroundIds(),
);

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

  void addMonitoring(String campgroundId) {
    if (!_monitoredIds.contains(campgroundId)) {
      _monitoredIds.add(campgroundId);
    }
  }

  void removeMonitoring(String campgroundId) {
    if (_monitoredIds.contains(campgroundId)) {
      _monitoredIds.remove(campgroundId);
    }
  }

  bool isMonitored(String campgroundId) {
    return _monitoredIds.contains(campgroundId);
  }

  int get count => _monitoredIds.length;
}

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
    final searchNotifier = ref.read(searchQueryProvider);
    searchNotifier.updateQuery(query);
  }

  void toggleMonitoring(String campgroundId) {
    final monitoredIds = ref.read(monitoredCampgroundIdsProvider);
    monitoredIds.toggleMonitoring(campgroundId);
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
