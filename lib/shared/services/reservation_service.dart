import 'dart:async';
import 'dart:convert';
import '../models/reservation.dart';
import 'recreation_gov_api_service.dart';
import '../../features/credentials/services/credential_storage_service.dart';
import '../../core/utils/app_logger.dart';

/// Service for managing reservations through Recreation.gov API
/// Bridges form data to live booking system
class ReservationService {
  final RecreationGovApiService _apiService;
  final CredentialStorageService _credentialService;
  final Map<String, List<Reservation>> _reservationCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  static const Duration _cacheExpiration = Duration(minutes: 15);

  ReservationService({
    required RecreationGovApiService apiService,
    required CredentialStorageService credentialService,
  }) : _apiService = apiService,
       _credentialService = credentialService;

  /// Create a new reservation from form data
  Future<Reservation> submitReservation(ReservationFormData formData) async {
    try {
      AppLogger.info(
        '🎫 Submitting reservation for ${formData.campgroundName}',
      );

      // Get Recreation.gov credentials
      final authToken = await _getAuthToken();
      if (authToken == null) {
        throw ReservationException(
          'No Recreation.gov credentials found. Please add credentials in Settings.',
          ReservationErrorType.authenticationRequired,
        );
      }

      // Convert form data to API request
      final request = _buildReservationRequest(formData);

      // Validate request data
      _validateReservationRequest(request, formData);

      // Submit to Recreation.gov API
      final response = await _apiService.createReservation(request, authToken);

      // Convert API response to our reservation model
      final reservation = _mapApiResponseToReservation(response, formData);

      // Update cache
      _updateReservationCache(reservation);

      AppLogger.info(
        '✅ Reservation created successfully: ${reservation.confirmationNumber}',
      );
      return reservation;
    } catch (e) {
      AppLogger.error('❌ Failed to submit reservation: $e');
      if (e is ReservationException) rethrow;
      throw ReservationException(
        'Failed to create reservation. Please try again.',
        ReservationErrorType.serverError,
        originalError: e,
      );
    }
  }

  /// Get all user reservations with caching
  Future<List<Reservation>> getUserReservations({
    bool forceRefresh = false,
  }) async {
    try {
      const cacheKey = 'user_reservations';

      // Check cache first
      if (!forceRefresh && _isCacheValid(cacheKey)) {
        AppLogger.info('📋 Returning cached reservations');
        return _reservationCache[cacheKey] ?? [];
      }

      AppLogger.info('🔄 Fetching user reservations from API');

      // Get credentials
      final authToken = await _getAuthToken();
      if (authToken == null) {
        AppLogger.warning('⚠️ No credentials found, returning empty list');
        return [];
      }

      // Fetch from API
      final apiReservations = await _apiService.getUserReservations(authToken);

      // Convert to our model
      final reservations = apiReservations
          .map((apiRes) => _mapApiResponseToReservation(apiRes, null))
          .toList();

      // Update cache
      _reservationCache[cacheKey] = reservations;
      _cacheTimestamps[cacheKey] = DateTime.now();

      AppLogger.info('✅ Retrieved ${reservations.length} reservations');
      return reservations;
    } catch (e) {
      AppLogger.error('❌ Failed to get user reservations: $e');
      // Return cached data on error if available
      const cacheKey = 'user_reservations';
      if (_reservationCache.containsKey(cacheKey)) {
        AppLogger.info('🔄 Returning cached data due to API error');
        return _reservationCache[cacheKey]!;
      }

      throw ReservationException(
        'Failed to retrieve reservations. Please check your connection.',
        ReservationErrorType.networkError,
        originalError: e,
      );
    }
  }

