import 'package:flutter/material.dart';
import '../../../../shared/models/campground.dart';

class CampgroundActionButtons extends StatelessWidget {
  final Campground campground;
  final VoidCallback onReservePressed;
  final VoidCallback onDirectionsPressed;
  final VoidCallback onSharePressed;

  const CampgroundActionButtons({
    super.key,
    required this.campground,
    required this.onReservePressed,
    required this.onDirectionsPressed,
    required this.onSharePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Primary action (Reserve)
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onReservePressed,
            icon: const Icon(Icons.book_online),
            label: const Text('Make Reservation'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary actions
        Row(
          children: [
            // Directions
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDirectionsPressed,
                icon: const Icon(Icons.directions),
                label: const Text('Directions'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Share
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSharePressed,
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Quick info chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (campground.phoneNumber != null)
              _buildInfoChip(
                context,
                icon: Icons.phone,
                label: 'Phone Available',
                color: theme.colorScheme.tertiary,
              ),
            if (campground.email != null)
              _buildInfoChip(
                context,
                icon: Icons.email,
                label: 'Email Contact',
                color: theme.colorScheme.tertiary,
              ),
            if (campground.amenities.contains('WiFi') ||
                campground.amenities.contains('Internet'))
              _buildInfoChip(
                context,
                icon: Icons.wifi,
                label: 'WiFi Available',
                color: theme.colorScheme.secondary,
              ),
            _buildInfoChip(
              context,
              icon: Icons.location_on,
              label: campground.state,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(102), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
