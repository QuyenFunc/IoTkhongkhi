import 'package:json_annotation/json_annotation.dart';

part 'alert_threshold_model.g.dart';

@JsonSerializable()
class AlertThreshold {
  final String id;
  final String deviceId;
  final String userId;
  final AlertType type;
  final double minValue;
  final double maxValue;
  final bool enabled;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AlertThreshold({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.type,
    required this.minValue,
    required this.maxValue,
    required this.enabled,
    required this.createdAt,
    this.updatedAt,
  });

  factory AlertThreshold.fromJson(Map<String, dynamic> json) =>
      _$AlertThresholdFromJson(json);

  Map<String, dynamic> toJson() => _$AlertThresholdToJson(this);

  AlertThreshold copyWith({
    String? id,
    String? deviceId,
    String? userId,
    AlertType? type,
    double? minValue,
    double? maxValue,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlertThreshold(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum AlertType {
  temperature('temperature', 'Nhiệt độ', '°C', 15.0, 40.0),
  humidity('humidity', 'Độ ẩm', '%', 30.0, 80.0),
  airQuality('airQuality', 'Chất lượng KK', 'μg/m³', 0.0, 100.0),
  pm25('pm25', 'PM2.5', 'μg/m³', 0.0, 50.0),
  pm10('pm10', 'PM10', 'μg/m³', 0.0, 100.0),
  co2('co2', 'CO2', 'ppm', 300.0, 1000.0);

  const AlertType(this.key, this.displayName, this.unit, this.defaultMin, this.defaultMax);
  
  final String key;
  final String displayName;
  final String unit;
  final double defaultMin;
  final double defaultMax;
}

@JsonSerializable()
class AlertEvent {
  final String id;
  final String deviceId;
  final String userId;
  final AlertType type;
  final double value;
  final double threshold;
  final String message;
  final DateTime timestamp;
  final bool acknowledged;
  final DateTime? acknowledgedAt;

  const AlertEvent({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.type,
    required this.value,
    required this.threshold,
    required this.message,
    required this.timestamp,
    required this.acknowledged,
    this.acknowledgedAt,
  });

  factory AlertEvent.fromJson(Map<String, dynamic> json) =>
      _$AlertEventFromJson(json);

  Map<String, dynamic> toJson() => _$AlertEventToJson(this);

  AlertEvent copyWith({
    String? id,
    String? deviceId,
    String? userId,
    AlertType? type,
    double? value,
    double? threshold,
    String? message,
    DateTime? timestamp,
    bool? acknowledged,
    DateTime? acknowledgedAt,
  }) {
    return AlertEvent(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      threshold: threshold ?? this.threshold,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }
}
