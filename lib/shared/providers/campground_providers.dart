import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/campground.dart';
import '../repositories/campground_repository.dart';
import '../repositories/simple_campground_repository.dart';

// Repository provider - using simplified version for UX testing
final campgroundRepositoryProvider = Provider<CampgroundRepository>((ref) {
  return SimpleCampgroundRepository();
});

// Provider for all campgrounds (async from repository)
final campgroundsProvider = FutureProvider<List<Campground>>((ref) async {
  final repository = ref.read(campgroundRepositoryProvider);
  return await repository.getAllCampgrounds();
});

// Provider for campgrounds by state
final campgroundsByStateProvider =
    FutureProvider.family<List<Campground>, String>((ref, stateCode) async {
      final repository = ref.read(campgroundRepositoryProvider);
      return await repository.getCampgroundsByState(stateCode);
    });

// Provider for monitored campgrounds
final monitoredCampgroundsProvider = FutureProvider<List<Campground>>((
  ref,
) async {
  final repository = ref.read(campgroundRepositoryProvider);
  return await repository.getMonitoredCampgrounds();
});

// Provider for search query state (converted from StateProvider)
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

// Provider for search results based on query
final searchResultsProvider = FutureProvider<List<Campground>>((ref) async {
  final repository = ref.read(campgroundRepositoryProvider);
  final searchQueryNotifier = ref.watch(searchQueryProvider);
  final query = searchQueryNotifier.query;

  if (query.isEmpty) {
    // Return all campgrounds when no search query
    return await repository.getAllCampgrounds();
  }

  return await repository.searchByQuery(query);
});

// Provider for campground details by ID
final campgroundDetailsProvider = FutureProvider.family<Campground?, String>((
  ref,
  campgroundId,
) async {
  final repository = ref.read(campgroundRepositoryProvider);
  return await repository.getCampgroundById(campgroundId);
});

// Provider for location-based search
final nearbySearchProvider =
    FutureProvider.family<List<Campground>, NearbySearchParams>((
      ref,
      params,
    ) async {
      final repository = ref.read(campgroundRepositoryProvider);
      return await repository.searchNearby(
        latitude: params.latitude,
        longitude: params.longitude,
        radiusMiles: params.radiusMiles,
        stateFilter: params.stateFilter,
      );
    });

// Provider for availability check
final availabilityProvider =
    FutureProvider.family<Map<String, bool>, AvailabilityParams>((
      ref,
      params,
    ) async {
      final repository = ref.read(campgroundRepositoryProvider);
      return await repository.checkAvailability(
        campgroundId: params.campgroundId,
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

// Provider for monitoring count
final monitoredCountProvider = FutureProvider<int>((ref) async {
  final monitoredCampgrounds = await ref.watch(
    monitoredCampgroundsProvider.future,
  );
  return monitoredCampgrounds.length;
});

// StateProvider for campground actions
final campgroundActionsProvider = Provider<CampgroundActions>((ref) {
  return CampgroundActions(ref.read(campgroundRepositoryProvider), ref);
});

// State classes for tracking loading/error states (converted from StateProvider)
final campgroundLoadingProvider = Provider((ref) => UIStateNotifier());
final campgroundErrorProvider = Provider((ref) => ErrorStateNotifier());

class UIStateNotifier {
  bool _loading = false;

  bool get loading => _loading;

  void setLoading(bool loading) {
    _loading = loading;
  }
}

class ErrorStateNotifier {
  String? _error;

  String? get error => _error;

  void setError(String? error) {
    _error = error;
  }
}

// Actions class for handling campground operations
class CampgroundActions {
  final CampgroundRepository _repository;
  final Ref _ref;

  CampgroundActions(this._repository, this._ref);

  /// Toggle monitoring status for a campground
  Future<void> toggleMonitoring(String campgroundId, bool isMonitored) async {
    try {
      _ref.read(campgroundLoadingProvider).setLoading(true);
      _ref.read(campgroundErrorProvider).setError(null);

      await _repository.updateMonitoringStatus(campgroundId, isMonitored);

      // Refresh monitored campgrounds
      _ref.invalidate(monitoredCampgroundsProvider);

      _ref.read(campgroundLoadingProvider).setLoading(false);
    } catch (e) {
      _ref.read(campgroundLoadingProvider).setLoading(false);
      _ref
          .read(campgroundErrorProvider)
          .setError('Failed to update monitoring status: ${e.toString()}');
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _ref.read(searchQueryProvider).updateQuery(query);
  }

  /// Refresh all campground data from APIs
  Future<void> refreshData() async {
    try {
      _ref.read(campgroundLoadingProvider).setLoading(true);
      _ref.read(campgroundErrorProvider).setError(null);

      await _repository.refresh();

      // Refresh all providers
      _ref.invalidate(campgroundsProvider);
      _ref.invalidate(searchResultsProvider);
      _ref.invalidate(monitoredCampgroundsProvider);

      _ref.read(campgroundLoadingProvider).setLoading(false);
    } catch (e) {
      _ref.read(campgroundLoadingProvider).setLoading(false);
      _ref
          .read(campgroundErrorProvider)
          .setError('Failed to refresh data: ${e.toString()}');
    }
  }

  /// Clear all cached campground data
  Future<void> clearCache() async {
    try {
      _ref.read(campgroundLoadingProvider).setLoading(true);
      _ref.read(campgroundErrorProvider).setError(null);

      await _repository.clearCache();

      // Refresh all providers
      _ref.invalidate(campgroundsProvider);
      _ref.invalidate(searchResultsProvider);
      _ref.invalidate(monitoredCampgroundsProvider);

      _ref.read(campgroundLoadingProvider).setLoading(false);
    } catch (e) {
      _ref.read(campgroundLoadingProvider).setLoading(false);
      _ref
          .read(campgroundErrorProvider)
          .setError('Failed to clear cache: ${e.toString()}');
    }
  }

  /// Clear any error state
  void clearError() {
    _ref.read(campgroundErrorProvider).setError(null);
  }
}

class NearbySearchParams {
  final double latitude;
  final double longitude;
  final double radiusMiles;
  final String? stateFilter;

  const NearbySearchParams({
    required this.latitude,
    required this.longitude,
    required this.radiusMiles,
    this.stateFilter,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbySearchParams &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radiusMiles == other.radiusMiles &&
          stateFilter == other.stateFilter;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      radiusMiles.hashCode ^
      stateFilter.hashCode;
}

class AvailabilityParams {
  final String campgroundId;
  final DateTime startDate;
  final DateTime endDate;

  const AvailabilityParams({
    required this.campgroundId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityParams &&
          runtimeType == other.runtimeType &&
          campgroundId == other.campgroundId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      campgroundId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}
