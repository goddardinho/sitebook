// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reservation _$ReservationFromJson(Map<String, dynamic> json) => Reservation(
  id: json['id'] as String,
  campsiteId: json['campsiteId'] as String,
  campgroundName: json['campgroundName'] as String,
  siteNumber: json['siteNumber'] as String,
  checkInDate: DateTime.parse(json['checkInDate'] as String),
  checkOutDate: DateTime.parse(json['checkOutDate'] as String),
  guestCount: (json['guestCount'] as num).toInt(),
  autoReserve: json['autoReserve'] as bool? ?? false,
  maxPrice: (json['maxPrice'] as num?)?.toDouble(),
  specialRequests: json['specialRequests'] as String?,
  status:
      $enumDecodeNullable(_$ReservationStatusEnumMap, json['status']) ??
      ReservationStatus.pending,
  confirmationNumber: json['confirmationNumber'] as String?,
  totalCost: (json['totalCost'] as num?)?.toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ReservationToJson(Reservation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'campsiteId': instance.campsiteId,
      'campgroundName': instance.campgroundName,
      'siteNumber': instance.siteNumber,
      'checkInDate': instance.checkInDate.toIso8601String(),
      'checkOutDate': instance.checkOutDate.toIso8601String(),
      'guestCount': instance.guestCount,
      'autoReserve': instance.autoReserve,
      'maxPrice': instance.maxPrice,
      'specialRequests': instance.specialRequests,
      'status': _$ReservationStatusEnumMap[instance.status]!,
      'confirmationNumber': instance.confirmationNumber,
      'totalCost': instance.totalCost,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$ReservationStatusEnumMap = {
  ReservationStatus.pending: 'pending',
  ReservationStatus.confirmed: 'confirmed',
  ReservationStatus.monitoring: 'monitoring',
  ReservationStatus.cancelled: 'cancelled',
  ReservationStatus.completed: 'completed',
  ReservationStatus.failed: 'failed',
};
