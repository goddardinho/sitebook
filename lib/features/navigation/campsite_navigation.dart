import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/campground.dart';
import '../../shared/models/campsite.dart';
import '../../core/utils/app_logger.dart';
import '../campgrounds/campsite_selection_screen.dart';

/// Navigation helper for campsite-related routes
class CampsiteNavigation {
  /// Navigate to campsite selection for a specific campground
  static Future<void> selectCampsites(
    BuildContext context,
    Campground campground,
  ) async {
    try {
      AppLogger.info(
        '🧭 Navigating to campsite selection for: ${campground.name}',
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CampsiteSelectionScreen(
            campground: campground,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 1)),
            guestCount: 2,
          ),
          settings: RouteSettings(
            name: '/campground/${campground.id}/campsites',
            arguments: {'campground': campground},
          ),
        ),
      );
    } catch (e) {
      AppLogger.error('❌ Failed to navigate to campsite selection', e);
    }
  }

  /// Navigate back to campground details with optional refresh
  static void backToCampgroundDetails(
    BuildContext context, {
    bool refresh = false,
    Map<String, dynamic>? result,
  }) {
    try {
      AppLogger.info('🧭 Navigating back to campground details');

      Navigator.of(context).pop(result);

      if (refresh) {
        // Trigger refresh of campground details if needed
        AppLogger.debug('🔄 Triggering campground details refresh');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to navigate back to campground details', e);
    }
  }

  /// Show campsite details in a bottom sheet or dialog
  static Future<T?> showCampsiteDetails<T>(
    BuildContext context,
    Campsite campsite, {
    DateTime? checkInDate,
    DateTime? checkOutDate,
  }) async {
    try {
      AppLogger.info('📋 Showing campsite details: ${campsite.siteNumber}');

      return await showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CampsiteDetailsSheet(
          campsite: campsite,
          checkInDate: checkInDate,
          checkOutDate: checkOutDate,
        ),
      );
    } catch (e) {
      AppLogger.error('❌ Failed to show campsite details', e);
      return null;
    }
  }

  /// Navigate to reservation page (external or internal)
  static Future<void> goToReservation(
    BuildContext context,
    Campsite campsite, {
    DateTime? checkInDate,
    DateTime? checkOutDate,
  }) async {
    try {
      AppLogger.info(
        '🎫 Navigating to reservation for campsite: ${campsite.siteNumber}',
      );

      // For now, just show a placeholder
      // TODO: Implement actual reservation navigation
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reserve Campsite'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Campsite: ${campsite.siteNumber}'),
              if (checkInDate != null)
                Text('Check-in: ${_formatDate(checkInDate)}'),
              if (checkOutDate != null)
                Text('Check-out: ${_formatDate(checkOutDate)}'),
              if (campsite.pricePerNight != null)
                Text(
                  'Price: \$${campsite.pricePerNight!.toStringAsFixed(2)}/night',
                ),
              const SizedBox(height: 16),
              const Text(
                'This will redirect to Recreation.gov for reservation.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Open Recreation.gov URL
                AppLogger.info('🌐 Opening Recreation.gov for reservation');
              },
              child: const Text('Continue to Recreation.gov'),
            ),
          ],
        ),
      );
    } catch (e) {
      AppLogger.error('❌ Failed to navigate to reservation', e);
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Bottom sheet widget for campsite details
class CampsiteDetailsSheet extends ConsumerWidget {
  final Campsite campsite;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;

  const CampsiteDetailsSheet({
    super.key,
    required this.campsite,
    this.checkInDate,
    this.checkOutDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Campsite ${campsite.siteNumber}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Availability status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: campsite.isAvailable
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      campsite.isAvailable ? 'Available' : 'Not Available',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Site details
                  _buildDetailRow('Site Type', campsite.siteType),
                  _buildDetailRow('Max Occupancy', '${campsite.maxOccupancy}'),
                  if (campsite.pricePerNight != null)
                    _buildDetailRow(
                      'Price per Night',
                      '\$${campsite.pricePerNight!.toStringAsFixed(2)}',
                    ),
                  _buildDetailRow(
                    'Accessible',
                    campsite.accessibility ? 'Yes' : 'No',
                  ),

                  if (campsite.amenities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Amenities',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: campsite.amenities
                          .map(
                            (amenity) => Chip(
                              label: Text(amenity),
                              backgroundColor: Colors.blue.withOpacity(0.1),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  if (checkInDate != null && checkOutDate != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Selected Dates',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Check-in',
                      CampsiteNavigation._formatDate(checkInDate!),
                    ),
                    _buildDetailRow(
                      'Check-out',
                      CampsiteNavigation._formatDate(checkOutDate!),
                    ),

                    if (campsite.pricePerNight != null) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          final nights = checkOutDate!
                              .difference(checkInDate!)
                              .inDays;
                          final totalCost = campsite.pricePerNight! * nights;
                          return _buildDetailRow(
                            'Total Cost',
                            '\$${totalCost.toStringAsFixed(2)} ($nights nights)',
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: campsite.isAvailable
                        ? () {
                            Navigator.pop(context);
                            // TODO: Add to monitoring
                            AppLogger.info('💾 Adding campsite to monitoring');
                          }
                        : null,
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('Monitor'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: campsite.isAvailable
                        ? () {
                            Navigator.pop(context);
                            CampsiteNavigation.goToReservation(
                              context,
                              campsite,
                              checkInDate: checkInDate,
                              checkOutDate: checkOutDate,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Reserve'),
                  ),
                ),
              ],
            ),
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
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
