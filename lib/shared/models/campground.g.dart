// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campground.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Campground _$CampgroundFromJson(Map<String, dynamic> json) => Campground(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  state: json['state'] as String,
  parkName: json['parkName'] as String?,
  reservationUrl: json['reservationUrl'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  email: json['email'] as String?,
  amenities: (json['amenities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  activities: (json['activities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  imageUrls: (json['imageUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  isMonitored: json['isMonitored'] as bool? ?? false,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CampgroundToJson(Campground instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'state': instance.state,
      'parkName': instance.parkName,
      'reservationUrl': instance.reservationUrl,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'amenities': instance.amenities,
      'activities': instance.activities,
      'imageUrls': instance.imageUrls,
      'isMonitored': instance.isMonitored,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
