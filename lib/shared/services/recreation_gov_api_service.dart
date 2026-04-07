import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../core/network/api_client.dart';
import '../models/campground.dart';

part 'recreation_gov_api_service.g.dart';

@RestApi()
abstract class RecreationGovApiService {
  factory RecreationGovApiService(Dio dio) = _RecreationGovApiService;

  static RecreationGovApiService create() {
    final apiClient = ApiClient();
    return RecreationGovApiService(apiClient.dio);
  }

  // Get facilities (campgrounds)
  @GET('/facilities')
  Future<RecreationGovResponse<RecreationGovFacility>> getFacilities({
    @Query('activity') String? activity,
    @Query('state') String? state,
    @Query('latitude') double? latitude,
    @Query('longitude') double? longitude,
    @Query('radius') double? radius, // in miles
    @Query('limit') int limit = 50,
    @Query('offset') int offset = 0,
  });

  // Get facility details
  @GET('/facilities/{facilityId}')
  Future<RecreationGovFacility> getFacilityDetails(
    @Path('facilityId') String facilityId,
  );

  // Get campsites for a facility
  @GET('/facilities/{facilityId}/campsites')
  Future<RecreationGovResponse<RecreationGovCampsite>> getCampsites(
    @Path('facilityId') String facilityId, {
    @Query('limit') int limit = 50,
    @Query('offset') int offset = 0,
  });

  // Get availability for a campsite
  @GET('/facilities/{facilityId}/campsites/{campsiteId}/availability')
  Future<RecreationGovAvailabilityResponse> getCampsiteAvailability(
    @Path('facilityId') String facilityId,
    @Path('campsiteId') String campsiteId,
    @Query('start_date') String startDate, // YYYY-MM-DD format
    @Query('end_date') String endDate,
  );
}

// API Response wrapper
class RecreationGovResponse<T> {
  final List<T> data;
  final RecreationGovMetadata metadata;

  RecreationGovResponse({required this.data, required this.metadata});

  factory RecreationGovResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return RecreationGovResponse(
      data: (json['RECDATA'] as List? ?? [])
          .where((item) => item != null) // Filter out null items
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      metadata: RecreationGovMetadata.fromJson(json['METADATA'] ?? {}),
    );
  }
}

class RecreationGovMetadata {
  final RecreationGovSearchParameters searchParameters;
  final RecreationGovResultInfo resultInfo;

  RecreationGovMetadata({
    required this.searchParameters,
    required this.resultInfo,
  });

  factory RecreationGovMetadata.fromJson(Map<String, dynamic> json) {
    return RecreationGovMetadata(
      searchParameters: RecreationGovSearchParameters.fromJson(
        json['SEARCH_PARAMETERS'] ?? {},
      ),
      resultInfo: RecreationGovResultInfo.fromJson(json['RESULT_INFO'] ?? {}),
    );
  }
}

class RecreationGovSearchParameters {
  final int limit;
  final int offset;

  RecreationGovSearchParameters({required this.limit, required this.offset});

  factory RecreationGovSearchParameters.fromJson(Map<String, dynamic> json) {
    return RecreationGovSearchParameters(
      limit: json['LIMIT'] ?? 0,
      offset: json['OFFSET'] ?? 0,
    );
  }
}

class RecreationGovResultInfo {
  final int totalCount;
  final int currentCount;

  RecreationGovResultInfo({
    required this.totalCount,
    required this.currentCount,
  });

  factory RecreationGovResultInfo.fromJson(Map<String, dynamic> json) {
    return RecreationGovResultInfo(
      totalCount: json['TOTAL_COUNT'] ?? 0,
      currentCount: json['CURRENT_COUNT'] ?? 0,
    );
  }
}

// Recreation.gov Facility model (maps to our Campground model)
class RecreationGovFacility {
  final String facilityId;
  final String facilityName;
  final String? facilityDescription;
  final double? facilityLatitude;
  final double? facilityLongitude;
  final String? facilityPhone;
  final String? facilityEmail;
  final String? facilityReservationURL;
  final List<RecreationGovAddress> addresses;
  final List<RecreationGovActivity> activities;

