import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/campground.dart';
import '../../demo/demo_data_provider.dart';
import '../../core/integrations/campground_notification_integration.dart';

// Demo providers for immediate UX testing
final campgroundRepositoryProvider = Provider((ref) => "Demo Mode");

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

// Actions provider for campground operations  
final campgroundActionsProvider = Provider((ref) {
  return CampgroundActions(ref);
});

// Provider for monitored count
final monitoredCountProvider = FutureProvider<int>((ref) async {
  return DemoDataProvider.getMonitoredCampgrounds().length;
});

class CampgroundActions {
  static int _monitoringStartCount = 0;
  final Ref _ref;
  
  CampgroundActions(this._ref);
  
  Future<void> toggleMonitoring(String campgroundId, bool isMonitored) async {
    try {
      // Update the demo data
      DemoDataProvider.toggleMonitoring(campgroundId);
      
      // Invalidate providers to trigger UI update
      _ref.invalidate(searchResultsProvider);
      _ref.invalidate(campgroundsProvider);
      _ref.invalidate(monitoredCountProvider);
      
      // Get the campground details for notifications
      final campground = DemoDataProvider.getCampgroundById(campgroundId);
      if (campground == null) return;
      
      // Send notification about monitoring status change
      await CampgroundNotificationIntegration.notifyMonitoringUpdate(
        campground: campground,
        isMonitored: isMonitored,
      );
      
      // Send welcome notification on first monitoring start
      if (isMonitored && _monitoringStartCount == 0) {
        _monitoringStartCount++;
        await CampgroundNotificationIntegration.sendWelcomeNotification();
      }
      
      // For demo purposes, simulate finding availability shortly after monitoring starts
      if (isMonitored) {
        _simulateAvailabilityCheck(campground);
      }
      
    } catch (e) {
      debugPrint('❌ Error toggling monitoring for $campgroundId: $e');
    }
  }
  
  /// Simulate availability check for demo purposes
  Future<void> _simulateAvailabilityCheck(Campground campground) async {
    // Wait a few seconds, then possibly send an availability notification
    Future.delayed(const Duration(seconds: 5), () async {
      // 30% chance of "finding" availability for demo
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      if (random < 30) {
        await CampgroundNotificationIntegration.notifyCampgroundAvailable(
          campground: campground,
          startDate: DateTime.now().add(const Duration(days: 14)),
          endDate: DateTime.now().add(const Duration(days: 16)),
        );
      }
    });
  }
  
  /// Test notification functionality 
  Future<void> testNotifications() async {
    try {
      final campgrounds = DemoDataProvider.getAllCampgrounds();
      if (campgrounds.isNotEmpty) {
        final testCampground = campgrounds.first;
        
        await CampgroundNotificationIntegration.notifyCampgroundAvailable(
          campground: testCampground,
          startDate: DateTime.now().add(const Duration(days: 7)),
          endDate: DateTime.now().add(const Duration(days: 9)),
        );
      }
    } catch (e) {
      debugPrint('❌ Error testing notifications: $e');  
    }
  }
  
  Future<void> refreshCampgrounds() async {
    // Demo version - no refresh needed
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  Future<void> searchCampgrounds(String query) async {
    // Demo version - handled by providers
    await Future.delayed(const Duration(milliseconds: 300));
  }
  
  Future<void> updateSearchQuery(String query) async {
    final searchNotifier = _ref.read(searchQueryProvider);
    searchNotifier.updateQuery(query);
    // Invalidate search results to trigger update
    _ref.invalidate(searchResultsProvider);
  }
}