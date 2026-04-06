// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:json_annotation/json_annotation.dart';
import 'campsite.dart';

part 'campsite_monitoring_settings.g.dart';

enum MonitoringPriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

enum SitePreference {
  @JsonValue('any_available')
  anyAvailable,
  @JsonValue('specific_sites')
  specificSites,
  @JsonValue('site_type')
  siteType,
  @JsonValue('accessible_only')
  accessibleOnly,
}

@JsonSerializable()
class CampsiteMonitoringSettings {
  final String id;
  final String campgroundId;
  final String userId; // For future multi-user support
  final DateTime startDate;
  final DateTime endDate;
  final int guestCount;

  // Site preferences
  final SitePreference sitePreference;
  final List<String> preferredSiteNumbers;
  final List<String> preferredSiteTypes;
  final bool requireAccessibility;

  // Price preferences
  final double? maxPricePerNight;
  final double? maxTotalCost;
  final bool alertOnPriceDrops;

  // Monitoring behavior
  final MonitoringPriority priority;
  final bool autoReserve;
  final int maxNotificationsPerDay;
  final bool enableQuietHours;
  final int quietHourStart; // Hour of day (0-23)
  final int quietHourEnd; // Hour of day (0-23)

  // Backup options
  final List<String> alternativeCampgroundIds;
  final bool acceptNearbyCampgrounds;
  final double nearbyCampgroundRadiusMiles;

  // Metadata
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastCheckedAt;
  final int successfulChecks;
  final int failedChecks;

  const CampsiteMonitoringSettings({
    required this.id,
    required this.campgroundId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.guestCount,
    this.sitePreference = SitePreference.anyAvailable,
    this.preferredSiteNumbers = const [],
    this.preferredSiteTypes = const [],
    this.requireAccessibility = false,
    this.maxPricePerNight,
    this.maxTotalCost,
    this.alertOnPriceDrops = true,
    this.priority = MonitoringPriority.normal,
    this.autoReserve = false,
    this.maxNotificationsPerDay = 5,
    this.enableQuietHours = true,
    this.quietHourStart = 22, // 10 PM
    this.quietHourEnd = 8, // 8 AM
    this.alternativeCampgroundIds = const [],
    this.acceptNearbyCampgrounds = false,
    this.nearbyCampgroundRadiusMiles = 25.0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.lastCheckedAt,
    this.successfulChecks = 0,
    this.failedChecks = 0,
  });

  factory CampsiteMonitoringSettings.fromJson(Map<String, dynamic> json) =>
      _$CampsiteMonitoringSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$CampsiteMonitoringSettingsToJson(this);

  CampsiteMonitoringSettings copyWith({
    String? id,
    String? campgroundId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? guestCount,
    SitePreference? sitePreference,
    List<String>? preferredSiteNumbers,
    List<String>? preferredSiteTypes,
    bool? requireAccessibility,
    double? maxPricePerNight,
    double? maxTotalCost,
    bool? alertOnPriceDrops,
    MonitoringPriority? priority,
    bool? autoReserve,
    int? maxNotificationsPerDay,
    bool? enableQuietHours,
    int? quietHourStart,
    int? quietHourEnd,
    List<String>? alternativeCampgroundIds,
    bool? acceptNearbyCampgrounds,
    double? nearbyCampgroundRadiusMiles,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastCheckedAt,
    int? successfulChecks,
    int? failedChecks,
  }) {
    return CampsiteMonitoringSettings(
      id: id ?? this.id,
      campgroundId: campgroundId ?? this.campgroundId,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      guestCount: guestCount ?? this.guestCount,
      sitePreference: sitePreference ?? this.sitePreference,
      preferredSiteNumbers: preferredSiteNumbers ?? this.preferredSiteNumbers,
      preferredSiteTypes: preferredSiteTypes ?? this.preferredSiteTypes,
      requireAccessibility: requireAccessibility ?? this.requireAccessibility,
      maxPricePerNight: maxPricePerNight ?? this.maxPricePerNight,
      maxTotalCost: maxTotalCost ?? this.maxTotalCost,
      alertOnPriceDrops: alertOnPriceDrops ?? this.alertOnPriceDrops,
      priority: priority ?? this.priority,
      autoReserve: autoReserve ?? this.autoReserve,
      maxNotificationsPerDay:
          maxNotificationsPerDay ?? this.maxNotificationsPerDay,
      enableQuietHours: enableQuietHours ?? this.enableQuietHours,
      quietHourStart: quietHourStart ?? this.quietHourStart,
      quietHourEnd: quietHourEnd ?? this.quietHourEnd,
      alternativeCampgroundIds:
          alternativeCampgroundIds ?? this.alternativeCampgroundIds,
      acceptNearbyCampgrounds:
          acceptNearbyCampgrounds ?? this.acceptNearbyCampgrounds,
      nearbyCampgroundRadiusMiles:
          nearbyCampgroundRadiusMiles ?? this.nearbyCampgroundRadiusMiles,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      successfulChecks: successfulChecks ?? this.successfulChecks,
      failedChecks: failedChecks ?? this.failedChecks,
    );
  }

  /// Check if a campsite matches the monitoring preferences
  bool matchesCampsite(Campsite campsite) {
    // Check accessibility requirement
    if (requireAccessibility && !campsite.accessibility) {
      return false;
    }

    // Check price limit
    if (maxPricePerNight != null &&
        campsite.pricePerNight != null &&
        campsite.pricePerNight! > maxPricePerNight!) {
      return false;
    }

    // Check site preference
    switch (sitePreference) {
      case SitePreference.specificSites:
        return preferredSiteNumbers.contains(campsite.siteNumber);
      case SitePreference.siteType:
        return preferredSiteTypes.contains(campsite.siteType);
      case SitePreference.accessibleOnly:
        return campsite.accessibility;
      case SitePreference.anyAvailable:
        return campsite.isAvailable;
    }
  }

  /// Check if currently within quiet hours
  bool get isInQuietHours {
    final now = DateTime.now();
    final currentHour = now.hour;

    if (quietHourStart <= quietHourEnd) {
      // Same day quiet hours (e.g., 22:00 - 08:00 next day)
      return currentHour >= quietHourStart || currentHour < quietHourEnd;
    } else {
      // Cross-midnight quiet hours (e.g., 22:00 - 08:00)
      return currentHour >= quietHourStart && currentHour < quietHourEnd;
    }
  }

  /// Calculate total days being monitored
  int get monitoringDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Check if monitoring period is active
  bool get isMonitoringPeriodActive {
    final now = DateTime.now();
    return now.isBefore(endDate) &&
        now.isAfter(startDate.subtract(const Duration(days: 1)));
  }

  /// Get success rate as percentage
  double get successRate {
    final totalChecks = successfulChecks + failedChecks;
    if (totalChecks == 0) return 100.0;
    return (successfulChecks / totalChecks) * 100.0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CampsiteMonitoringSettings && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CampsiteMonitoringSettings(id: $id, campgroundId: $campgroundId, '
        'startDate: $startDate, endDate: $endDate, priority: $priority, isActive: $isActive)';
  }
}
