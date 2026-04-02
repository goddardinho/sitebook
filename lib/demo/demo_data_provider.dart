import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/campground.dart';

/// Demo data provider for immediate UX testing
/// Provides sample campgrounds without database dependency
class DemoDataProvider {
  static final List<Campground> _sampleCampgrounds = [
    const Campground(
      id: 'demo_1',
      name: 'Yosemite Valley Campground',
      description:
          'Stunning wilderness camping surrounded by towering granite cliffs and pristine forests. Wake up to incredible views of Half Dome and El Capitan.',
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
        'Showers',
        'Phone Service',
      ],
      activities: const [
        'Hiking',
        'Rock Climbing',
        'Photography',
        'Wildlife Viewing',
        'Fishing',
        'Stargazing',
      ],
      imageUrls: const [],
      reservationUrl: 'https://recreation.gov/camping/campgrounds/232447',
      phoneNumber: '209-372-0200',
      isMonitored: false,
    ),

    const Campground(
      id: 'demo_2',
      name: 'Big Sur Coastal Paradise',
      description:
          'Breathtaking oceanfront camping with dramatic coastal views and rugged hiking trails along the Pacific Coast Highway.',
      latitude: 36.2704,
      longitude: -121.8081,
      state: 'CA',
      amenities: const [
        'Restrooms',
        'Showers',
        'Fire Rings',
        'Water',
        'Picnic Tables',
        'Beach Access',
      ],
      activities: const [
        'Hiking',
        'Beach Walking',
        'Surfing',
        'Bird Watching',
        'Photography',
        'Tide Pooling',
      ],
      imageUrls: const [],
      isMonitored: true, // This one is being monitored
    ),

    const Campground(
      id: 'demo_3',
      name: 'Lake Tahoe Alpine Retreat',
      description:
          'High elevation mountain camping with crystal clear lake views, excellent fishing, and alpine hiking trails.',
      latitude: 39.0968,
      longitude: -120.0324,
      state: 'CA',
      amenities: const [
        'Restrooms',
        'Fire Pits',
        'Boat Launch',
        'Picnic Tables',
        'Water',
        'Fishing Pier',
      ],
      activities: const [
        'Fishing',
        'Boating',
        'Swimming',
        'Hiking',
        'Kayaking',
        'Mountain Biking',
      ],
      imageUrls: const [],
      isMonitored: false,
    ),

    const Campground(
      id: 'demo_4',
      name: 'Joshua Tree Desert Camp',
      description:
          'Unique desert camping experience among iconic Joshua Trees and fascinating rock formations perfect for climbing.',
      latitude: 33.8734,
      longitude: -115.9010,
      state: 'CA',
      parkName: 'Joshua Tree National Park',
      amenities: const [
        'Restrooms',
        'Fire Rings',
        'Picnic Tables',
        'Water (Limited)',
      ],
      activities: const [
        'Hiking',
        'Rock Climbing',
        'Stargazing',
        'Photography',
        'Desert Exploration',
        'Nature Study',
      ],
      imageUrls: const [],
      reservationUrl: 'https://recreation.gov/camping/campgrounds/232427',
      isMonitored: true, // This one is being monitored
    ),

    const Campground(
      id: 'demo_5',
      name: 'Sequoia Giant Forest',
      description:
          'Camp among ancient giant sequoia trees in this pristine mountain forest setting with incredible hiking.',
      latitude: 36.5647,
      longitude: -118.7732,
      state: 'CA',
      parkName: 'Sequoia National Park',
      amenities: const [
        'Restrooms',
        'Water',
        'Fire Pits',
        'Bear Lockers',
        'Picnic Tables',
        'Interpretive Programs',
      ],
      activities: const [
        'Hiking',
        'Wildlife Viewing',
        'Photography',
        'Ranger Programs',
        'Nature Walks',
      ],
      imageUrls: const [],
      isMonitored: false,
    ),

    const Campground(
      id: 'demo_6',
      name: 'Zion Canyon Basecamp',
      description:
          'Gateway to spectacular red rock canyons and world-class hiking trails in Zion National Park.',
      latitude: 37.2002,
      longitude: -113.0164,
      state: 'UT',
      parkName: 'Zion National Park',
      amenities: const [
        'Restrooms',
        'Showers',
        'Fire Rings',
        'Water',
        'Picnic Tables',
        'Shuttle Access',
      ],
      activities: const [
        'Hiking',
        'Canyoneering',
        'Photography',
        'Rock Climbing',
        'Wildlife Viewing',
        'River Tubing',
      ],
      imageUrls: const [],
      reservationUrl: 'https://recreation.gov/camping/campgrounds/232475',
      phoneNumber: '435-772-3256',
      isMonitored: true, // This one is being monitored
    ),
  ];

  static List<Campground> getAllCampgrounds() => _sampleCampgrounds;

  static List<Campground> getMonitoredCampgrounds() =>
      _sampleCampgrounds.where((c) => c.isMonitored).toList();

  static List<Campground> getCampgroundsByState(String state) =>
      _sampleCampgrounds.where((c) => c.state == state).toList();

  static List<Campground> searchByQuery(String query) => _sampleCampgrounds
      .where(
        (c) =>
            c.name.toLowerCase().contains(query.toLowerCase()) ||
            c.description.toLowerCase().contains(query.toLowerCase()) ||
            c.parkName?.toLowerCase().contains(query.toLowerCase()) == true,
      )
      .toList();

  static Campground? getCampgroundById(String id) {
    try {
      return _sampleCampgrounds.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  static void toggleMonitoring(String id) {
    final index = _sampleCampgrounds.indexWhere((c) => c.id == id);
    if (index != -1) {
      final campground = _sampleCampgrounds[index];
      _sampleCampgrounds[index] = campground.copyWith(
        isMonitored: !campground.isMonitored,
      );
    }
  }
}

// Demo providers for immediate UX testing
final demoCampgroundsProvider = Provider<List<Campground>>((ref) {
  return DemoDataProvider.getAllCampgrounds();
});

final demoMonitoredCampgroundsProvider = Provider<List<Campground>>((ref) {
  return DemoDataProvider.getMonitoredCampgrounds();
});

final demoSearchProvider = Provider.family<List<Campground>, String>((
  ref,
  query,
) {
  if (query.isEmpty) return DemoDataProvider.getAllCampgrounds();
  return DemoDataProvider.searchByQuery(query);
});

final demoStateProvider = Provider.family<List<Campground>, String>((
  ref,
  state,
) {
  return DemoDataProvider.getCampgroundsByState(state);
});
