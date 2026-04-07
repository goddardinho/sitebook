import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/reservation_service.dart';
import '../services/recreation_gov_api_service.dart';
import '../../features/credentials/services/credential_storage_service.dart';
import '../models/reservation.dart';
import '../../core/utils/app_logger.dart';

/// Provider for the reservation service
final reservationServiceProvider = Provider<ReservationService>((ref) {
  final apiService = RecreationGovApiService.create();
  final credentialService = CredentialStorageService();

  return ReservationService(
    apiService: apiService,
    credentialService: credentialService,
  );
});

/// Provider for user reservations with automatic refresh
final userReservationsProvider = FutureProvider<List<Reservation>>((ref) async {
  final service = ref.read(reservationServiceProvider);
  return await service.getUserReservations();
});

/// Provider for refreshing user reservations
final refreshReservationsProvider =
    FutureProvider.family<List<Reservation>, bool>((ref, forceRefresh) async {
      final service = ref.read(reservationServiceProvider);
      return await service.getUserReservations(forceRefresh: forceRefresh);
    });

/// Provider for reservation submission
final reservationSubmissionProvider = FutureProvider.autoDispose<Reservation?>((
  ref,
) async {
  // Will be set when submission is triggered
  return null;
});

/// Provider for manual reservation submission
final manualReservationSubmissionProvider =
    Provider.autoDispose<Future<Reservation> Function(ReservationFormData)>((
      ref,
    ) {
      final service = ref.read(reservationServiceProvider);

      return (ReservationFormData formData) async {
        AppLogger.info('🎫 Starting reservation submission process');

        // Check for conflicts first
        final conflicts = await service.checkReservationConflicts(formData);
        if (conflicts.isNotEmpty) {
          AppLogger.warning(
            '⚠️ Reservation conflicts detected: ${conflicts.length}',
          );
          throw ReservationException(
            'Conflicts detected: ${conflicts.map((c) => c.message).join(', ')}',
            ReservationErrorType.conflictError,
          );
        }

        // Submit reservation
        final reservation = await service.submitReservation(formData);
        AppLogger.info('✅ Reservation submission completed successfully');

        return reservation;
      };
    });

/// Provider for reservation cancellation state management
final reservationCancellationProvider =
    FutureProvider.family<CancellationResult, String>((
      ref,
      reservationId,
    ) async {
      final service = ref.read(reservationServiceProvider);
      return await service.cancelReservation(reservationId);
    });

/// Provider for upcoming reservations (filtered view)
final upcomingReservationsProvider = Provider<AsyncValue<List<Reservation>>>((
  ref,
) {
  final reservationsAsync = ref.watch(userReservationsProvider);

  return reservationsAsync.when(
    data: (reservations) {
      final upcoming = reservations
          .where(
            (r) =>
                r.checkInDate.isAfter(DateTime.now()) &&
                r.status != ReservationStatus.cancelled,
          )
          .toList();
      upcoming.sort((a, b) => a.checkInDate.compareTo(b.checkInDate));
      return AsyncData(upcoming);
    },
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
});

/// Provider for past reservations (filtered view)
final pastReservationsProvider = Provider<AsyncValue<List<Reservation>>>((ref) {
  final reservationsAsync = ref.watch(userReservationsProvider);

  return reservationsAsync.when(
    data: (reservations) {
      final past = reservations
          .where((r) => r.checkOutDate.isBefore(DateTime.now()))
          .toList();
      past.sort(
        (a, b) => b.checkInDate.compareTo(a.checkInDate),
      ); // Most recent first
      return AsyncData(past);
    },
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
});

/// Provider for active/monitoring reservations
final activeReservationsProvider = Provider<AsyncValue<List<Reservation>>>((
  ref,
) {
  final reservationsAsync = ref.watch(userReservationsProvider);

  return reservationsAsync.when(
    data: (reservations) {
      final active = reservations.where((r) => r.isActive).toList();
      active.sort((a, b) => a.checkInDate.compareTo(b.checkInDate));
      return AsyncData(active);
    },
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
});

/// Provider for reservation statistics
final reservationStatsProvider = Provider<AsyncValue<ReservationStats>>((ref) {
  final reservationsAsync = ref.watch(userReservationsProvider);

  return reservationsAsync.when(
    data: (reservations) {
      final stats = ReservationStats.fromReservations(reservations);
      return AsyncData(stats);
    },
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
  );
});

/// Reservation statistics model
class ReservationStats {
  final int total;
  final int upcoming;
  final int completed;
  final int cancelled;
  final double totalSpent;
  final int totalNights;
  final Map<String, int> campgroundCounts;

  const ReservationStats({
    required this.total,
    required this.upcoming,
    required this.completed,
    required this.cancelled,
    required this.totalSpent,
    required this.totalNights,
    required this.campgroundCounts,
  });

  factory ReservationStats.fromReservations(List<Reservation> reservations) {
    final campgroundCounts = <String, int>{};
    double totalSpent = 0.0;
    int totalNights = 0;

    for (final reservation in reservations) {
      // Count campgrounds
      campgroundCounts[reservation.campgroundName] =
          (campgroundCounts[reservation.campgroundName] ?? 0) + 1;

      // Sum costs and nights
      if (reservation.totalCost != null) {
        totalSpent += reservation.totalCost!;
      }
      totalNights += reservation.checkOutDate
          .difference(reservation.checkInDate)
          .inDays;
    }

    return ReservationStats(
      total: reservations.length,
      upcoming: reservations
          .where(
            (r) =>
                r.checkInDate.isAfter(DateTime.now()) &&
                r.status != ReservationStatus.cancelled,
          )
          .length,
      completed: reservations
          .where((r) => r.status == ReservationStatus.completed)
          .length,
      cancelled: reservations
          .where((r) => r.status == ReservationStatus.cancelled)
          .length,
      totalSpent: totalSpent,
      totalNights: totalNights,
      campgroundCounts: Map.from(campgroundCounts),
    );
  }
}

/// Helper provider for refreshing reservations manually
final refreshReservationsActionProvider = Provider<VoidCallback>((ref) {
  return () {
    ref.invalidate(userReservationsProvider);
    AppLogger.info('🔄 Manually refreshing reservations');
  };
});

/// Provider for checking if reservations need credential setup
final needsCredentialsProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(reservationServiceProvider);
  final hasCredentials = await service.hasValidCredentials();
  return !hasCredentials; // Return true if credentials are needed
});
