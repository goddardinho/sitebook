import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/campground.dart';
import '../../demo/demo_data_provider.dart';
import 'dart:math' as math;

// Demo location data
class UserLocation {
  final double latitude;
  final double longitude;
  final String displayName;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}

// Demo location provider - simulates user's current location
final userLocationProvider = FutureProvider<UserLocation>((ref) async {
  await Future.delayed(const Duration(milliseconds: 500));

  // Default location: San Francisco Bay Area for demo
  return const UserLocation(
    latitude: 37.7749,
    longitude: -122.4194,
    displayName: 'San Francisco Bay Area, CA',
  );
});

// Provider for campgrounds with distance calculations
final nearbyCampgroundsProvider = FutureProvider<List<CampgroundWithDistance>>((
  ref,
) async {
  final userLocation = await ref.watch(userLocationProvider.future);
  final campgrounds = DemoDataProvider.getAllCampgrounds();

  return campgrounds.map((campground) {
    final distance = _calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      campground.latitude,
      campground.longitude,
    );

    return CampgroundWithDistance(campground: campground, distance: distance);
  }).toList()..sort((a, b) => a.distance.compareTo(b.distance));
});

class CampgroundWithDistance {
  final Campground campground;
  final double distance;

  const CampgroundWithDistance({
    required this.campground,
    required this.distance,
  });
}

// Calculate distance between two points using Haversine formula
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // Earth's radius in kilometers

  final double dLat = (lat2 - lat1) * (math.pi / 180);
  final double dLon = (lon2 - lon1) * (math.pi / 180);

  final double a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * (math.pi / 180)) *
          math.cos(lat2 * (math.pi / 180)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  final double distance = earthRadius * c;

  return distance;
}

class MapScreenIOSCompatible extends ConsumerStatefulWidget {
  const MapScreenIOSCompatible({super.key});

  @override
  ConsumerState<MapScreenIOSCompatible> createState() =>
      _MapScreenIOSCompatibleState();
}

class _MapScreenIOSCompatibleState
    extends ConsumerState<MapScreenIOSCompatible> {
  String _selectedFilter = 'all'; // all, monitored, available

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userLocationAsync = ref.watch(userLocationProvider);
    final nearbyCampgroundsAsync = ref.watch(nearbyCampgroundsProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Nearby Campgrounds',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withAlpha(230),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          userLocationAsync.when(
                            data: (location) => Row(
                              children: [
                                Icon(
                                  Icons.my_location,
                                  size: 16,
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    location.displayName,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onPrimary
                                          .withValues(alpha: 0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            loading: () => const SizedBox(height: 20),
                            error: (_, __) => const SizedBox(height: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Filter chips
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', theme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Monitored', 'monitored', theme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Available', 'available', theme),
                ],
              ),
            ),

            // Campgrounds list
            Expanded(
              child: nearbyCampgroundsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(theme),
                data: (campgroundsWithDistance) =>
                    _buildCampgroundsList(theme, campgroundsWithDistance),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMapInfo(context),
        tooltip: 'Map Info',
        child: const Icon(Icons.info_outline),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Unable to load nearby campgrounds',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your location settings and try again',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCampgroundsList(
    ThemeData theme,
    List<CampgroundWithDistance> campgroundsWithDistance,
  ) {
    // Apply filter
    List<CampgroundWithDistance> filteredCampgrounds;

    switch (_selectedFilter) {
      case 'monitored':
        filteredCampgrounds = campgroundsWithDistance
            .where((item) => item.campground.isMonitored)
            .toList();
        break;
      case 'available':
        // For demo, assume some campgrounds are "available"
        filteredCampgrounds = campgroundsWithDistance
            .where((item) => item.distance < 200) // Within 200km
            .toList();
        break;
      default:
        filteredCampgrounds = campgroundsWithDistance;
    }

    if (filteredCampgrounds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.terrain,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No campgrounds found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              'Try adjusting your filter settings',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredCampgrounds.length,
      itemBuilder: (context, index) {
        final item = filteredCampgrounds[index];
        return _buildCampgroundCard(theme, item);
      },
    );
  }

  Widget _buildCampgroundCard(
    ThemeData theme,
    CampgroundWithDistance campgroundWithDistance,
  ) {
    final campground = campgroundWithDistance.campground;
    final distance = campgroundWithDistance.distance;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCampgroundDetails(context, campground, distance),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name, distance, and monitor status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campground.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              campground.state,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${distance.round()} km',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (campground.isMonitored)
                        Icon(
                          Icons.visibility,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                campground.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Amenities (show first 2)
              if (campground.amenities.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: campground.amenities.take(2).map<Widget>((amenity) {
                    return Chip(
                      label: Text(amenity, style: theme.textTheme.labelSmall),
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCampgroundDetails(
    BuildContext context,
    Campground campground,
    double distance,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(campground.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Distance:', '${distance.round()} km away'),
              _buildDetailRow('State:', campground.state),
              if (campground.parkName != null)
                _buildDetailRow('Park:', campground.parkName!),
              _buildDetailRow(
                'Monitored:',
                campground.isMonitored ? 'Yes' : 'No',
              ),
              const SizedBox(height: 8),
              const Text(
                'Description:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(campground.description),
              if (campground.amenities.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Amenities:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: campground.amenities.map<Widget>((amenity) {
                    return Chip(
                      label: Text(
                        amenity,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.grey.shade100,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Directions to ${campground.name}'),
                  action: SnackBarAction(
                    label: 'GPS',
                    onPressed: () {
                      // In a real app, this would open maps or navigation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('GPS navigation coming soon!'),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            child: const Text('Directions'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showMapInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About This Map'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is a simplified map view optimized for iOS compatibility.',
            ),
            SizedBox(height: 8),
            Text('Features:', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('• Distance-based sorting'),
            Text('• Filter by monitoring status'),
            Text('• Detailed campground information'),
            Text('• iOS-optimized performance'),
            SizedBox(height: 8),
            Text(
              'Interactive map features will be added in future updates.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
