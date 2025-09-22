import 'package:json_annotation/json_annotation.dart';

part 'historical_data_model.g.dart';

@JsonSerializable()
class HistoricalDataPoint {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double airQuality;
  final double? pm25;
  final double? pm10;
  final double? co2;
  final String status;

  const HistoricalDataPoint({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.airQuality,
    this.pm25,
    this.pm10,
    this.co2,
    this.status = 'online',
  });

  factory HistoricalDataPoint.fromJson(Map<String, dynamic> json) =>
      _$HistoricalDataPointFromJson(json);

  Map<String, dynamic> toJson() => _$HistoricalDataPointToJson(this);

  factory HistoricalDataPoint.fromFirebase(Map<String, dynamic> data) {
    return HistoricalDataPoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(data['timestamp']?.toString() ?? '0') ?? 0,
      ),
      temperature: double.tryParse(data['temperature']?.toString() ?? '0') ?? 0.0,
      humidity: double.tryParse(data['humidity']?.toString() ?? '0') ?? 0.0,
      airQuality: double.tryParse(data['airQuality']?.toString() ?? '0') ?? 0.0,
      pm25: double.tryParse(data['pm25']?.toString() ?? ''),
      pm10: double.tryParse(data['pm10']?.toString() ?? ''),
      co2: double.tryParse(data['co2']?.toString() ?? ''),
      status: data['status']?.toString() ?? 'online',
    );
  }
}

enum TimeRange {
  oneHour('1 giờ', Duration(hours: 1)),
  oneDay('24 giờ', Duration(days: 1)),
  oneWeek('7 ngày', Duration(days: 7)),
  oneMonth('30 ngày', Duration(days: 30));

  const TimeRange(this.label, this.duration);
  final String label;
  final Duration duration;
}

enum SensorType {
  temperature('Nhiệt độ', '°C'),
  humidity('Độ ẩm', '%'),
  airQuality('Chất lượng KK', 'μg/m³'),
  pm25('PM2.5', 'μg/m³'),
  pm10('PM10', 'μg/m³'),
  co2('CO2', 'ppm');

  const SensorType(this.label, this.unit);
  final String label;
  final String unit;
}
