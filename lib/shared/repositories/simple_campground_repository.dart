import '../../core/storage/campground_database.dart';
import '../models/campground.dart';
import 'campground_repository.dart';

/// Simplified repository for UX testing
/// Uses only database functionality without API integration
class SimpleCampgroundRepository implements CampgroundRepository {
  final CampgroundDatabase _database = CampgroundDatabase();

  Future<List<Campground>> getCampgroundsByLocation({
    required double latitude,
    required double longitude,
    required double radiusMiles,
    String? stateFilter,
  }) async {
    // Use database-only search for now
    if (stateFilter != null) {
      return await _database.getCampgroundsByState(stateFilter);
    }
    return await _database.searchNearby(
      latitude: latitude,
      longitude: longitude,
      radiusMiles: radiusMiles,
    );
  }

  @override
  Future<List<Campground>> getCampgroundsByState(String state) async {
    return await _database.getCampgroundsByState(state);
  }

  @override
  Future<List<Campground>> getAllCampgrounds() async {
    return await _database.getAllCampgrounds();
  }

  @override
  Future<List<Campground>> searchByQuery(String query) async {
    return await _database.searchByQuery(query);
  }

  @override
  Future<List<Campground>> getMonitoredCampgrounds() async {
    return await _database.getMonitoredCampgrounds();
  }

  @override
  Future<Campground?> getCampgroundById(String id) async {
    return await _database.getCampgroundById(id);
  }

  @override
  Future<void> updateMonitoringStatus(String id, bool isMonitored) async {
    return await _database.updateMonitoringStatus(id, isMonitored);
  }

  @override
  Future<void> saveCampground(Campground campground) async {
    return await _database.saveCampground(campground);
  }

  @override
  Future<void> saveCampgrounds(List<Campground> campgrounds) async {
    return await _database.saveCampgrounds(campgrounds);
  }

  @override
  Future<List<Campground>> searchNearby({
    required double latitude,
    required double longitude,
    required double radiusMiles,
    String? stateFilter,
  }) async {
    return await _database.searchNearby(
      latitude: latitude,
      longitude: longitude,
      radiusMiles: radiusMiles,
    );
  }

  Future<Map<String, dynamic>> getCampsiteAvailability({
    required String campgroundId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Mock availability for UX testing
    return {
      'available_dates': [],
      'unavailable_dates': [],
      'status': 'available',
    };
  }

  @override
  Future<Map<String, bool>> checkAvailability({
    required String campgroundId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Mock availability check
    return {
      startDate.toIso8601String().substring(0, 10): true,
      endDate.toIso8601String().substring(0, 10): true,
    };
  }

  @override
  Future<void> deleteCampground(String campgroundId) async {
    // Not implemented for UX testing
    return;
  }

  @override
  Future<void> clearCache() async {
    // Not needed for simplified version
    return;
  }

  @override
  Future<void> refresh() async {
    // Just sync with sample data
    await syncWithApis();
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    // Return current time as mock sync time
    return DateTime.now();
  }

  Future<void> syncWithApis() async {
    // Add some sample data for UX testing
    final sampleCampgrounds = [
      Campground(
        id: 'sample_1',
        name: 'Yosemite Valley Campground',
        description:
            'Beautiful wilderness camping in the heart of Yosemite National Park. Surrounded by towering granite cliffs and pristine forests.',
        latitude: 37.7459,
        longitude: -119.5873,
        state: 'CA',
        parkName: 'Yosemite National Park',
        amenities: const [
          'Restrooms',
          'Fire Pits',
          'Water',
          'Picnic Tables',
          'Bear Lockers',
        ],
        activities: const [
          'Hiking',
          'Rock Climbing',
          'Photography',
          'Wildlife Viewing',
        ],
        imageUrls: const [],
        reservationUrl: 'https://recreation.gov/camping/campgrounds/232447',
        phoneNumber: '209-372-0200',
      ),
      Campground(
        id: 'sample_2',
        name: 'Big Sur Coastal Camp',
        description:
            'Stunning oceanfront camping with dramatic coastal views and rugged hiking trails along the Pacific Coast.',
        latitude: 36.2704,
        longitude: -121.8081,
        state: 'CA',
        amenities: const ['Restrooms', 'Showers', 'Fire Rings', 'Water'],
        activities: const [
          'Hiking',
          'Beach Walking',
          'Surfing',
          'Bird Watching',
        ],
        imageUrls: const [],
      ),
      Campground(
        id: 'sample_3',
        name: 'Lake Tahoe Alpine Camp',
        description:
            'Mountain camping at high elevation with crystal clear lake views and excellent fishing opportunities.',
        latitude: 39.0968,
        longitude: -120.0324,
        state: 'CA',
        amenities: const [
          'Restrooms',
          'Fire Pits',
          'Boat Launch',
          'Picnic Tables',
        ],
        activities: const ['Fishing', 'Boating', 'Swimming', 'Hiking'],
        imageUrls: const [],
      ),
      Campground(
        id: 'sample_4',
        name: 'Joshua Tree Desert Camp',
        description:
            'Unique desert camping experience among iconic Joshua Trees and fascinating rock formations.',
        latitude: 33.8734,
        longitude: -115.9010,
        state: 'CA',
        parkName: 'Joshua Tree National Park',
        amenities: const ['Restrooms', 'Fire Rings', 'Picnic Tables'],
        activities: const [
          'Hiking',
          'Rock Climbing',
          'Stargazing',
          'Photography',
        ],
        imageUrls: const [],
        reservationUrl: 'https://recreation.gov/camping/campgrounds/232447',
      ),
      Campground(
        id: 'sample_5',
        name: 'Sequoia Giant Forest Camp',
        description:
            'Camp among ancient giant sequoia trees in this pristine mountain forest setting.',
        latitude: 36.5647,
        longitude: -118.7732,
        state: 'CA',
        parkName: 'Sequoia National Park',
        amenities: const ['Restrooms', 'Water', 'Fire Pits', 'Bear Lockers'],
        activities: const ['Hiking', 'Wildlife Viewing', 'Photography'],
        imageUrls: const [],
      ),
    ];

    // Save sample data
    await saveCampgrounds(sampleCampgrounds);
  }
}