  /// Update existing reservation
  Future<Reservation> updateReservation(
    String reservationId,
    ReservationFormData formData,
  ) async {
    try {
      AppLogger.info('✏️ Updating reservation $reservationId');

      final authToken = await _getAuthToken();
      if (authToken == null) {
        throw ReservationException(
          'Authentication required to update reservation.',
          ReservationErrorType.authenticationRequired,
        );
      }

      final request = _buildReservationRequest(formData);
      final response = await _apiService.updateReservation(
        reservationId,
        request,
        authToken,
      );

      final updatedReservation = _mapApiResponseToReservation(
        response,
        formData,
      );
      _updateReservationCache(updatedReservation);

      AppLogger.info('✅ Reservation updated successfully');
      return updatedReservation;
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

  /// Cancel existing reservation
  Future<CancellationResult> cancelReservation(String reservationId) async {
    try {
      AppLogger.info('🚫 Cancelling reservation $reservationId');

      final authToken = await _getAuthToken();
      if (authToken == null) {
        throw ReservationException(
          'Authentication required to cancel reservation.',
          ReservationErrorType.authenticationRequired,
        );
      }

      final response = await _apiService.cancelReservation(
        reservationId,
        authToken,
      );

      // Remove from cache
      _removeFromCache(reservationId);

      final result = CancellationResult(
        reservationId: response.reservationId,
        success:
            response.status == 'cancelled' ||
            response.status == 'cancelledWithFee',
        refundAmount: response.refundAmount,
        cancellationFee: response.cancellationFee,
        refundMethod: response.refundMethod,
        eta: response.refundEta,
        message: _getCancellationMessage(response),
      );

      AppLogger.info('✅ Reservation cancelled successfully');
      return result;
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
        if (_datesOverlap(
          formData.checkInDate,
          formData.checkOutDate,
          reservation.checkInDate,
          reservation.checkOutDate,
        )) {
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
    try {
      final credentials = await _credentialService.loadCredentials();
      return credentials.any(
        (cred) =>
            cred.name.toLowerCase().contains('recreation.gov') &&
            cred.username.isNotEmpty &&
            cred.password.isNotEmpty,
      );
    } catch (e) {
      AppLogger.warning('⚠️ Failed to check credentials: $e');
      return false;
    }
  }

  /// Get Recreation.gov auth token from stored credentials
  Future<String?> _getAuthToken() async {
    try {
      final credentials = await _credentialService.loadCredentials();
      final recreationGovCred = credentials.firstWhere(
        (cred) => cred.name.toLowerCase().contains('recreation.gov'),
        orElse: () => throw StateError('No Recreation.gov credentials found'),
      );

      // In a real implementation, you'd use the username/password to get a JWT token
      // For now, we'll simulate with a basic auth token
      final basicAuth = base64Encode(
        utf8.encode(
          '${recreationGovCred.username}:${recreationGovCred.password}',
        ),
      );
      return 'Bearer $basicAuth';
    } catch (e) {
      AppLogger.warning('⚠️ Failed to get auth token: $e');
      return null;
    }
  }

  /// Build API request from form data
  ReservationRequest _buildReservationRequest(ReservationFormData formData) {
    return ReservationRequest(
      facilityId: formData.campgroundId,
      campsiteId:
          formData.campsiteId ?? 'auto', // Let system choose if not specified
      startDate: formData.checkInDate.toIso8601String().split('T')[0],
      endDate: formData.checkOutDate.toIso8601String().split('T')[0],
      partySize: formData.guestCount,
      customerEmail: formData.contactInfo.email,
      customerPhone: formData.contactInfo.phone,
      customerFirstName: formData.contactInfo.firstName,
      customerLastName: formData.contactInfo.lastName,
      specialRequests: formData.specialRequests,
      acceptTerms: true,
    );
  }

  /// Validate reservation request before submission
  void _validateReservationRequest(
    ReservationRequest request,
    ReservationFormData formData,
  ) {
    final errors = <String>[];

    // Date validation
    if (formData.checkInDate.isBefore(DateTime.now())) {
      errors.add('Check-in date cannot be in the past');
    }

    if (formData.checkOutDate.isBefore(
      formData.checkInDate.add(Duration(days: 1)),
    )) {
      errors.add('Check-out must be at least 1 day after check-in');
    }

    // Guest count validation
    if (formData.guestCount < 1 || formData.guestCount > 20) {
      errors.add('Guest count must be between 1 and 20');
    }

    // Contact validation
    if (formData.contactInfo.email.isEmpty ||
        !formData.contactInfo.email.contains('@')) {
      errors.add('Valid email address is required');
    }

    if (formData.contactInfo.firstName.isEmpty ||
        formData.contactInfo.lastName.isEmpty) {
      errors.add('First and last name are required');
    }

    if (errors.isNotEmpty) {
      throw ReservationException(
        'Validation failed: ${errors.join(', ')}',
        ReservationErrorType.validationError,
      );
    }
  }

  /// Map API response to our reservation model
  Reservation _mapApiResponseToReservation(
    ReservationResponse response,
    ReservationFormData? formData,
  ) {
    return Reservation(
      id: response.reservationId,
      campsiteId: response.campsiteId,
      campgroundName: response.facilityName,
      siteNumber: response.campsiteName,
      checkInDate: DateTime.parse(response.startDate),
      checkOutDate: DateTime.parse(response.endDate),
      guestCount: formData?.guestCount ?? 1,
      autoReserve: false,
      maxPrice: formData?.maxBudget,
      specialRequests: formData?.specialRequests,
      status: _mapApiStatus(response.status),
      confirmationNumber: response.confirmationCode,
      totalCost: response.totalCost,
      createdAt: response.createdAt,
      updatedAt: response.updatedAt,
    );
  }

  /// Map API status to our enum
  ReservationStatus _mapApiStatus(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'pending':
        return ReservationStatus.pending;
      case 'cancelled':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.pending;
    }
  }

  /// Helper methods for caching and validation
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiration;
  }

  void _updateReservationCache(Reservation reservation) {
    const cacheKey = 'user_reservations';
    final cached = _reservationCache[cacheKey] ?? [];

    // Update existing or add new
    final index = cached.indexWhere((r) => r.id == reservation.id);
    if (index >= 0) {
      cached[index] = reservation;
    } else {
      cached.add(reservation);
    }

    _reservationCache[cacheKey] = cached;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  void _removeFromCache(String reservationId) {
    const cacheKey = 'user_reservations';
    final cached = _reservationCache[cacheKey];
    if (cached != null) {
      cached.removeWhere((r) => r.id == reservationId);
    }
  }

  bool _datesOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  String _getCancellationMessage(CancellationResponse response) {
    if (response.status == 'cancelled') {
      return 'Reservation cancelled successfully. Refund of \$${response.refundAmount.toStringAsFixed(2)} will be processed.';
    } else if (response.status == 'cancelledWithFee') {
      return 'Reservation cancelled with \$${response.cancellationFee.toStringAsFixed(2)} fee. Refund of \$${response.refundAmount.toStringAsFixed(2)} will be processed.';
    }
    return 'Cancellation request processed. Please check your email for details.';
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
