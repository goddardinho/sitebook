import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/campground.dart';
import '../../demo/demo_data_provider.dart';

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

// Provider for search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider for search results based on query
final searchResultsProvider = FutureProvider<List<Campground>>((ref) async {
  final query = ref.watch(searchQueryProvider);
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

// Provider for UI state
final campgroundLoadingProvider = StateProvider<bool>((ref) => false);
final campgroundErrorProvider = StateProvider<String?>((ref) => null);

// Location search provider
final nearbySearchProvider = FutureProvider.family<List<Campground>, Map<String, dynamic>>((ref, params) async {
  // For demo, just return first 3 campgrounds as "nearby"
  return DemoDataProvider.getAllCampgrounds().take(3).toList();
});

// Actions provider for campground operations  
final campgroundActionsProvider = Provider((ref) {
  return CampgroundActions();
});

// Provider for monitored count
final monitoredCountProvider = FutureProvider<int>((ref) async {
  return DemoDataProvider.getMonitoredCampgrounds().length;
});

class CampgroundActions {
  Future<void> toggleMonitoring(String campgroundId, bool isMonitored) async {
    // Update the demo data
    DemoDataProvider.toggleMonitoring(campgroundId);
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
    // Demo version - search queries handled by StateProvider
    await Future.delayed(const Duration(milliseconds: 100));
  }
}