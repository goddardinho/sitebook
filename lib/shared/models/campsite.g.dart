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
};