  RecreationGovFacility({
    required this.facilityId,
    required this.facilityName,
    this.facilityDescription,
    this.facilityLatitude,
    this.facilityLongitude,
    this.facilityPhone,
    this.facilityEmail,
    this.facilityReservationURL,
    required this.addresses,
    required this.activities,
  });

  factory RecreationGovFacility.fromJson(Map<String, dynamic> json) {
    return RecreationGovFacility(
      facilityId: json['FacilityID'] ?? '',
      facilityName: json['FacilityName'] ?? '',
      facilityDescription: json['FacilityDescription'],
      facilityLatitude: (json['FacilityLatitude'] as num?)?.toDouble(),
      facilityLongitude: (json['FacilityLongitude'] as num?)?.toDouble(),
      facilityPhone: json['FacilityPhone'],
      facilityEmail: json['FacilityEmail'],
      facilityReservationURL: json['FacilityReservationURL'],
      addresses: (json['FACILITYADDRESS'] as List? ?? [])
          .where((addr) => addr != null) // Filter out null addresses
          .map((addr) => RecreationGovAddress.fromJson(addr))
          .toList(),
      activities: (json['ACTIVITY'] as List? ?? [])
          .where((activity) => activity != null) // Filter out null activities
          .map((activity) => RecreationGovActivity.fromJson(activity))
          .toList(),
    );
  }

  // Convert Recreation.gov facility to our Campground model
  Campground toCampground() {
    final address = addresses.isNotEmpty ? addresses.first : null;
    final state = address?.addressStateCode ?? '';

    return Campground(
      id: facilityId,
      name: facilityName,
      description: facilityDescription ?? '',
      latitude: facilityLatitude ?? 0.0,
      longitude: facilityLongitude ?? 0.0,
      state: state,
      parkName: address?.facilityStreetAddress1,
      reservationUrl: facilityReservationURL,
      phoneNumber: facilityPhone,
      email: facilityEmail,
      amenities: _extractAmenities(),
      activities: activities.map((a) => a.activityName).toList(),
      imageUrls: [], // Recreation.gov images require separate API call
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  List<String> _extractAmenities() {
    // Basic amenity mapping - can be enhanced
    List<String> amenities = [];
    if (facilityPhone != null) amenities.add('Phone Service');
    if (facilityReservationURL != null) amenities.add('Online Reservations');
    return amenities;
  }
}

class RecreationGovAddress {
  final String? facilityStreetAddress1;
  final String? city;
  final String? addressStateCode;
  final String? postalCode;
  final String? addressCountryCode;

  RecreationGovAddress({
    this.facilityStreetAddress1,
    this.city,
    this.addressStateCode,
    this.postalCode,
    this.addressCountryCode,
  });

  factory RecreationGovAddress.fromJson(Map<String, dynamic> json) {
    return RecreationGovAddress(
      facilityStreetAddress1: json['FacilityStreetAddress1'],
      city: json['City'],
      addressStateCode: json['AddressStateCode'],
      postalCode: json['PostalCode'],
      addressCountryCode: json['AddressCountryCode'],
    );
  }
}

class RecreationGovActivity {
  final String activityId;
  final String activityName;

  RecreationGovActivity({required this.activityId, required this.activityName});

  factory RecreationGovActivity.fromJson(Map<String, dynamic> json) {
    return RecreationGovActivity(
      activityId: json['ActivityID']?.toString() ?? '',
      activityName: json['ActivityName'] ?? '',
    );
  }
}

class RecreationGovCampsite {
  final String campsiteId;
  final String campsiteName;
  final String? campsiteType;
  final int? campsiteLoop;
  final bool campsiteAccessible;

  RecreationGovCampsite({
    required this.campsiteId,
    required this.campsiteName,
    this.campsiteType,
    this.campsiteLoop,
    required this.campsiteAccessible,
  });

  factory RecreationGovCampsite.fromJson(Map<String, dynamic> json) {
    return RecreationGovCampsite(
      campsiteId: json['CampsiteID'] ?? '',
      campsiteName: json['CampsiteName'] ?? '',
      campsiteType: json['CampsiteType'],
      campsiteLoop: (json['Loop'] as num?)?.toInt(),
      campsiteAccessible: json['CampsiteAccessible'] == 'Yes',
    );
  }
}

// Wrapper for campsite availability response - handles raw Map data
class RecreationGovAvailabilityResponse {
  final Map<String, dynamic> availability;

  RecreationGovAvailabilityResponse({required this.availability});

  factory RecreationGovAvailabilityResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return RecreationGovAvailabilityResponse(availability: json);
  }

  Map<String, dynamic> toJson() => availability;
}

// RESERVATION BOOKING DATA MODELS (NEW)

/// Request payload for creating or updating reservations
class ReservationRequest {
  final String facilityId;
  final String campsiteId;
  final String startDate; // YYYY-MM-DD format
  final String endDate; // YYYY-MM-DD format
  final int partySize;
  final String customerEmail;
  final String customerPhone;
  final String customerFirstName;
  final String customerLastName;
  final String? specialRequests;
  final bool acceptTerms;

