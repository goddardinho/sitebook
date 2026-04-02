import 'package:flutter/material.dart';
import '../../../../shared/models/campground.dart';

class CampgroundInfoSection extends StatelessWidget {
  final Campground campground;

  const CampgroundInfoSection({super.key, required this.campground});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderSection(context),
        const SizedBox(height: 24),
        _buildDescriptionSection(context),
        const SizedBox(height: 24),
        _buildLocationSection(context),
        const SizedBox(height: 24),
        _buildAmenitiesSection(context),
        const SizedBox(height: 24),
        _buildActivitiesSection(context),
        const SizedBox(height: 24),
        _buildContactSection(context),
      ],
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campground.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (campground.parkName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.park_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    campground.parkName!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                campground.state,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (campground.isMonitored)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 14,
                        color: theme.colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Monitoring',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            campground.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha(77),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.my_location, color: theme.colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coordinates',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${campground.latitude.toStringAsFixed(6)}, ${campground.longitude.toStringAsFixed(6)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/maps',
                        arguments: campground,
                      );
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View on Map'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(BuildContext context) {
    final theme = Theme.of(context);

    if (campground.amenities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: campground.amenities.map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(77),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getAmenityIcon(amenity),
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      amenity,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection(BuildContext context) {
    final theme = Theme.of(context);

    if (campground.activities.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activities',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: campground.activities.map((activity) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withAlpha(77),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getActivityIcon(activity),
                      size: 16,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activity,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    final theme = Theme.of(context);

    final hasContact =
        campground.phoneNumber != null ||
        campground.email != null ||
        campground.reservationUrl != null;

    if (!hasContact) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha(77),
              ),
            ),
            child: Column(
              children: [
                if (campground.phoneNumber != null) ...[
                  _buildContactRow(
                    context,
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: campground.phoneNumber!,
                    onTap: () {
                      // TODO: Launch phone call
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling ${campground.phoneNumber}...'),
                        ),
                      );
                    },
                  ),
                  if (campground.email != null ||
                      campground.reservationUrl != null)
                    const Divider(height: 32),
                ],
                if (campground.email != null) ...[
                  _buildContactRow(
                    context,
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: campground.email!,
                    onTap: () {
                      // TODO: Launch email
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Opening email to ${campground.email}...',
                          ),
                        ),
                      );
                    },
                  ),
                  if (campground.reservationUrl != null)
                    const Divider(height: 32),
                ],
                if (campground.reservationUrl != null)
                  _buildContactRow(
                    context,
                    icon: Icons.web_outlined,
                    label: 'Reservations',
                    value: 'Book online at Recreation.gov',
                    onTap: () {
                      // TODO: Launch web URL
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening reservation website...'),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'restrooms':
      case 'bathrooms':
        return Icons.wc;
      case 'potable water':
      case 'water':
        return Icons.water_drop;
      case 'fire rings':
      case 'fire pits':
        return Icons.local_fire_department;
      case 'picnic tables':
        return Icons.table_restaurant;
      case 'dump station':
        return Icons.cleaning_services;
      case 'amphitheater':
        return Icons.theater_comedy;
      case 'showers':
        return Icons.shower;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'store':
      case 'camp store':
        return Icons.store;
      case 'visitors center':
        return Icons.info;
      case 'wifi':
      case 'internet':
        return Icons.wifi;
      default:
        return Icons.check_circle_outline;
    }
  }

  IconData _getActivityIcon(String activity) {
    switch (activity.toLowerCase()) {
      case 'wildlife viewing':
        return Icons.pets;
      case 'fishing':
        return Icons.phishing;
      case 'hiking':
        return Icons.hiking;
      case 'photography':
        return Icons.camera_alt;
      case 'stargazing':
        return Icons.nights_stay;
      case 'swimming':
        return Icons.pool;
      case 'boating':
        return Icons.directions_boat;
      case 'biking':
      case 'cycling':
        return Icons.directions_bike;
      case 'rock climbing':
        return Icons.terrain;
      case 'bird watching':
        return Icons.visibility;
      default:
        return Icons.outdoor_grill;
    }
  }
}
