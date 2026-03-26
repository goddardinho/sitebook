// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:json_annotation/json_annotation.dart';

part 'user_preference.g.dart';

@JsonSerializable()
class UserPreference {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? preferredState;
  final double? maxDistance;
  final List<String> preferredAmenities;
  final bool notificationsEnabled;
  final bool autoReserveEnabled;
  final double? maxBudget;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserPreference({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.preferredState,
    this.maxDistance,
    this.preferredAmenities = const [],
    this.notificationsEnabled = true,
    this.autoReserveEnabled = false,
    this.maxBudget,
    this.createdAt,
    this.updatedAt,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) => _$UserPreferenceFromJson(json);
  Map<String, dynamic> toJson() => _$UserPreferenceToJson(this);

  UserPreference copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? preferredState,
    double? maxDistance,
    List<String>? preferredAmenities,
    bool? notificationsEnabled,
    bool? autoReserveEnabled,
    double? maxBudget,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreference(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      preferredState: preferredState ?? this.preferredState,
      maxDistance: maxDistance ?? this.maxDistance,
      preferredAmenities: preferredAmenities ?? this.preferredAmenities,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoReserveEnabled: autoReserveEnabled ?? this.autoReserveEnabled,
      maxBudget: maxBudget ?? this.maxBudget,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreference && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserPreference(id: $id, email: $email, notificationsEnabled: $notificationsEnabled)';
  }
}