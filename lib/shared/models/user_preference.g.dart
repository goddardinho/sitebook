// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPreference _$UserPreferenceFromJson(Map<String, dynamic> json) =>
    UserPreference(
      id: json['id'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      preferredState: json['preferredState'] as String?,
      maxDistance: (json['maxDistance'] as num?)?.toDouble(),
      preferredAmenities:
          (json['preferredAmenities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      autoReserveEnabled: json['autoReserveEnabled'] as bool? ?? false,
      maxBudget: (json['maxBudget'] as num?)?.toDouble(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserPreferenceToJson(UserPreference instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'preferredState': instance.preferredState,
      'maxDistance': instance.maxDistance,
      'preferredAmenities': instance.preferredAmenities,
      'notificationsEnabled': instance.notificationsEnabled,
      'autoReserveEnabled': instance.autoReserveEnabled,
      'maxBudget': instance.maxBudget,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
