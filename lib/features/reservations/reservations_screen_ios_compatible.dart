import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'my_reservations_screen.dart';

// Demo reservation data
class Reservation {
  final String id;
  final String campgroundName;
  final String parkName;
  final String state;
  final DateTime startDate;
  final DateTime endDate;
  final String siteNumber;
  final String status; // confirmed, pending, cancelled
  final double cost;
  final int nights;

  const Reservation({
    required this.id,
    required this.campgroundName,
    required this.parkName,
    required this.state,
    required this.startDate,
    required this.endDate,
    required this.siteNumber,
    required this.status,
    required this.cost,
    required this.nights,
  });
}

// Demo reservations provider
final reservationsProvider = FutureProvider<List<Reservation>>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 800));

  return [
    Reservation(
      id: 'res_001',
      campgroundName: 'Yosemite Valley Campground',
      parkName: 'Yosemite National Park',
      state: 'CA',
      startDate: DateTime.now().add(const Duration(days: 45)),
      endDate: DateTime.now().add(const Duration(days: 48)),
      siteNumber: 'A-23',
      status: 'confirmed',
      cost: 180.00,
      nights: 3,
    ),
    Reservation(
      id: 'res_002',
      campgroundName: 'Big Sur Coastal Paradise',
      parkName: 'Julia Pfeiffer Burns State Park',
      state: 'CA',
      startDate: DateTime.now().add(const Duration(days: 21)),
      endDate: DateTime.now().add(const Duration(days: 23)),
      siteNumber: 'C-12',
      status: 'confirmed',
      cost: 120.00,
      nights: 2,
    ),
    Reservation(
      id: 'res_003',
      campgroundName: 'Grand Canyon Village',
      parkName: 'Grand Canyon National Park',
      state: 'AZ',
      startDate: DateTime.now().add(const Duration(days: 120)),
      endDate: DateTime.now().add(const Duration(days: 125)),
      siteNumber: 'B-45',
      status: 'pending',
      cost: 250.00,
      nights: 5,
    ),
    Reservation(
      id: 'res_004',
      campgroundName: 'Glacier Point Campground',
      parkName: 'Yosemite National Park',
      state: 'CA',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().subtract(const Duration(days: 27)),
      siteNumber: 'D-07',
      status: 'completed',
      cost: 160.00,
      nights: 3,
    ),
  ];
});

class ReservationsScreenIOSCompatible extends ConsumerWidget {
  const ReservationsScreenIOSCompatible({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reservationsAsync = ref.watch(reservationsProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 100,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.sync_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MyReservationsScreen(),
                      ),
                    );
                  },
                  tooltip: 'View Live Reservations',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'My Reservations',
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
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Live Reservations Link Banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: Card(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MyReservationsScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sync_outlined,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'View Live Reservations',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Connect to Recreation.gov for your actual reservations',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Demo reservations content
            Expanded(
              child: reservationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(context, theme),
                data: (reservations) =>
                    _buildReservationsList(context, theme, reservations),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Unable to load reservations',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList(
    BuildContext context,
    ThemeData theme,
    List<Reservation> reservations,
  ) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No reservations yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book your first camping adventure!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    // Group reservations by status
    final upcoming = reservations
        .where(
          (r) => r.status == 'confirmed' && r.startDate.isAfter(DateTime.now()),
        )
        .toList();
    final pending = reservations.where((r) => r.status == 'pending').toList();
    final past = reservations
        .where(
          (r) =>
              r.status == 'completed' || r.startDate.isBefore(DateTime.now()),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (upcoming.isNotEmpty) ...[
          _buildSectionHeader(
            theme,
            'Upcoming Trips',
            Icons.upcoming,
            upcoming.length,
          ),
          const SizedBox(height: 8),
          ...upcoming.map(
            (reservation) => _buildReservationCard(context, theme, reservation),
          ),
          const SizedBox(height: 24),
        ],
        if (pending.isNotEmpty) ...[
          _buildSectionHeader(
            theme,
            'Pending Requests',
            Icons.hourglass_empty,
            pending.length,
          ),
          const SizedBox(height: 8),
          ...pending.map(
            (reservation) => _buildReservationCard(context, theme, reservation),
          ),
          const SizedBox(height: 24),
        ],
        if (past.isNotEmpty) ...[
          _buildSectionHeader(theme, 'Past Trips', Icons.history, past.length),
          const SizedBox(height: 8),
          ...past.map(
            (reservation) => _buildReservationCard(context, theme, reservation),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    IconData icon,
    int count,
  ) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReservationCard(
    BuildContext context,
    ThemeData theme,
    Reservation reservation,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showReservationDetails(context, reservation),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with campground name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reservation.campgroundName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(theme, reservation.status),
                ],
              ),
              const SizedBox(height: 4),

              // Park name and location
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${reservation.parkName}, ${reservation.state}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date range and site info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateRange(
                            reservation.startDate,
                            reservation.endDate,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Site ${reservation.siteNumber} • ${reservation.nights} nights',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${reservation.cost.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'total',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, String status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case 'confirmed':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        statusText = 'Confirmed';
        break;
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade700;
        statusText = 'Pending';
        break;
      case 'completed':
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        statusText = 'Completed';
        break;
      default:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        statusText = 'Cancelled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (start.month == end.month) {
      return '${months[start.month - 1]} ${start.day}-${end.day}, ${start.year}';
    } else {
      return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}, ${start.year}';
    }
  }

  void _showReservationDetails(BuildContext context, Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reservation.campgroundName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Park:', reservation.parkName),
            _buildDetailRow('Location:', reservation.state),
            _buildDetailRow(
              'Dates:',
              _formatDateRange(reservation.startDate, reservation.endDate),
            ),
            _buildDetailRow('Site:', reservation.siteNumber),
            _buildDetailRow('Nights:', '${reservation.nights}'),
            _buildDetailRow('Status:', reservation.status.toUpperCase()),
            _buildDetailRow(
              'Total Cost:',
              '\$${reservation.cost.toStringAsFixed(2)}',
            ),
            if (reservation.status == 'confirmed') ...[
              const SizedBox(height: 16),
              const Text(
                'Booking confirmed! Check-in after 2:00 PM on arrival date.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (reservation.status == 'confirmed' &&
              reservation.startDate.isAfter(DateTime.now()))
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Modify reservation feature coming soon!'),
                  ),
                );
              },
              child: const Text('Modify'),
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
}
