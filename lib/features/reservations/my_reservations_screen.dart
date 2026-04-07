import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/reservation_providers.dart';
import '../../shared/models/reservation.dart';

class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reservationsAsync = ref.watch(userReservationsProvider);
    final upcomingReservations = ref.watch(upcomingReservationsProvider);
    final pastReservations = ref.watch(pastReservationsProvider);
    final activeReservations = ref.watch(activeReservationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () => ref.refresh(userReservationsProvider),
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh Reservations',
          ),
        ],
      ),
      body: reservationsAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your reservations...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load reservations',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(userReservationsProvider),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
        data: (reservations) => reservations.isEmpty
            ? _buildEmptyState(context, theme)
            : _buildReservationsList(
                context,
                theme,
                ref,
                reservations,
                upcomingReservations.value ?? [],
                pastReservations.value ?? [],
                activeReservations.value ?? [],
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Reservations Yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start planning your next camping adventure!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Browse Campgrounds'),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    List<Reservation> allReservations,
    List<Reservation> upcoming,
    List<Reservation> past,
    List<Reservation> active,
  ) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // Tab bar
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: TabBar(
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              tabs: [
                Tab(text: 'All (${allReservations.length})'),
                Tab(text: 'Active (${active.length})'),
                Tab(text: 'Upcoming (${upcoming.length})'),
                Tab(text: 'Past (${past.length})'),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              children: [
                _buildReservationList(context, theme, ref, allReservations),
                _buildReservationList(context, theme, ref, active),
                _buildReservationList(context, theme, ref, upcoming),
                _buildReservationList(context, theme, ref, past),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationList(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    List<Reservation> reservations,
  ) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No reservations in this category',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(userReservationsProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final reservation = reservations[index];
          return _buildReservationCard(context, theme, ref, reservation);
        },
      ),
    );
  }

  Widget _buildReservationCard(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    Reservation reservation,
  ) {
    final now = DateTime.now();
    final isActive =
        now.isAfter(reservation.checkInDate) &&
        now.isBefore(reservation.checkOutDate);
    final isPast = now.isAfter(reservation.checkOutDate);
    final canCancel =
        !isPast && reservation.status != ReservationStatus.cancelled;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Text(
                    reservation.campgroundName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatusChip(theme, reservation.status, isActive, isPast),
              ],
            ),

            const SizedBox(height: 12),

            // Dates
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(reservation.checkInDate)} - ${_formatDate(reservation.checkOutDate)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Guests and campsite
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${reservation.guestCount} guest${reservation.guestCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.nature_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  reservation.siteNumber,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            if (reservation.specialRequests?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reservation.specialRequests!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons
            if (canCancel || !isPast) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isPast)
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showReservationDetails(context, reservation),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                    ),

                  if (canCancel) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () =>
                          _showCancelDialog(context, ref, reservation),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    ThemeData theme,
    ReservationStatus status,
    bool isActive,
    bool isPast,
  ) {
    Color backgroundColor;
    Color foregroundColor;
    String label;
    IconData icon;

    if (status == ReservationStatus.cancelled) {
      backgroundColor = theme.colorScheme.error;
      foregroundColor = theme.colorScheme.onError;
      label = 'Cancelled';
      icon = Icons.cancel_outlined;
    } else if (isActive) {
      backgroundColor = theme.colorScheme.primary;
      foregroundColor = theme.colorScheme.onPrimary;
      label = 'Active';
      icon = Icons.check_circle_outline;
    } else if (isPast) {
      backgroundColor = theme.colorScheme.outline;
      foregroundColor = theme.colorScheme.onSurface;
      label = 'Completed';
      icon = Icons.history;
    } else {
      backgroundColor = theme.colorScheme.tertiary;
      foregroundColor = theme.colorScheme.onTertiary;
      label = 'Upcoming';
      icon = Icons.schedule_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}';
  }

  void _showReservationDetails(BuildContext context, Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reservation.campgroundName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Reservation ID', reservation.id),
              _buildDetailRow('Check-in', _formatDate(reservation.checkInDate)),
              _buildDetailRow(
                'Check-out',
                _formatDate(reservation.checkOutDate),
              ),
              _buildDetailRow('Guests', reservation.guestCount.toString()),
              _buildDetailRow('Campsite Type', reservation.siteNumber),
              if (reservation.specialRequests?.isNotEmpty == true)
                _buildDetailRow(
                  'Special Requests',
                  reservation.specialRequests!,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    Reservation reservation,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: Text(
          'Are you sure you want to cancel your reservation at ${reservation.campgroundName}?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Reservation'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _cancelReservation(context, ref, reservation);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel Reservation'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelReservation(
    BuildContext context,
    WidgetRef ref,
    Reservation reservation,
  ) async {
    try {
      await ref.read(reservationCancellationProvider(reservation.id).future);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the reservations list
        ref.invalidate(userReservationsProvider);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel reservation: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
