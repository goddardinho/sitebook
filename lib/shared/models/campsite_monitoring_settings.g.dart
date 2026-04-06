// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campsite_monitoring_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CampsiteMonitoringSettings _$CampsiteMonitoringSettingsFromJson(
  Map<String, dynamic> json,
) => CampsiteMonitoringSettings(
  id: json['id'] as String,
  campgroundId: json['campgroundId'] as String,
  userId: json['userId'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  guestCount: (json['guestCount'] as num).toInt(),
  sitePreference:
      $enumDecodeNullable(_$SitePreferenceEnumMap, json['sitePreference']) ??
      SitePreference.anyAvailable,
  preferredSiteNumbers:
      (json['preferredSiteNumbers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  preferredSiteTypes:
      (json['preferredSiteTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  requireAccessibility: json['requireAccessibility'] as bool? ?? false,
  maxPricePerNight: (json['maxPricePerNight'] as num?)?.toDouble(),
  maxTotalCost: (json['maxTotalCost'] as num?)?.toDouble(),
  alertOnPriceDrops: json['alertOnPriceDrops'] as bool? ?? true,
  priority:
      $enumDecodeNullable(_$MonitoringPriorityEnumMap, json['priority']) ??
      MonitoringPriority.normal,
  autoReserve: json['autoReserve'] as bool? ?? false,
  maxNotificationsPerDay:
      (json['maxNotificationsPerDay'] as num?)?.toInt() ?? 5,
  enableQuietHours: json['enableQuietHours'] as bool? ?? true,
  quietHourStart: (json['quietHourStart'] as num?)?.toInt() ?? 22,
  quietHourEnd: (json['quietHourEnd'] as num?)?.toInt() ?? 8,
  alternativeCampgroundIds:
      (json['alternativeCampgroundIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  acceptNearbyCampgrounds: json['acceptNearbyCampgrounds'] as bool? ?? false,
  nearbyCampgroundRadiusMiles:
      (json['nearbyCampgroundRadiusMiles'] as num?)?.toDouble() ?? 25.0,
  isActive: json['isActive'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  lastCheckedAt: json['lastCheckedAt'] == null
      ? null
      : DateTime.parse(json['lastCheckedAt'] as String),
  successfulChecks: (json['successfulChecks'] as num?)?.toInt() ?? 0,
  failedChecks: (json['failedChecks'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CampsiteMonitoringSettingsToJson(
  CampsiteMonitoringSettings instance,
) => <String, dynamic>{
  'id': instance.id,
  'campgroundId': instance.campgroundId,
  'userId': instance.userId,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'guestCount': instance.guestCount,
  'sitePreference': _$SitePreferenceEnumMap[instance.sitePreference]!,
  'preferredSiteNumbers': instance.preferredSiteNumbers,
  'preferredSiteTypes': instance.preferredSiteTypes,
  'requireAccessibility': instance.requireAccessibility,
  'maxPricePerNight': instance.maxPricePerNight,
  'maxTotalCost': instance.maxTotalCost,
  'alertOnPriceDrops': instance.alertOnPriceDrops,
  'priority': _$MonitoringPriorityEnumMap[instance.priority]!,
  'autoReserve': instance.autoReserve,
  'maxNotificationsPerDay': instance.maxNotificationsPerDay,
  'enableQuietHours': instance.enableQuietHours,
  'quietHourStart': instance.quietHourStart,
  'quietHourEnd': instance.quietHourEnd,
  'alternativeCampgroundIds': instance.alternativeCampgroundIds,
  'acceptNearbyCampgrounds': instance.acceptNearbyCampgrounds,
  'nearbyCampgroundRadiusMiles': instance.nearbyCampgroundRadiusMiles,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'lastCheckedAt': instance.lastCheckedAt?.toIso8601String(),
  'successfulChecks': instance.successfulChecks,
  'failedChecks': instance.failedChecks,
};

const _$SitePreferenceEnumMap = {
  SitePreference.anyAvailable: 'any_available',
  SitePreference.specificSites: 'specific_sites',
  SitePreference.siteType: 'site_type',
  SitePreference.accessibleOnly: 'accessible_only',
};

const _$MonitoringPriorityEnumMap = {
  MonitoringPriority.low: 'low',
  MonitoringPriority.normal: 'normal',
  MonitoringPriority.high: 'high',
  MonitoringPriority.critical: 'critical',
};
