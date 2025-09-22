class AirQualityResponse {
  final double temperature;
  final double humidity;
  final double pm25;
  final bool isOnline;
  final int lastSeen;
  final String deviceId;
  final bool hasAlert;
  final String? alertReason;
  final int timestamp;

  const AirQualityResponse({
    required this.temperature,
    required this.humidity,
    required this.pm25,
    required this.isOnline,
    required this.lastSeen,
    required this.deviceId,
    this.hasAlert = false,
    this.alertReason,
    required this.timestamp,
  });

  factory AirQualityResponse.fromFirebase(Map<String, dynamic> sensorData, Map<String, dynamic> statusData, [Map<String, dynamic>? alertData]) {
    return AirQualityResponse(
      temperature: (sensorData['temp'] as num?)?.toDouble() ?? 0.0,
      humidity: (sensorData['hum'] as num?)?.toDouble() ?? 0.0,
      pm25: (sensorData['pm25'] as num?)?.toDouble() ?? 0.0,
      isOnline: statusData['is_online'] as bool? ?? false,
      lastSeen: statusData['last_seen'] as int? ?? 0,
      deviceId: statusData['device_id'] as String? ?? 'Unknown',
      hasAlert: alertData?['active'] as bool? ?? false,
      alertReason: alertData?['reason'] as String?,
      timestamp: sensorData['ts'] as int? ?? 0,
    );
  }

  // Air quality assessment
  AirQualityLevel get airQualityLevel {
    if (pm25 <= 12) {
      return AirQualityLevel.good;
    } else if (pm25 <= 35) {
      return AirQualityLevel.moderate;
    } else if (pm25 <= 55) {
      return AirQualityLevel.unhealthyForSensitive;
    } else if (pm25 <= 150) {
      return AirQualityLevel.unhealthy;
    } else {
      return AirQualityLevel.hazardous;
    }
  }

  String get airQualityDescription {
    switch (airQualityLevel) {
      case AirQualityLevel.good:
        return 'Tốt - An toàn cho mọi hoạt động';
      case AirQualityLevel.moderate:
        return 'Trung bình - Có thể hoạt động bình thường';
      case AirQualityLevel.unhealthyForSensitive:
        return 'Kém cho người nhạy cảm - Hạn chế hoạt động ngoài trời';
      case AirQualityLevel.unhealthy:
        return 'Không lành mạnh - Nên đeo khẩu trang';
      case AirQualityLevel.hazardous:
        return 'Nguy hiểm - Tránh ra ngoài trừ khi cần thiết';
    }
  }

  String get temperatureDescription {
    if (temperature < 16) {
      return 'Lạnh';
    } else if (temperature < 24) {
      return 'Mát';
    } else if (temperature < 30) {
      return 'Ấm';
    } else if (temperature < 35) {
      return 'Nóng';
    } else {
      return 'Rất nóng';
    }
  }

  String get humidityDescription {
    if (humidity < 30) {
      return 'Khô';
    } else if (humidity < 60) {
      return 'Thoải mái';
    } else if (humidity < 80) {
      return 'Ẩm';
    } else {
      return 'Rất ẩm';
    }
  }

  String get connectionStatusDescription {
    if (!isOnline) {
      return 'Ngoại tuyến';
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastSeenMs = lastSeen < 2000000000 ? lastSeen * 1000 : lastSeen;
    final timeDiff = now - lastSeenMs;

    if (timeDiff < 60000) {
      return 'Hoạt động tốt';
    } else if (timeDiff < 300000) {
      return 'Trực tuyến';
    } else {
      return 'Kết nối chậm';
    }
  }

  DateTime get lastSeenDateTime => DateTime.fromMillisecondsSinceEpoch(
    lastSeen < 2000000000 ? lastSeen * 1000 : lastSeen
  );

  DateTime get dataDateTime => DateTime.fromMillisecondsSinceEpoch(
    timestamp < 2000000000 ? timestamp * 1000 : timestamp
  );

  // Voice-friendly summary
  String get voiceSummary {
    return 'Nhiệt độ ${temperature.toStringAsFixed(1)} độ C, '
           'độ ẩm ${humidity.toStringAsFixed(1)} phần trăm, '
           'chỉ số PM2.5 ${pm25.toStringAsFixed(1)} microgram trên mét khối. '
           'Chất lượng không khí ${airQualityLevel.displayName}.';
  }

  String get detailedVoiceReport {
    final connectionStatus = connectionStatusDescription;
    final alertStatus = hasAlert ? 'Có cảnh báo: $alertReason' : 'Không có cảnh báo';
    
    return 'Báo cáo chi tiết: $voiceSummary '
           'Thiết bị $connectionStatus. $alertStatus.';
  }

  @override
  String toString() {
    return 'AirQualityResponse(temp: $temperature°C, hum: $humidity%, pm25: $pm25μg/m³, online: $isOnline)';
  }
}

enum AirQualityLevel {
  good,
  moderate,
  unhealthyForSensitive,
  unhealthy,
  hazardous;

  String get displayName {
    switch (this) {
      case AirQualityLevel.good:
        return 'Tốt';
      case AirQualityLevel.moderate:
        return 'Trung bình';
      case AirQualityLevel.unhealthyForSensitive:
        return 'Kém cho người nhạy cảm';
      case AirQualityLevel.unhealthy:
        return 'Không lành mạnh';
      case AirQualityLevel.hazardous:
        return 'Nguy hiểm';
    }
  }

  String get emoji {
    switch (this) {
      case AirQualityLevel.good:
        return '😊';
      case AirQualityLevel.moderate:
        return '😐';
      case AirQualityLevel.unhealthyForSensitive:
        return '😷';
      case AirQualityLevel.unhealthy:
        return '😰';
      case AirQualityLevel.hazardous:
        return '💀';
    }
  }

  String get color {
    switch (this) {
      case AirQualityLevel.good:
        return '#4CAF50'; // Green
      case AirQualityLevel.moderate:
        return '#FFEB3B'; // Yellow
      case AirQualityLevel.unhealthyForSensitive:
        return '#FF9800'; // Orange
      case AirQualityLevel.unhealthy:
        return '#F44336'; // Red
      case AirQualityLevel.hazardous:
        return '#9C27B0'; // Purple
    }
  }
}
