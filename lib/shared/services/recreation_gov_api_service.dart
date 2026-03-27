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
  Future<RecreationGovResponse<List<RecreationGovFacility>>> getFacilities({
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
  Future<RecreationGovResponse<List<RecreationGovCampsite>>> getCampsites(
    @Path('facilityId') String facilityId, {
    @Query('limit') int limit = 50,
    @Query('offset') int offset = 0,
  });

  // Get availability for a campsite
  @GET('/facilities/{facilityId}/campsites/{campsiteId}/availability')
  Future<Map<String, dynamic>> getCampsiteAvailability(
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

  RecreationGovResponse({
    required this.data,
    required this.metadata,
  });

  factory RecreationGovResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return RecreationGovResponse(
      data: (json['RECDATA'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      metadata: RecreationGovMetadata.fromJson(json['METADATA']),
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
      searchParameters: RecreationGovSearchParameters.fromJson(json['SEARCH_PARAMETERS']),
      resultInfo: RecreationGovResultInfo.fromJson(json['RESULT_INFO']),
    );
  }
}

class RecreationGovSearchParameters {
  final int limit;
  final int offset;

  RecreationGovSearchParameters({
    required this.limit,
    required this.offset,
  });

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
      facilityLatitude: json['FacilityLatitude']?.toDouble(),
      facilityLongitude: json['FacilityLongitude']?.toDouble(),
      facilityPhone: json['FacilityPhone'],
      facilityEmail: json['FacilityEmail'],
      facilityReservationURL: json['FacilityReservationURL'],
      addresses: (json['FACILITYADDRESS'] as List? ?? [])
          .map((addr) => RecreationGovAddress.fromJson(addr))
          .toList(),
      activities: (json['ACTIVITY'] as List? ?? [])
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

  RecreationGovActivity({
    required this.activityId,
    required this.activityName,
  });

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
      campsiteLoop: json['Loop']?.toInt(),
      campsiteAccessible: json['CampsiteAccessible'] == 'Yes',
    );
  }
}