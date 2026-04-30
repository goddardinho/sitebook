import 'dart:async';
import '../models/reservation.dart';
import '../../features/credentials/services/credential_storage_service.dart';
import '../../core/utils/app_logger.dart';

/// Service for managing reservations through Recreation.gov API
/// Bridges form data to live booking system
class ReservationService {
  final CredentialStorageService _credentialService;
  final Map<String, List<Reservation>> _reservationCache = {};

  ReservationService({required CredentialStorageService credentialService})
    : _credentialService = credentialService;

  /// Create a new reservation by redirecting to Recreation.gov website
  /// Recreation.gov requires web-based booking - no public API available
  Future<Reservation> submitReservation(ReservationFormData formData) async {
    try {
      AppLogger.info(
        '🎫 Preparing Recreation.gov booking for ${formData.campgroundName}',
      );

      // Create a pending reservation locally for tracking
      final reservation = Reservation(
        id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
        campsiteId: formData.campsiteId ?? 'TBD',
        campgroundName: formData.campgroundName,
        siteNumber: 'To be selected on Recreation.gov',
        checkInDate: formData.checkInDate,
        checkOutDate: formData.checkOutDate,
        guestCount: formData.guestCount,
        status: ReservationStatus.pending,
        confirmationNumber: 'PENDING_WEB_BOOKING',
        totalCost: 0.0, // Will be determined on Recreation.gov
        specialRequests: formData.specialRequests,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      AppLogger.info(
        '✅ Pending reservation created - user should complete booking on Recreation.gov',
      );
      return reservation;
    } catch (e) {
      AppLogger.error('❌ Failed to create booking redirect: $e');
      throw ReservationException(
        'Failed to prepare Recreation.gov booking. Please try again.',
        ReservationErrorType.serverError,
        originalError: e,
      );
    }
  }

  /// Get user reservations - Recreation.gov uses web-only booking
  /// Returns locally cached/managed reservation data for display
  Future<List<Reservation>> getUserReservations({
    bool forceRefresh = false,
  }) async {
    try {
      AppLogger.info('📋 Accessing user reservation data (web-managed)');

      // Recreation.gov manages reservations through their website only
      // Return any locally stored reservation data for display purposes
      const cacheKey = 'user_reservations';
      final cachedReservations = _reservationCache[cacheKey] ?? [];

      if (cachedReservations.isNotEmpty) {
        AppLogger.info(
          '📋 Displaying ${cachedReservations.length} locally tracked reservations',
        );
        return cachedReservations;
      }

      // Guide users to Recreation.gov website for actual reservation management
      AppLogger.info(
        'ℹ️ No local reservation data - use Recreation.gov website for booking',
      );
      return [];
    } catch (e) {
      AppLogger.warning('⚠️ Error accessing reservation data: $e');
      return [];
    }
  }

  /// Update existing reservation through Recreation.gov website
  Future<Reservation> updateReservation(
    String reservationId,
    ReservationFormData formData,
  ) async {
    try {
      AppLogger.info(
        '✏️ Reservation updates must be done through Recreation.gov website',
      );

      // Recreation.gov requires web-based management for reservation changes
      // Generate URL to manage existing reservation
      final manageUrl =
          'https://www.recreation.gov/reservation/manage/$reservationId';

      AppLogger.info(
        '🌐 Visit Recreation.gov to update reservation: $manageUrl',
      );

      throw ReservationException(
        'Reservation updates must be completed on Recreation.gov website.',
        ReservationErrorType.authenticationRequired,
      );
    } catch (e) {
      AppLogger.error('❌ Failed to update reservation: $e');
      if (e is ReservationException) rethrow;
      throw ReservationException(
        'Failed to update reservation. Please try again.',
        ReservationErrorType.serverError,
        originalError: e,
      );
    }
  }

  /// Cancel existing reservation through Recreation.gov website
  Future<CancellationResult> cancelReservation(String reservationId) async {
    try {
      AppLogger.info(
        '🚫 Reservation cancellations must be done through Recreation.gov website',
      );

      // Recreation.gov requires web-based management for cancellations
      final manageUrl =
          'https://www.recreation.gov/reservation/manage/$reservationId';

      AppLogger.info(
        '🌐 Visit Recreation.gov to cancel reservation: $manageUrl',
      );

      throw ReservationException(
        'Reservation cancellations must be completed on Recreation.gov website.',
        ReservationErrorType.authenticationRequired,
      );
    } catch (e) {
      AppLogger.error('❌ Failed to cancel reservation: $e');
      if (e is ReservationException) rethrow;
      throw ReservationException(
        'Failed to cancel reservation. Please try again.',
        ReservationErrorType.serverError,
        originalError: e,
      );
    }
  }

  /// Check for reservation conflicts with existing bookings
  Future<List<ReservationConflict>> checkReservationConflicts(
    ReservationFormData formData,
  ) async {
    try {
      final existingReservations = await getUserReservations();
      final conflicts = <ReservationConflict>[];

      for (final reservation in existingReservations) {
        if (reservation.status == ReservationStatus.cancelled ||
            reservation.status == ReservationStatus.completed) {
          continue;
        }

        // Check date overlap
        if (formData.checkInDate.isBefore(reservation.checkOutDate) &&
            formData.checkOutDate.isAfter(reservation.checkInDate)) {
          conflicts.add(
            ReservationConflict(
              conflictingReservation: reservation,
              conflictType: ReservationConflictType.dateOverlap,
              message:
                  'Overlaps with existing reservation at ${reservation.campgroundName}',
            ),
          );
        }
      }

      return conflicts;
    } catch (e) {
      AppLogger.warning('⚠️ Could not check conflicts: $e');
      return []; // Don't block reservation for conflict check failures
    }
  }

  /// Check if Recreation.gov credentials are configured
  Future<bool> hasValidCredentials() async {
    return await hasRecreationGovCredentials();
  }

  /// Create Recreation.gov booking URL for campground reservation
  String createBookingUrl({
    required String facilityId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? partySize,
  }) {
    // Recreation.gov booking URL format
    var url = 'https://www.recreation.gov/camping/campgrounds/$facilityId';

    final params = <String>[];
    if (checkInDate != null && checkOutDate != null) {
      params.add('arrival_date=${checkInDate.toIso8601String().split('T')[0]}');
      params.add(
        'departure_date=${checkOutDate.toIso8601String().split('T')[0]}',
      );
    }
    if (partySize != null) {
      params.add('party_size=$partySize');
    }

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    AppLogger.info('🌐 Generated Recreation.gov booking URL: $url');
    return url;
  }

  /// Check if user has Recreation.gov credentials for web login
  Future<bool> hasRecreationGovCredentials() async {
    try {
      final credentials = await _credentialService.loadCredentials();
      return credentials.any(
        (cred) =>
            cred.name.toLowerCase().contains('recreation.gov') &&
            cred.username.isNotEmpty &&
            cred.password.isNotEmpty,
      );
    } catch (e) {
      AppLogger.warning('⚠️ Failed to check Recreation.gov credentials: $e');
      return false;
    }
  }
}

/// Form data model for reservation submissions
class ReservationFormData {
  final String campgroundId;
  final String campgroundName;
  final String? campsiteId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final ContactInfo contactInfo;
  final String? specialRequests;
  final double? maxBudget;

