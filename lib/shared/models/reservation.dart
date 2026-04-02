// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:json_annotation/json_annotation.dart';

part 'reservation.g.dart';

enum ReservationStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('monitoring')
  monitoring,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
}

@JsonSerializable()
class Reservation {
  final String id;
  final String campsiteId;
  final String campgroundName;
  final String siteNumber;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;
  final bool autoReserve;
  final double? maxPrice;
  final String? specialRequests;
  final ReservationStatus status;
  final String? confirmationNumber;
  final double? totalCost;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Reservation({
    required this.id,
    required this.campsiteId,
    required this.campgroundName,
    required this.siteNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    this.autoReserve = false,
    this.maxPrice,
    this.specialRequests,
    this.status = ReservationStatus.pending,
    this.confirmationNumber,
    this.totalCost,
    required this.createdAt,
    this.updatedAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) =>
      _$ReservationFromJson(json);
  Map<String, dynamic> toJson() => _$ReservationToJson(this);

  Reservation copyWith({
    String? id,
    String? campsiteId,
    String? campgroundName,
    String? siteNumber,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? guestCount,
    bool? autoReserve,
    double? maxPrice,
    String? specialRequests,
    ReservationStatus? status,
    String? confirmationNumber,
    double? totalCost,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      campsiteId: campsiteId ?? this.campsiteId,
      campgroundName: campgroundName ?? this.campgroundName,
      siteNumber: siteNumber ?? this.siteNumber,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      guestCount: guestCount ?? this.guestCount,
      autoReserve: autoReserve ?? this.autoReserve,
      maxPrice: maxPrice ?? this.maxPrice,
      specialRequests: specialRequests ?? this.specialRequests,
      status: status ?? this.status,
      confirmationNumber: confirmationNumber ?? this.confirmationNumber,
      totalCost: totalCost ?? this.totalCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive =>
      status == ReservationStatus.monitoring ||
      status == ReservationStatus.confirmed;
  bool get canCancel =>
      status != ReservationStatus.cancelled &&
      status != ReservationStatus.completed;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reservation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Reservation(id: $id, campgroundName: $campgroundName, status: $status)';
  }
}