  const ReservationRequest({
    required this.facilityId,
    required this.campsiteId,
    required this.startDate,
    required this.endDate,
    required this.partySize,
    required this.customerEmail,
    required this.customerPhone,
    required this.customerFirstName,
    required this.customerLastName,
    this.specialRequests,
    this.acceptTerms = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'FacilityID': facilityId,
      'CampsiteID': campsiteId,
      'StartDate': startDate,
      'EndDate': endDate,
      'PartySize': partySize,
      'CustomerEmail': customerEmail,
      'CustomerPhone': customerPhone,
      'CustomerFirstName': customerFirstName,
      'CustomerLastName': customerLastName,
      'SpecialRequests': specialRequests,
      'AcceptTerms': acceptTerms,
    };
  }

  factory ReservationRequest.fromJson(Map<String, dynamic> json) {
    return ReservationRequest(
      facilityId: json['FacilityID'] ?? '',
      campsiteId: json['CampsiteID'] ?? '',
      startDate: json['StartDate'] ?? '',
      endDate: json['EndDate'] ?? '',
      partySize: json['PartySize'] ?? 1,
      customerEmail: json['CustomerEmail'] ?? '',
      customerPhone: json['CustomerPhone'] ?? '',
      customerFirstName: json['CustomerFirstName'] ?? '',
      customerLastName: json['CustomerLastName'] ?? '',
      specialRequests: json['SpecialRequests'],
      acceptTerms: json['AcceptTerms'] ?? true,
    );
  }
}

/// Response from Recreation.gov for reservation operations
class ReservationResponse {
  final String reservationId;
  final String confirmationCode;
  final String status; // 'confirmed', 'pending', 'cancelled'
  final String facilityId;
  final String facilityName;
  final String campsiteId;
  final String campsiteName;
  final String startDate;
  final String endDate;
  final int nights;
  final double totalCost;
  final double taxes;
  final double fees;
  final String customerEmail;
  final String customerName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? cancellationPolicy;
  final List<ReservationFee> feeBreakdown;

  const ReservationResponse({
    required this.reservationId,
    required this.confirmationCode,
    required this.status,
    required this.facilityId,
    required this.facilityName,
    required this.campsiteId,
    required this.campsiteName,
    required this.startDate,
    required this.endDate,
    required this.nights,
    required this.totalCost,
    required this.taxes,
    required this.fees,
    required this.customerEmail,
    required this.customerName,
    required this.createdAt,
    this.updatedAt,
    this.cancellationPolicy,
    required this.feeBreakdown,
  });