  const ReservationFormData({
    required this.campgroundId,
    required this.campgroundName,
    this.campsiteId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    required this.contactInfo,
    this.specialRequests,
    this.maxBudget,
  });

  int get nights => checkOutDate.difference(checkInDate).inDays;
}

/// Contact information for reservations
class ContactInfo {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  const ContactInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });
}

/// Result of reservation cancellation
class CancellationResult {
  final String reservationId;
  final bool success;
  final double refundAmount;
  final double cancellationFee;
  final String refundMethod;
  final String? eta;
  final String message;

  const CancellationResult({
    required this.reservationId,
    required this.success,
    required this.refundAmount,
    required this.cancellationFee,
    required this.refundMethod,
    this.eta,
    required this.message,
  });
}

/// Reservation conflict detection
class ReservationConflict {
  final Reservation conflictingReservation;
  final ReservationConflictType conflictType;
  final String message;

  const ReservationConflict({
    required this.conflictingReservation,
    required this.conflictType,
    required this.message,
  });
}

enum ReservationConflictType { dateOverlap, sameCampground, budgetExceeded }

/// Reservation service exceptions
class ReservationException implements Exception {
  final String message;
  final ReservationErrorType errorType;
  final Object? originalError;

  const ReservationException(
    this.message,
    this.errorType, {
    this.originalError,
  });

  @override
  String toString() => 'ReservationException: $message';
}

enum ReservationErrorType {
  authenticationRequired,
  validationError,
  networkError,
  serverError,
  conflictError,
  quotaExceeded,
}
