class VoiceCommand {
  final String originalText;
  final String normalizedText;
  final VoiceIntent intent;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final double confidence;

  const VoiceCommand({
    required this.originalText,
    required this.normalizedText,
    required this.intent,
    this.parameters = const {},
    required this.timestamp,
    this.confidence = 1.0,
  });

  factory VoiceCommand.fromText(String text, VoiceIntent intent) {
    return VoiceCommand(
      originalText: text,
      normalizedText: text.toLowerCase().trim(),
      intent: intent,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'VoiceCommand(text: $originalText, intent: $intent, confidence: $confidence)';
  }
}

// Voice command pattern for matching user input
class VoiceCommandPattern {
  final List<String> patterns;
  final VoiceIntent intent;

  const VoiceCommandPattern({
    required this.patterns,
    required this.intent,
  });
}

enum VoiceIntent {
  getAirQuality,
  getTemperature,
  getHumidity,
  getPM25,
  getDeviceStatus,
  getAlerts,
  getFullReport,
  unknown;

  String get displayName {
    switch (this) {
      case VoiceIntent.getAirQuality:
        return 'Chất lượng không khí';
      case VoiceIntent.getTemperature:
        return 'Nhiệt độ';
      case VoiceIntent.getHumidity:
        return 'Độ ẩm';
      case VoiceIntent.getPM25:
        return 'PM2.5';
      case VoiceIntent.getDeviceStatus:
        return 'Trạng thái thiết bị';
      case VoiceIntent.getAlerts:
        return 'Cảnh báo';
      case VoiceIntent.getFullReport:
        return 'Báo cáo tổng quan';
      case VoiceIntent.unknown:
        return 'Không xác định';
    }
  }

  String get description {
    switch (this) {
      case VoiceIntent.getAirQuality:
        return 'Kiểm tra chất lượng không khí tổng quan';
      case VoiceIntent.getTemperature:
        return 'Xem nhiệt độ hiện tại';
      case VoiceIntent.getHumidity:
        return 'Xem độ ẩm hiện tại';
      case VoiceIntent.getPM25:
        return 'Kiểm tra chỉ số bụi mịn PM2.5';
      case VoiceIntent.getDeviceStatus:
        return 'Xem trạng thái kết nối ESP32';
      case VoiceIntent.getAlerts:
        return 'Kiểm tra các cảnh báo';
      case VoiceIntent.getFullReport:
        return 'Báo cáo chi tiết tất cả thông số';
      case VoiceIntent.unknown:
        return 'Lệnh không được nhận dạng';
    }
  }

  List<String> get examplePhrases {
    switch (this) {
      case VoiceIntent.getAirQuality:
        return [
          'Chất lượng không khí thế nào?',
          'Không khí có tốt không?',
          'Kiểm tra chất lượng không khí',
        ];
      case VoiceIntent.getTemperature:
        return [
          'Nhiệt độ bao nhiêu?',
          'Bao nhiêu độ?',
          'Kiểm tra nhiệt độ',
        ];
      case VoiceIntent.getHumidity:
        return [
          'Độ ẩm bao nhiêu?',
          'Kiểm tra độ ẩm',
          'Ẩm độ như nào?',
        ];
      case VoiceIntent.getPM25:
        return [
          'Chỉ số PM2.5?',
          'Bụi mịn như nào?',
          'Kiểm tra PM2.5',
        ];
      case VoiceIntent.getDeviceStatus:
        return [
          'Thiết bị có hoạt động không?',
          'Trạng thái ESP32',
          'Kiểm tra kết nối',
        ];
      case VoiceIntent.getAlerts:
        return [
          'Có cảnh báo gì không?',
          'Kiểm tra cảnh báo',
          'Có nguy hiểm gì không?',
        ];
      case VoiceIntent.getFullReport:
        return [
          'Báo cáo tổng quan',
          'Tất cả thông tin',
          'Báo cáo đầy đủ',
        ];
      case VoiceIntent.unknown:
        return [];
    }
  }
}
