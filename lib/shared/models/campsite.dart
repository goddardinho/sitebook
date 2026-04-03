// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:json_annotation/json_annotation.dart';

part 'campsite.g.dart';

@JsonSerializable()
class Campsite {
  final String id;
  final String campgroundId;
  final String siteNumber;
  final String siteType;
  final int maxOccupancy;
  final bool accessibility;
  final List<String> amenities;
  final double? pricePerNight;
  final bool isAvailable;
  final DateTime? nextAvailableDate;

  // Enhanced fields for campsite-level monitoring
  final String? imageUrl;
  final String? description;
  final Map<String, double> ratePricing; // Date-specific pricing
  final List<DateTime> availableDates;
  final Map<String, bool> amenitiesDetails; // Detailed amenities availability
  final String? reservationUrl;
  final bool isMonitored;
  final int? monitoringCount; // How many users are monitoring this site
  final DateTime? lastAvailabilityCheck;
  final String? notes;

  const Campsite({
    required this.id,
    required this.campgroundId,
    required this.siteNumber,
    required this.siteType,
    required this.maxOccupancy,
    this.accessibility = false,
    required this.amenities,
    this.pricePerNight,
    this.isAvailable = false,
    this.nextAvailableDate,
    this.imageUrl,
    this.description,
    this.ratePricing = const {},
    this.availableDates = const [],
    this.amenitiesDetails = const {},
    this.reservationUrl,
    this.isMonitored = false,
    this.monitoringCount,
    this.lastAvailabilityCheck,
    this.notes,
  });

  factory Campsite.fromJson(Map<String, dynamic> json) =>
      _$CampsiteFromJson(json);
  Map<String, dynamic> toJson() => _$CampsiteToJson(this);

  Campsite copyWith({
    String? id,
    String? campgroundId,
    String? siteNumber,
    String? siteType,
    int? maxOccupancy,
    bool? accessibility,
    List<String>? amenities,
    double? pricePerNight,
    bool? isAvailable,
    DateTime? nextAvailableDate,
    String? imageUrl,
    String? description,
    Map<String, double>? ratePricing,
    List<DateTime>? availableDates,
    Map<String, bool>? amenitiesDetails,
    String? reservationUrl,
    bool? isMonitored,
    int? monitoringCount,
    DateTime? lastAvailabilityCheck,
    String? notes,
  }) {
    return Campsite(
      id: id ?? this.id,
      campgroundId: campgroundId ?? this.campgroundId,
      siteNumber: siteNumber ?? this.siteNumber,
      siteType: siteType ?? this.siteType,
      maxOccupancy: maxOccupancy ?? this.maxOccupancy,
      accessibility: accessibility ?? this.accessibility,
      amenities: amenities ?? this.amenities,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      isAvailable: isAvailable ?? this.isAvailable,
      nextAvailableDate: nextAvailableDate ?? this.nextAvailableDate,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      ratePricing: ratePricing ?? this.ratePricing,
      availableDates: availableDates ?? this.availableDates,
      amenitiesDetails: amenitiesDetails ?? this.amenitiesDetails,
      reservationUrl: reservationUrl ?? this.reservationUrl,
      isMonitored: isMonitored ?? this.isMonitored,
      monitoringCount: monitoringCount ?? this.monitoringCount,
      lastAvailabilityCheck:
          lastAvailabilityCheck ?? this.lastAvailabilityCheck,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Campsite && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Campsite(id: $id, siteNumber: $siteNumber, isAvailable: $isAvailable, '
        'isMonitored: $isMonitored, pricePerNight: $pricePerNight)';
  }

  /// Check if campsite is available for a given date range
  bool isAvailableForDates(DateTime startDate, DateTime endDate) {
    if (availableDates.isEmpty) return isAvailable;

    final datesNeeded = <DateTime>[];
    var currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      datesNeeded.add(
        DateTime(currentDate.year, currentDate.month, currentDate.day),
      );
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return datesNeeded.every(
      (date) => availableDates.any(
        (available) =>
            available.year == date.year &&
            available.month == date.month &&
            available.day == date.day,
      ),
    );
  }

  /// Get average price for a date range
  double? getAveragePriceForDates(DateTime startDate, DateTime endDate) {
    if (ratePricing.isEmpty) return pricePerNight;

    var currentDate = startDate;
    final prices = <double>[];

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final dateKey =
          '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      final price = ratePricing[dateKey] ?? pricePerNight;
      if (price != null) prices.add(price);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a + b) / prices.length;
  }

  /// Get total cost for a date range
  double? getTotalCostForDates(DateTime startDate, DateTime endDate) {
    if (ratePricing.isEmpty && pricePerNight == null) return null;

    var currentDate = startDate;
    double totalCost = 0.0;

    while (currentDate.isBefore(endDate)) {
      final dateKey =
          '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      final price = ratePricing[dateKey] ?? pricePerNight ?? 0.0;
      totalCost += price;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return totalCost;
  }

  /// Check if campsite needs availability update
  bool get needsAvailabilityUpdate {
    if (lastAvailabilityCheck == null) return true;
    final timeSinceCheck = DateTime.now().difference(lastAvailabilityCheck!);
    return timeSinceCheck.inHours > 6; // Update every 6 hours
  }
}
