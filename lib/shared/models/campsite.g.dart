// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campsite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Campsite _$CampsiteFromJson(Map<String, dynamic> json) => Campsite(
  id: json['id'] as String,
  campgroundId: json['campgroundId'] as String,
  siteNumber: json['siteNumber'] as String,
  siteType: json['siteType'] as String,
  maxOccupancy: (json['maxOccupancy'] as num).toInt(),
  accessibility: json['accessibility'] as bool? ?? false,
  amenities: (json['amenities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  pricePerNight: (json['pricePerNight'] as num?)?.toDouble(),
  isAvailable: json['isAvailable'] as bool? ?? false,
  nextAvailableDate: json['nextAvailableDate'] == null
      ? null
      : DateTime.parse(json['nextAvailableDate'] as String),
  imageUrl: json['imageUrl'] as String?,
  description: json['description'] as String?,
  ratePricing:
      (json['ratePricing'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const {},
  availableDates:
      (json['availableDates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList() ??
      const [],
  amenitiesDetails:
      (json['amenitiesDetails'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const {},
  reservationUrl: json['reservationUrl'] as String?,
  isMonitored: json['isMonitored'] as bool? ?? false,
  monitoringCount: (json['monitoringCount'] as num?)?.toInt(),
  lastAvailabilityCheck: json['lastAvailabilityCheck'] == null
      ? null
      : DateTime.parse(json['lastAvailabilityCheck'] as String),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$CampsiteToJson(Campsite instance) => <String, dynamic>{
  'id': instance.id,
  'campgroundId': instance.campgroundId,
  'siteNumber': instance.siteNumber,
  'siteType': instance.siteType,
  'maxOccupancy': instance.maxOccupancy,
  'accessibility': instance.accessibility,
  'amenities': instance.amenities,
  'pricePerNight': instance.pricePerNight,
  'isAvailable': instance.isAvailable,
  'nextAvailableDate': instance.nextAvailableDate?.toIso8601String(),
  'imageUrl': instance.imageUrl,
  'description': instance.description,
  'ratePricing': instance.ratePricing,
  'availableDates': instance.availableDates
      .map((e) => e.toIso8601String())
      .toList(),
  'amenitiesDetails': instance.amenitiesDetails,
  'reservationUrl': instance.reservationUrl,
  'isMonitored': instance.isMonitored,
  'monitoringCount': instance.monitoringCount,
  'lastAvailabilityCheck': instance.lastAvailabilityCheck?.toIso8601String(),
  'notes': instance.notes,
};