  factory ReservationResponse.fromJson(Map<String, dynamic> json) {
    return ReservationResponse(
      reservationId: json['ReservationID'] ?? '',
      confirmationCode: json['ConfirmationCode'] ?? '',
      status: json['Status'] ?? 'pending',
      facilityId: json['FacilityID'] ?? '',
      facilityName: json['FacilityName'] ?? '',
      campsiteId: json['CampsiteID'] ?? '',
      campsiteName: json['CampsiteName'] ?? '',
      startDate: json['StartDate'] ?? '',
      endDate: json['EndDate'] ?? '',
      nights: json['Nights'] ?? 0,
      totalCost: (json['TotalCost'] as num?)?.toDouble() ?? 0.0,
      taxes: (json['Taxes'] as num?)?.toDouble() ?? 0.0,
      fees: (json['Fees'] as num?)?.toDouble() ?? 0.0,
      customerEmail: json['CustomerEmail'] ?? '',
      customerName: json['CustomerName'] ?? '',
      createdAt: DateTime.tryParse(json['CreatedAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.tryParse(json['UpdatedAt'])
          : null,
      cancellationPolicy: json['CancellationPolicy'],
      feeBreakdown: (json['FeeBreakdown'] as List? ?? [])
          .where((fee) => fee != null) // Filter out null fees
          .map((fee) => ReservationFee.fromJson(fee))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ReservationID': reservationId,
      'ConfirmationCode': confirmationCode,
      'Status': status,
      'FacilityID': facilityId,
      'FacilityName': facilityName,
      'CampsiteID': campsiteId,
      'CampsiteName': campsiteName,
      'StartDate': startDate,
      'EndDate': endDate,
      'Nights': nights,
      'TotalCost': totalCost,
      'Taxes': taxes,
      'Fees': fees,
      'CustomerEmail': customerEmail,
      'CustomerName': customerName,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt?.toIso8601String(),
      'CancellationPolicy': cancellationPolicy,
      'FeeBreakdown': feeBreakdown.map((fee) => fee.toJson()).toList(),
    };
  }
}

/// Fee breakdown for reservations
class ReservationFee {
  final String feeType; // 'site', 'tax', 'service', 'processing'
  final String description;
  final double amount;
  final int nights;

  const ReservationFee({
    required this.feeType,
    required this.description,
    required this.amount,
    required this.nights,
  });

  factory ReservationFee.fromJson(Map<String, dynamic> json) {
    return ReservationFee(
      feeType: json['FeeType'] ?? '',
      description: json['Description'] ?? '',
      amount: (json['Amount'] as num?)?.toDouble() ?? 0.0,
      nights: json['Nights'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'FeeType': feeType,
      'Description': description,
      'Amount': amount,
      'Nights': nights,
    };
  }
}

/// Response for reservation cancellation
class CancellationResponse {
  final String reservationId;
  final String status; // 'cancelled', 'cancelledWithFee', 'error'
  final double refundAmount;
  final double cancellationFee;
  final String refundMethod; // 'original_payment', 'credit'
  final String? refundEta; // Expected refund timeline
  final DateTime cancelledAt;
  final String? cancellationReason;

  const CancellationResponse({
    required this.reservationId,
    required this.status,
    required this.refundAmount,
    required this.cancellationFee,
    required this.refundMethod,
    this.refundEta,
    required this.cancelledAt,
    this.cancellationReason,
  });

  factory CancellationResponse.fromJson(Map<String, dynamic> json) {
    return CancellationResponse(
      reservationId: json['ReservationID'] ?? '',
      status: json['Status'] ?? 'error',
      refundAmount: (json['RefundAmount'] as num?)?.toDouble() ?? 0.0,
      cancellationFee: (json['CancellationFee'] as num?)?.toDouble() ?? 0.0,
      refundMethod: json['RefundMethod'] ?? 'original_payment',
      refundEta: json['RefundETA'],
      cancelledAt:
          DateTime.tryParse(json['CancelledAt'] ?? '') ?? DateTime.now(),
      cancellationReason: json['CancellationReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ReservationID': reservationId,
      'Status': status,
      'RefundAmount': refundAmount,
      'CancellationFee': cancellationFee,
      'RefundMethod': refundMethod,
      'RefundETA': refundEta,
      'CancelledAt': cancelledAt.toIso8601String(),
      'CancellationReason': cancellationReason,
    };
  }
}
