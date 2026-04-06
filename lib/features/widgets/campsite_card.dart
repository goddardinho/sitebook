import 'package:flutter/material.dart';
import '../../shared/models/campsite.dart';

/// Card widget displaying campsite information with action buttons
class CampsiteCard extends StatelessWidget {
  final Campsite campsite;
  final DateTime startDate;
  final DateTime endDate;
  final int guestCount;
  final VoidCallback? onMonitorTap;
  final VoidCallback? onReserveTap;
  final VoidCallback? onDetailsTap;

  const CampsiteCard({
    super.key,
    required this.campsite,
    required this.startDate,
    required this.endDate,
    required this.guestCount,
    this.onMonitorTap,
    this.onReserveTap,
    this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildContent(context),
          _buildActions(context),
        ],
      ),
    );
  }

  /// Card header with site number and availability status
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: campsite.isAvailable
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      ),
      child: Row(
        children: [
          // Site number and type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Site ${campsite.siteNumber}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        campsite.siteType,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (campsite.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    campsite.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Availability status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: campsite.isAvailable
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  campsite.isAvailable ? Icons.check_circle : Icons.block,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  campsite.isAvailable ? 'Available' : 'Unavailable',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card content with details and pricing
  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Site details row
          Row(
            children: [
              _buildDetailChip(
                context,
                Icons.people,
                'Max ${campsite.maxOccupancy}',
              ),
              const SizedBox(width: 8),
              if (campsite.accessibility)
                _buildDetailChip(
                  context,
                  Icons.accessible,
                  'Accessible',
                  isPrimary: true,
                ),
              if (campsite.isMonitored) ...[
                const SizedBox(width: 8),
                _buildDetailChip(
                  context,
                  Icons.notifications_active,
                  'Monitoring',
                  isPrimary: true,
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Amenities
          if (campsite.amenities.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: campsite.amenities.take(4).map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    amenity,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Pricing information
          _buildPricingInfo(context),
        ],
      ),
    );
  }

  /// Pricing information section
  Widget _buildPricingInfo(BuildContext context) {
    final totalCost = campsite.getTotalCostForDates(startDate, endDate);
    final avgPrice = campsite.getAveragePriceForDates(startDate, endDate);

    if (totalCost == null &&
        avgPrice == null &&
        campsite.pricePerNight == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_money,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (totalCost != null) ...[
                  Text(
                    'Total: \$${totalCost.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${endDate.difference(startDate).inDays} nights',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else if (avgPrice != null) ...[
                  Text(
                    '\$${avgPrice.toStringAsFixed(2)}/night (avg)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (campsite.pricePerNight != null) ...[
                  Text(
                    '\$${campsite.pricePerNight!.toStringAsFixed(2)}/night',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (campsite.isAvailable && campsite.reservationUrl != null)
            OutlinedButton(
              onPressed: onReserveTap,
              style: OutlinedButton.styleFrom(minimumSize: const Size(80, 32)),
              child: const Text('Reserve'),
            ),
        ],
      ),
    );
  }

  /// Action buttons row
  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Row(
        children: [
          // Monitor button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onMonitorTap,
              icon: Icon(
                campsite.isMonitored
                    ? Icons.notifications_active
                    : Icons.add_alert,
                size: 18,
              ),
              label: Text(campsite.isMonitored ? 'Update' : 'Monitor'),
              style: OutlinedButton.styleFrom(
                foregroundColor: campsite.isMonitored
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Details button
          OutlinedButton.icon(
            onPressed: onDetailsTap,
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Details'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(100, 36)),
          ),
        ],
      ),
    );
  }

  /// Helper to build detail chips
  Widget _buildDetailChip(
    BuildContext context,
    IconData icon,
    String label, {
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isPrimary
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isPrimary
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
