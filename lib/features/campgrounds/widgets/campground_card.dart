import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/campground.dart';
import '../../../shared/providers/campground_providers_demo.dart';
import '../details/campground_details_screen.dart';

class CampgroundCard extends ConsumerWidget {
  final Campground campground;

  const CampgroundCard({super.key, required this.campground});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actions = ref.watch(campgroundActionsProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                // Main image
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: campground.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: Image.network(
                            campground.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderImage(theme),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildPlaceholderImage(theme);
                            },
                          ),
                        )
                      : _buildPlaceholderImage(theme),
                ),
                // Monitoring status badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: campground.isMonitored
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest.withAlpha(
                              200,
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          campground.isMonitored
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 14,
                          color: campground.isMonitored
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          campground.isMonitored
                              ? 'Monitoring'
                              : 'Not Monitored',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: campground.isMonitored
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and state
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
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
                                if (campground.parkName != null) ...[
                                  Text(
                                    ' • ',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      campground.parkName!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Monitor button
                      IconButton.filledTonal(
                        onPressed: () => actions.toggleMonitoring(
                          campground.id,
                          !campground.isMonitored,
                        ),
                        icon: Icon(
                          campground.isMonitored
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        tooltip: campground.isMonitored
                            ? 'Stop monitoring'
                            : 'Start monitoring',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    campground.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Amenities chips (show first 3)
                  if (campground.amenities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: campground.amenities.take(3).map((amenity) {
                        return Chip(
                          label: Text(
                            amenity,
                            style: theme.textTheme.labelSmall,
                          ),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          side: BorderSide.none,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _viewDetails(context, campground),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('View Details'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _makeReservation(context, campground),
                          icon: const Icon(Icons.book_online, size: 18),
                          label: const Text('Reserve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CampgroundDetailsScreen(campground: campground),
      ),
    );
  }

  Widget _buildPlaceholderImage(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.nature_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
          ),
          const SizedBox(height: 8),
          Text(
            'No Image Available',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }

  void _viewDetails(BuildContext context, Campground campground) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CampgroundDetailsScreen(campground: campground),
      ),
    );
  }

  void _makeReservation(BuildContext context, Campground campground) {
    // TODO: Navigate to reservation screen or open external URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Make reservation for ${campground.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
