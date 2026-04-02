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
    return 'Campsite(id: $id, siteNumber: $siteNumber, isAvailable: $isAvailable)';
  }
}
