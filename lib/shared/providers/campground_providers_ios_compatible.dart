import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/campground.dart';
import '../../demo/demo_data_provider.dart';
// Note: Removed notification integration import to fix iOS crashes

// Demo providers for immediate UX testing (iOS-compatible version)
final campgroundRepositoryProvider = Provider((ref) => "Demo Mode - iOS Compatible");

// Provider for all campgrounds
final campgroundsProvider = FutureProvider<List<Campground>>((ref) async {
  return DemoDataProvider.getAllCampgrounds();
});

// Provider for monitored campgrounds
final monitoredCampgroundsProvider = FutureProvider<List<Campground>>((ref) async {
  return DemoDataProvider.getMonitoredCampgrounds();
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
  final searchQueryNotifier = ref.watch(searchQueryProvider);
  final query = searchQueryNotifier.query;
  if (query.isEmpty) {
    return DemoDataProvider.getAllCampgrounds();
  }
  return DemoDataProvider.searchByQuery(query);
});

// Provider for campgrounds by state
final campgroundsByStateProvider = FutureProvider.family<List<Campground>, String>((ref, state) async {
  return DemoDataProvider.getCampgroundsByState(state);
});

// Provider for campground details
final campgroundDetailsProvider = FutureProvider.family<Campground?, String>((ref, id) async {
  return DemoDataProvider.getCampgroundById(id);
});

// Provider for UI state (converted from StateProvider)
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

// Location search provider
final nearbySearchProvider = FutureProvider.family<List<Campground>, Map<String, dynamic>>((ref, params) async {
  // For demo, just return first 3 campgrounds as "nearby"
  return DemoDataProvider.getAllCampgrounds().take(3).toList();
});

// Actions provider for campground operations (iOS-compatible version)
final campgroundActionsProvider = Provider((ref) {
  return CampgroundActionsIOSCompatible(ref);
});

// Provider for monitored count
final monitoredCountProvider = FutureProvider<int>((ref) async {
  return DemoDataProvider.getMonitoredCampgrounds().length;
});

class CampgroundActionsIOSCompatible {
  static int _monitoringStartCount = 0;
  final Ref _ref;
  
  CampgroundActionsIOSCompatible(this._ref);
  
  Future<void> toggleMonitoring(String campgroundId, bool isMonitored) async {
    try {
      // Update the demo data
      DemoDataProvider.toggleMonitoring(campgroundId);
      
      // Invalidate providers to trigger UI update
      _ref.invalidate(searchResultsProvider);
      _ref.invalidate(campgroundsProvider);
      _ref.invalidate(monitoredCountProvider);
      
      // Get the campground details for logging
      final campground = DemoDataProvider.getCampgroundById(campgroundId);
      if (campground == null) return;
      
      // iOS-compatible: Log monitoring status instead of sending notifications
      debugPrint('🏕️ Monitoring ${isMonitored ? 'started' : 'stopped'} for ${campground.name}');
      
      // Send welcome notification on first monitoring start (iOS-compatible version)
      if (isMonitored && _monitoringStartCount == 0) {
        _monitoringStartCount++;
        debugPrint('✅ Welcome! Monitoring started for your first campground.');
      }
      
      // For demo purposes, simulate finding availability shortly after monitoring starts
      if (isMonitored) {
        _simulateAvailabilityCheck(campground);
      }
      
    } catch (e) {
      debugPrint('❌ Error toggling monitoring for $campgroundId: $e');
    }
  }
  
  void updateSearchQuery(String query) {
    final searchQueryNotifier = _ref.read(searchQueryProvider);
    searchQueryNotifier.updateQuery(query);
    // Invalidate search results to trigger update
    _ref.invalidate(searchResultsProvider);
  }
  
  /// Simulate availability check for demo purposes (iOS-compatible version)
  Future<void> _simulateAvailabilityCheck(Campground campground) async {
    // Wait a few seconds, then possibly log availability for demo
    Future.delayed(const Duration(seconds: 5), () async {
      // 30% chance of "finding" availability for demo
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      if (random < 30) {
        debugPrint('🔥 Demo: Found availability at ${campground.name}!');
        debugPrint('📅 Available dates: ${DateTime.now().add(const Duration(days: 14))} - ${DateTime.now().add(const Duration(days: 16))}');
      }
    });
  }
}