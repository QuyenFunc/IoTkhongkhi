// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'historical_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HistoricalDataPoint _$HistoricalDataPointFromJson(Map<String, dynamic> json) =>
    HistoricalDataPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      airQuality: (json['airQuality'] as num).toDouble(),
      pm25: (json['pm25'] as num?)?.toDouble(),
      pm10: (json['pm10'] as num?)?.toDouble(),
      co2: (json['co2'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'online',
    );

Map<String, dynamic> _$HistoricalDataPointToJson(
        HistoricalDataPoint instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'airQuality': instance.airQuality,
      'pm25': instance.pm25,
      'pm10': instance.pm10,
      'co2': instance.co2,
      'status': instance.status,
    };
