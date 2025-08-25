class SensorData {
  final double? temperature;
  final double? humidity;
  final double? dustPM25;
  final int? timestamp;
  final String? deviceId;
  final String? status;

  SensorData({
    this.temperature,
    this.humidity,
    this.dustPM25,
    this.timestamp,
    this.deviceId,
    this.status,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: _parseDouble(json['temperature']),
      humidity: _parseDouble(json['humidity']),
      dustPM25: _parseDouble(json['dustPM25']) ?? _parseDouble(json['dust']),
      timestamp: _parseInt(json['timestamp']),
      deviceId: json['deviceId'] as String?,
      status: json['status'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'dustPM25': dustPM25,
      'timestamp': timestamp,
      'deviceId': deviceId,
      'status': status,
    };
  }

  // Helper methods for type conversion
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Validation methods
  bool get isValid => 
      temperature != null && 
      humidity != null && 
      dustPM25 != null &&
      timestamp != null;

  // Status helpers
  bool get isOnline => status == 'online';
  bool get isOffline => status == 'offline';

  // Quality assessment methods
  String get temperatureStatus {
    if (temperature == null) return 'unknown';
    if (temperature! < 18) return 'cold';
    if (temperature! > 28) return 'hot';
    return 'normal';
  }

  String get humidityStatus {
    if (humidity == null) return 'unknown';
    if (humidity! < 40) return 'dry';
    if (humidity! > 70) return 'humid';
    return 'normal';
  }

  String get dustStatus {
    if (dustPM25 == null) return 'unknown';
    if (dustPM25! <= 12) return 'good';
    if (dustPM25! <= 35) return 'moderate';
    if (dustPM25! <= 55) return 'unhealthy_sensitive';
    if (dustPM25! <= 150) return 'unhealthy';
    return 'hazardous';
  }

  // Air Quality Index calculation
  int get aqi {
    if (dustPM25 == null) return 0;
    
    // Simplified AQI calculation based on PM2.5
    if (dustPM25! <= 12) return ((dustPM25! / 12) * 50).round();
    if (dustPM25! <= 35) return (50 + ((dustPM25! - 12) / 23) * 50).round();
    if (dustPM25! <= 55) return (100 + ((dustPM25! - 35) / 20) * 50).round();
    if (dustPM25! <= 150) return (150 + ((dustPM25! - 55) / 95) * 50).round();
    if (dustPM25! <= 250) return (200 + ((dustPM25! - 150) / 100) * 100).round();
    return 300 + ((dustPM25! - 250) / 200 * 200).round();
  }

  String get aqiDescription {
    int aqiValue = aqi;
    if (aqiValue <= 50) return 'Tốt';
    if (aqiValue <= 100) return 'Trung bình';
    if (aqiValue <= 150) return 'Kém với nhóm nhạy cảm';
    if (aqiValue <= 200) return 'Kém';
    if (aqiValue <= 300) return 'Rất kém';
    return 'Nguy hiểm';
  }

  // DateTime helper
  DateTime? get dateTime => 
      timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp! * 1000) : null;

  String get formattedTime {
    if (dateTime == null) return 'Unknown';
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime!);
    
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inMinutes < 60) return '${difference.inMinutes} phút trước';
    if (difference.inHours < 24) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';
    
    return '${dateTime!.day}/${dateTime!.month}/${dateTime!.year}';
  }

  @override
  String toString() {
    return 'SensorData(temp: $temperature°C, humidity: $humidity%, dust: $dustPM25 μg/m³, time: $formattedTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorData &&
        other.temperature == temperature &&
        other.humidity == humidity &&
        other.dustPM25 == dustPM25 &&
        other.timestamp == timestamp &&
        other.deviceId == deviceId;
  }

  @override
  int get hashCode {
    return temperature.hashCode ^
        humidity.hashCode ^
        dustPM25.hashCode ^
        timestamp.hashCode ^
        deviceId.hashCode;
  }

  // Copy with method
  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? dustPM25,
    int? timestamp,
    String? deviceId,
    String? status,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      dustPM25: dustPM25 ?? this.dustPM25,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
    );
  }
}

