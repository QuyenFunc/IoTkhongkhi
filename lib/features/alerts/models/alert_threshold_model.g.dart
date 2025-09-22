// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_threshold_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertThreshold _$AlertThresholdFromJson(Map<String, dynamic> json) =>
    AlertThreshold(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$AlertTypeEnumMap, json['type']),
      minValue: (json['minValue'] as num).toDouble(),
      maxValue: (json['maxValue'] as num).toDouble(),
      enabled: json['enabled'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$AlertThresholdToJson(AlertThreshold instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'userId': instance.userId,
      'type': _$AlertTypeEnumMap[instance.type]!,
      'minValue': instance.minValue,
      'maxValue': instance.maxValue,
      'enabled': instance.enabled,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$AlertTypeEnumMap = {
  AlertType.temperature: 'temperature',
  AlertType.humidity: 'humidity',
  AlertType.airQuality: 'airQuality',
  AlertType.pm25: 'pm25',
  AlertType.pm10: 'pm10',
  AlertType.co2: 'co2',
};

AlertEvent _$AlertEventFromJson(Map<String, dynamic> json) => AlertEvent(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$AlertTypeEnumMap, json['type']),
      value: (json['value'] as num).toDouble(),
      threshold: (json['threshold'] as num).toDouble(),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      acknowledged: json['acknowledged'] as bool,
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedAt'] as String),
    );

Map<String, dynamic> _$AlertEventToJson(AlertEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'userId': instance.userId,
      'type': _$AlertTypeEnumMap[instance.type]!,
      'value': instance.value,
      'threshold': instance.threshold,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
      'acknowledged': instance.acknowledged,
      'acknowledgedAt': instance.acknowledgedAt?.toIso8601String(),
    };
