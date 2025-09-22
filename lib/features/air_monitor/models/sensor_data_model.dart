class SensorData {
  final double temperature;
  final double humidity;
  final double pm25;
  final int timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.pm25,
    required this.timestamp,
  });

  factory SensorData.fromFirebase(Map<String, dynamic> data) {
    final ts = _parseInt(data['timestamp']);
    // Check if timestamp is in seconds (less than 2000000000) and convert to milliseconds
    final timestamp = ts < 2000000000 ? ts * 1000 : ts;
    
    return SensorData(
      temperature: _parseDouble(data['temperature']),
      humidity: _parseDouble(data['humidity']),
      pm25: _parseDouble(data['pm25']),
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'pm25': pm25,
      'timestamp': timestamp,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory SensorData.empty() {
    return const SensorData(
      temperature: 0.0,
      humidity: 0.0,
      pm25: 0.0,
      timestamp: 0,
    );
  }

  bool get isValid => 
      temperature >= -50 && temperature <= 100 &&
      humidity >= 0 && humidity <= 100 &&
      pm25 >= 0 && pm25 <= 1000 &&
      timestamp > 0;

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  String get airQualityLevel {
    if (pm25 <= 12) return 'Tốt';
    if (pm25 <= 35) return 'Trung bình';
    if (pm25 <= 55) return 'Kém';
    if (pm25 <= 150) return 'Xấu';
    return 'Nguy hiểm';
  }

  String get airQualityColor {
    if (pm25 <= 12) return '#4CAF50';
    if (pm25 <= 35) return '#FFEB3B';
    if (pm25 <= 55) return '#FF9800';
    if (pm25 <= 150) return '#F44336';
    return '#9C27B0';
  }

  @override
  String toString() {
    return 'SensorData(temp: ${temperature}°C, humi: ${humidity}%, pm25: ${pm25}μg/m³)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorData &&
          runtimeType == other.runtimeType &&
          temperature == other.temperature &&
          humidity == other.humidity &&
          pm25 == other.pm25 &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      temperature.hashCode ^
      humidity.hashCode ^
      pm25.hashCode ^
      timestamp.hashCode;
}

class HistorySensorData {
  final double temp;
  final double hum;
  final double pm25;
  final int ts;

  const HistorySensorData({
    required this.temp,
    required this.hum,
    required this.pm25,
    required this.ts,
  });

  factory HistorySensorData.fromFirebase(Map<String, dynamic> data) {
    final ts = SensorData._parseInt(data['ts']);
    // ESP32 có thể gửi timestamp theo giây, cần convert sang milliseconds
    final timestamp = ts < 2000000000 ? ts * 1000 : ts;
    
    return HistorySensorData(
      temp: SensorData._parseDouble(data['temp']),
      hum: SensorData._parseDouble(data['hum']),
      pm25: SensorData._parseDouble(data['pm25']),
      ts: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temp': temp,
      'hum': hum,
      'pm25': pm25,
      'ts': ts,
    };
  }

  SensorData toSensorData() {
    return SensorData(
      temperature: temp,
      humidity: hum,
      pm25: pm25,
      timestamp: ts,
    );
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(ts);

  @override
  String toString() {
    return 'HistorySensorData(temp: ${temp}°C, hum: ${hum}%, pm25: ${pm25}μg/m³)';
  }
}