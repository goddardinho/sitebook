// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:json_annotation/json_annotation.dart';

part 'campground.g.dart';

@JsonSerializable()
class Campground {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String state;
  final String? parkName;
  final String? reservationUrl;
  final String? phoneNumber;
  final String? email;
  final List<String> amenities;
  final List<String> activities;
  final List<String> imageUrls;
  final bool isMonitored;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Campground({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.state,
    this.parkName,
    this.reservationUrl,
    this.phoneNumber,
    this.email,
    required this.amenities,
    required this.activities,
    required this.imageUrls,
    this.isMonitored = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Campground.fromJson(Map<String, dynamic> json) =>
      _$CampgroundFromJson(json);
  Map<String, dynamic> toJson() => _$CampgroundToJson(this);

  Campground copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? state,
    String? parkName,
    String? reservationUrl,
    String? phoneNumber,
    String? email,
    List<String>? amenities,
    List<String>? activities,
    List<String>? imageUrls,
    bool? isMonitored,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Campground(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      state: state ?? this.state,
      parkName: parkName ?? this.parkName,
      reservationUrl: reservationUrl ?? this.reservationUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      amenities: amenities ?? this.amenities,
      activities: activities ?? this.activities,
      imageUrls: imageUrls ?? this.imageUrls,
      isMonitored: isMonitored ?? this.isMonitored,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Campground &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.state == state;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        state.hashCode;
  }

  @override
  String toString() {
    return 'Campground(id: $id, name: $name, state: $state, isMonitored: $isMonitored)';
  }
}
