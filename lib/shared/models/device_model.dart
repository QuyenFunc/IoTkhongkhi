import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_model.g.dart';

@JsonSerializable()
class DeviceModel extends Equatable {
  final String id;
  final String name;
  final String location;
  final String? description;
  final DeviceType type;
  final DeviceStatus status;
  final String ownerId;
  final String? groupId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeenAt;
  final DeviceConfiguration configuration;
  final List<String> capabilities;
  final Map<String, dynamic>? metadata;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.location,
    this.description,
    required this.type,
    required this.status,
    required this.ownerId,
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.lastSeenAt,
    required this.configuration,
    required this.capabilities,
    this.metadata,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) =>
      _$DeviceModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceModelToJson(this);

  DeviceModel copyWith({
    String? id,
    String? name,
    String? location,
    String? description,
    DeviceType? type,
    DeviceStatus? status,
    String? ownerId,
    String? groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
    DeviceConfiguration? configuration,
    List<String>? capabilities,
    Map<String, dynamic>? metadata,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      configuration: configuration ?? this.configuration,
      capabilities: capabilities ?? this.capabilities,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isOnline {
    if (lastSeenAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastSeenAt!);
    return difference.inMinutes < 5; // Consider offline if not seen for 5 minutes
  }

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        description,
        type,
        status,
        ownerId,
        groupId,
        createdAt,
        updatedAt,
        lastSeenAt,
        configuration,
        capabilities,
        metadata,
      ];
}

@JsonSerializable()
class DeviceConfiguration extends Equatable {
  final String mqttTopic;
  final int reportingInterval; // in seconds
  final SensorThresholds thresholds;
  final bool alertsEnabled;
  final List<String> alertRecipients;
  final Map<String, dynamic> customSettings;

  const DeviceConfiguration({
    required this.mqttTopic,
    required this.reportingInterval,
    required this.thresholds,
    required this.alertsEnabled,
    required this.alertRecipients,
    required this.customSettings,
  });

  factory DeviceConfiguration.defaultConfiguration(String deviceId) {
    return DeviceConfiguration(
      mqttTopic: 'iot/devices/$deviceId/data',
      reportingInterval: 30,
      thresholds: SensorThresholds.defaultThresholds(),
      alertsEnabled: true,
      alertRecipients: [],
      customSettings: {},
    );
  }

  factory DeviceConfiguration.fromJson(Map<String, dynamic> json) =>
      _$DeviceConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceConfigurationToJson(this);

  DeviceConfiguration copyWith({
    String? mqttTopic,
    int? reportingInterval,
    SensorThresholds? thresholds,
    bool? alertsEnabled,
    List<String>? alertRecipients,
    Map<String, dynamic>? customSettings,
  }) {
    return DeviceConfiguration(
      mqttTopic: mqttTopic ?? this.mqttTopic,
      reportingInterval: reportingInterval ?? this.reportingInterval,
      thresholds: thresholds ?? this.thresholds,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      alertRecipients: alertRecipients ?? this.alertRecipients,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  List<Object?> get props => [
        mqttTopic,
        reportingInterval,
        thresholds,
        alertsEnabled,
        alertRecipients,
        customSettings,
      ];
}

@JsonSerializable()
class SensorThresholds extends Equatable {
  final double minTemperature;
  final double maxTemperature;
  final double minHumidity;
  final double maxHumidity;
  final double? minPressure;
  final double? maxPressure;
  final int? maxAirQualityIndex;

  const SensorThresholds({
    required this.minTemperature,
    required this.maxTemperature,
    required this.minHumidity,
    required this.maxHumidity,
    this.minPressure,
    this.maxPressure,
    this.maxAirQualityIndex,
  });

  factory SensorThresholds.defaultThresholds() {
    return const SensorThresholds(
      minTemperature: 15.0,
      maxTemperature: 35.0,
      minHumidity: 30.0,
      maxHumidity: 70.0,
      minPressure: 950.0,
      maxPressure: 1050.0,
      maxAirQualityIndex: 100,
    );
  }

  factory SensorThresholds.fromJson(Map<String, dynamic> json) =>
      _$SensorThresholdsFromJson(json);

  Map<String, dynamic> toJson() => _$SensorThresholdsToJson(this);

  SensorThresholds copyWith({
    double? minTemperature,
    double? maxTemperature,
    double? minHumidity,
    double? maxHumidity,
    double? minPressure,
    double? maxPressure,
    int? maxAirQualityIndex,
  }) {
    return SensorThresholds(
      minTemperature: minTemperature ?? this.minTemperature,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      minHumidity: minHumidity ?? this.minHumidity,
      maxHumidity: maxHumidity ?? this.maxHumidity,
      minPressure: minPressure ?? this.minPressure,
      maxPressure: maxPressure ?? this.maxPressure,
      maxAirQualityIndex: maxAirQualityIndex ?? this.maxAirQualityIndex,
    );
  }

  @override
  List<Object?> get props => [
        minTemperature,
        maxTemperature,
        minHumidity,
        maxHumidity,
        minPressure,
        maxPressure,
        maxAirQualityIndex,
      ];
}

enum DeviceType {
  @JsonValue('esp32')
  esp32,
  @JsonValue('arduino')
  arduino,
  @JsonValue('raspberry_pi')
  raspberryPi,
  @JsonValue('custom')
  custom,
  @JsonValue('other')
  other,
}

enum DeviceStatus {
  @JsonValue('active')
  active,
  @JsonValue('inactive')
  inactive,
  @JsonValue('maintenance')
  maintenance,
  @JsonValue('error')
  error,
}

extension DeviceTypeExtension on DeviceType {
  String get displayName {
    switch (this) {
      case DeviceType.esp32:
        return 'ESP32';
      case DeviceType.arduino:
        return 'Arduino';
      case DeviceType.raspberryPi:
        return 'Raspberry Pi';
      case DeviceType.custom:
        return 'Tùy chỉnh';
      case DeviceType.other:
        return 'Khác';
    }
  }

  String get description {
    switch (this) {
      case DeviceType.esp32:
        return 'Vi điều khiển ESP32 với WiFi tích hợp';
      case DeviceType.arduino:
        return 'Bo mạch Arduino với các cảm biến';
      case DeviceType.raspberryPi:
        return 'Máy tính nhỏ Raspberry Pi';
      case DeviceType.custom:
        return 'Thiết bị tùy chỉnh khác';
      case DeviceType.other:
        return 'Thiết bị khác';
    }
  }
}

extension DeviceStatusExtension on DeviceStatus {
  String get displayName {
    switch (this) {
      case DeviceStatus.active:
        return 'Hoạt động';
      case DeviceStatus.inactive:
        return 'Không hoạt động';
      case DeviceStatus.maintenance:
        return 'Bảo trì';
      case DeviceStatus.error:
        return 'Lỗi';
    }
  }

  String get description {
    switch (this) {
      case DeviceStatus.active:
        return 'Thiết bị đang hoạt động bình thường';
      case DeviceStatus.inactive:
        return 'Thiết bị tạm thời không hoạt động';
      case DeviceStatus.maintenance:
        return 'Thiết bị đang được bảo trì';
      case DeviceStatus.error:
        return 'Thiết bị gặp lỗi';
    }
  }
}
