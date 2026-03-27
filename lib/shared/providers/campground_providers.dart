import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/campground.dart';
import '../data/sample_campgrounds.dart';

// Provider for all campgrounds
final campgroundsProvider = Provider<List<Campground>>((ref) {
  return sampleCampgrounds;
});

// Provider for search query
final searchQueryProvider = Provider<String>((ref) => '');

// Provider for filtered campgrounds based on search
final filteredCampgroundsProvider = Provider<List<Campground>>((ref) {
  final campgrounds = ref.watch(campgroundsProvider);
  final query = ref.watch(searchQueryProvider);
  
  if (query.isEmpty) {
    return campgrounds;
  }
  
  return campgrounds.where((campground) {
    final name = campground.name.toLowerCase();
    final description = campground.description.toLowerCase();
    final state = campground.state.toLowerCase();
    final parkName = campground.parkName?.toLowerCase() ?? '';
    final searchLower = query.toLowerCase();
    
    return name.contains(searchLower) || 
           description.contains(searchLower) ||
           state.contains(searchLower) ||
           parkName.contains(searchLower);
  }).toList();
});

// Provider for monitored campgrounds count
final monitoredCountProvider = Provider<int>((ref) {
  final campgrounds = ref.watch(campgroundsProvider);
  return campgrounds.where((c) => c.isMonitored).length;
});

// Provider for toggling campground monitoring status
final campgroundActionsProvider = Provider((ref) {
  return CampgroundActions(ref);
});

class CampgroundActions {
  final Ref ref;
  
  CampgroundActions(this.ref);
  
  void toggleMonitoring(String campgroundId) {
    // For now, just log the action
    // TODO: Implement state management with StateNotifier or similar
    print('Toggling monitoring for campground: $campgroundId');
  }
  
  void updateSearchQuery(String query) {
    // For now, just log the search query
    // TODO: Implement search state management
    print('Updating search query to: $query');
  }
}