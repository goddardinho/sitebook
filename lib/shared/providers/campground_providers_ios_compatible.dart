import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../models/campground.dart';
import '../../demo/demo_data_provider.dart';
import '../services/availability_monitoring_service.dart';
import '../services/enhanced_notification_service.dart';
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

// Provider for background monitoring status
final backgroundMonitoringStatusProvider = FutureProvider<BackgroundMonitoringStatus>((ref) async {
  final isActive = await AvailabilityMonitoringService.isMonitoringActive();
  final monitoredCount = DemoDataProvider.getMonitoredCampgrounds().length;
  final notificationsEnabled = await EnhancedNotificationService.areNotificationsEnabled();
  
  return BackgroundMonitoringStatus(
    isActive: isActive,
    monitoredCampgrounds: monitoredCount,
    notificationsEnabled: notificationsEnabled,
    lastCheckTime: DateTime.now(), // TODO: Store actual last check time
  );
});

// Provider for manual monitoring controls
final monitoringControlsProvider = Provider((ref) {
  return MonitoringControls(ref);
});

/// Background monitoring status data model
class BackgroundMonitoringStatus {
  final bool isActive;
  final int monitoredCampgrounds;
  final bool notificationsEnabled;
  final DateTime lastCheckTime;

  const BackgroundMonitoringStatus({
    required this.isActive,
    required this.monitoredCampgrounds,
    required this.notificationsEnabled,
    required this.lastCheckTime,
  });
  
  bool get hasMonitoredCampgrounds => monitoredCampgrounds > 0;
  
  String get statusText {
    if (!hasMonitoredCampgrounds) return 'No campgrounds monitored';
    if (!isActive) return 'Monitoring paused';
    if (!notificationsEnabled) return 'Notifications disabled';
    return 'Monitoring $monitoredCampgrounds campgrounds';
  }
}

/// Monitoring controls for manual operations
class MonitoringControls {
  final Ref _ref;
  
  MonitoringControls(this._ref);
  
  /// Trigger immediate availability check
  Future<void> triggerImmediateCheck() async {
    try {
      await AvailabilityMonitoringService.triggerImmediateCheck();
      debugPrint('🔍 Manual availability check triggered');
      
      // Invalidate status provider to update UI
      _ref.invalidate(backgroundMonitoringStatusProvider);
      
    } catch (e) {
      debugPrint('❌ Error triggering immediate check: $e');
    }
  }
  
  /// Start background monitoring service
  Future<void> startBackgroundMonitoring() async {
    try {
      await AvailabilityMonitoringService.startMonitoring();
      debugPrint('🔄 Background monitoring started manually');
      
      // Invalidate status provider to update UI
      _ref.invalidate(backgroundMonitoringStatusProvider);
      
    } catch (e) {
      debugPrint('❌ Error starting background monitoring: $e');
    }
  }
  
  /// Stop background monitoring service
  Future<void> stopBackgroundMonitoring() async {
    try {
      await AvailabilityMonitoringService.stopMonitoring();
      debugPrint('⏹️ Background monitoring stopped manually');
      
      // Invalidate status provider to update UI
      _ref.invalidate(backgroundMonitoringStatusProvider);
      
    } catch (e) {
      debugPrint('❌ Error stopping background monitoring: $e');
    }
  }
  
  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      final granted = await EnhancedNotificationService.requestPermissions();
      
      // Invalidate status provider to update UI
      _ref.invalidate(backgroundMonitoringStatusProvider);
      
      return granted;
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
      return false;
    }
  }
}

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
      
      // Enhanced monitoring integration
      if (isMonitored) {
        await _startMonitoring(campground);
      } else {
        await _stopMonitoring(campground);
      }
      
    } catch (e) {
      debugPrint('❌ Error toggling monitoring for $campgroundId: $e');
    }
  }
  
  /// Start monitoring for a specific campground
  Future<void> _startMonitoring(Campground campground) async {
    try {
      debugPrint('🏕️ Monitoring started for ${campground.name}');
      
      // Send monitoring started notification
      await EnhancedNotificationService.sendMonitoringStartedNotification(campground);
      
      // Send welcome notification on first monitoring start
      if (_monitoringStartCount == 0) {
        _monitoringStartCount++;
        await EnhancedNotificationService.sendWelcomeNotification();
      }
      
      // Start background monitoring service if we have monitored campgrounds
      final monitoredCount = DemoDataProvider.getMonitoredCampgrounds().length;
      if (monitoredCount == 1) { // First campground being monitored
        await AvailabilityMonitoringService.startMonitoring();
        debugPrint('🔄 Background availability monitoring service started');
      }
      
      // Trigger immediate check for demo purposes
      await AvailabilityMonitoringService.triggerImmediateCheck();
      
    } catch (e) {
      debugPrint('❌ Error starting monitoring for ${campground.name}: $e');
    }
  }
  
  /// Stop monitoring for a specific campground
  Future<void> _stopMonitoring(Campground campground) async {
    try {
      debugPrint('🏕️ Monitoring stopped for ${campground.name}');
      
      // Check if we still have any monitored campgrounds
      final monitoredCount = DemoDataProvider.getMonitoredCampgrounds().length;
      if (monitoredCount == 0) { // No more campgrounds being monitored
        await AvailabilityMonitoringService.stopMonitoring();
        debugPrint('⏹️ Background availability monitoring service stopped');
      }
      
    } catch (e) {
      debugPrint('❌ Error stopping monitoring for ${campground.name}: $e');
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