// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceModel _$DeviceModelFromJson(Map<String, dynamic> json) => DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      description: json['description'] as String?,
      type: $enumDecode(_$DeviceTypeEnumMap, json['type']),
      status: $enumDecode(_$DeviceStatusEnumMap, json['status']),
      ownerId: json['ownerId'] as String,
      groupId: json['groupId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastSeenAt: json['lastSeenAt'] == null
          ? null
          : DateTime.parse(json['lastSeenAt'] as String),
      configuration: DeviceConfiguration.fromJson(
          json['configuration'] as Map<String, dynamic>),
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$DeviceModelToJson(DeviceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'location': instance.location,
      'description': instance.description,
      'type': _$DeviceTypeEnumMap[instance.type]!,
      'status': _$DeviceStatusEnumMap[instance.status]!,
      'ownerId': instance.ownerId,
      'groupId': instance.groupId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'lastSeenAt': instance.lastSeenAt?.toIso8601String(),
      'configuration': instance.configuration.toJson(),
      'capabilities': instance.capabilities,
      'metadata': instance.metadata,
    };

const _$DeviceTypeEnumMap = {
  DeviceType.esp32: 'esp32',
  DeviceType.arduino: 'arduino',
  DeviceType.raspberryPi: 'raspberry_pi',
  DeviceType.custom: 'custom',
  DeviceType.other: 'other',
};

const _$DeviceStatusEnumMap = {
  DeviceStatus.active: 'active',
  DeviceStatus.inactive: 'inactive',
  DeviceStatus.maintenance: 'maintenance',
  DeviceStatus.error: 'error',
};

DeviceConfiguration _$DeviceConfigurationFromJson(Map<String, dynamic> json) =>
    DeviceConfiguration(
      mqttTopic: json['mqttTopic'] as String,
      reportingInterval: (json['reportingInterval'] as num).toInt(),
      thresholds:
          SensorThresholds.fromJson(json['thresholds'] as Map<String, dynamic>),
      alertsEnabled: json['alertsEnabled'] as bool,
      alertRecipients: (json['alertRecipients'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      customSettings: json['customSettings'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$DeviceConfigurationToJson(
        DeviceConfiguration instance) =>
    <String, dynamic>{
      'mqttTopic': instance.mqttTopic,
      'reportingInterval': instance.reportingInterval,
      'thresholds': instance.thresholds.toJson(),
      'alertsEnabled': instance.alertsEnabled,
      'alertRecipients': instance.alertRecipients,
      'customSettings': instance.customSettings,
    };

SensorThresholds _$SensorThresholdsFromJson(Map<String, dynamic> json) =>
    SensorThresholds(
      minTemperature: (json['minTemperature'] as num).toDouble(),
      maxTemperature: (json['maxTemperature'] as num).toDouble(),
      minHumidity: (json['minHumidity'] as num).toDouble(),
      maxHumidity: (json['maxHumidity'] as num).toDouble(),
      minPressure: (json['minPressure'] as num?)?.toDouble(),
      maxPressure: (json['maxPressure'] as num?)?.toDouble(),
      maxAirQualityIndex: (json['maxAirQualityIndex'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SensorThresholdsToJson(SensorThresholds instance) =>
    <String, dynamic>{
      'minTemperature': instance.minTemperature,
      'maxTemperature': instance.maxTemperature,
      'minHumidity': instance.minHumidity,
      'maxHumidity': instance.maxHumidity,
      'minPressure': instance.minPressure,
      'maxPressure': instance.maxPressure,
      'maxAirQualityIndex': instance.maxAirQualityIndex,
    };
