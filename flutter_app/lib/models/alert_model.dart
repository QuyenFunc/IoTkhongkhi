import 'package:flutter/material.dart';

class AlertModel {
  String? id;
  final String deviceId;
  final String type;
  final String message;
  final double? value;
  final double? threshold;
  final int? timestamp;
  final bool acknowledged;
  final int? acknowledgedAt;

  AlertModel({
    this.id,
    required this.deviceId,
    required this.type,
    required this.message,
    this.value,
    this.threshold,
    this.timestamp,
    this.acknowledged = false,
    this.acknowledgedAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String?,
      deviceId: json['deviceId'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      value: _parseDouble(json['value']),
      threshold: _parseDouble(json['threshold']),
      timestamp: _parseInt(json['timestamp']),
      acknowledged: json['acknowledged'] as bool? ?? false,
      acknowledgedAt: _parseInt(json['acknowledgedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'type': type,
      'message': message,
      'value': value,
      'threshold': threshold,
      'timestamp': timestamp,
      'acknowledged': acknowledged,
      'acknowledgedAt': acknowledgedAt,
    };
  }

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

  // Alert severity levels
  AlertSeverity get severity {
    switch (type) {
      case 'temperature_critical':
      case 'humidity_critical':
      case 'dust_critical':
      case 'device_offline':
        return AlertSeverity.critical;
      
      case 'temperature_high':
      case 'temperature_low':
      case 'humidity_high':
      case 'humidity_low':
      case 'dust_warning':
        return AlertSeverity.warning;
      
      case 'temperature_normal':
      case 'humidity_normal':
      case 'dust_good':
      case 'device_online':
        return AlertSeverity.info;
      
      default:
        return AlertSeverity.low;
    }
  }

  // Alert category
  AlertCategory get category {
    if (type.startsWith('temperature_')) return AlertCategory.temperature;
    if (type.startsWith('humidity_')) return AlertCategory.humidity;
    if (type.startsWith('dust_')) return AlertCategory.dust;
    if (type.startsWith('device_')) return AlertCategory.device;
    return AlertCategory.system;
  }

  // DateTime helper
  DateTime? get dateTime => 
      timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp! * 1000) : null;

  DateTime? get acknowledgedDateTime => 
      acknowledgedAt != null ? DateTime.fromMillisecondsSinceEpoch(acknowledgedAt! * 1000) : null;

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

  String get fullFormattedTime {
    if (dateTime == null) return 'Unknown';
    return '${dateTime!.day}/${dateTime!.month}/${dateTime!.year} ${dateTime!.hour}:${dateTime!.minute.toString().padLeft(2, '0')}';
  }

  // Display helpers
  String get displayTitle {
    switch (category) {
      case AlertCategory.temperature:
        return 'Nhiệt độ';
      case AlertCategory.humidity:
        return 'Độ ẩm';
      case AlertCategory.dust:
        return 'Chất lượng không khí';
      case AlertCategory.device:
        return 'Thiết bị';
      case AlertCategory.system:
        return 'Hệ thống';
    }
  }

  String get displayIcon {
    switch (category) {
      case AlertCategory.temperature:
        return '🌡️';
      case AlertCategory.humidity:
        return '💧';
      case AlertCategory.dust:
        return '💨';
      case AlertCategory.device:
        return '📱';
      case AlertCategory.system:
        return '⚙️';
    }
  }

  String get severityText {
    switch (severity) {
      case AlertSeverity.critical:
        return 'Nghiêm trọng';
      case AlertSeverity.warning:
        return 'Cảnh báo';
      case AlertSeverity.info:
        return 'Thông tin';
      case AlertSeverity.low:
        return 'Thấp';
    }
  }

  @override
  String toString() {
    return 'AlertModel(type: $type, message: $message, severity: $severity, time: $formattedTime)';
  }

  AlertModel copyWith({
    String? id,
    String? deviceId,
    String? type,
    String? message,
    double? value,
    double? threshold,
    int? timestamp,
    bool? acknowledged,
    int? acknowledgedAt,
  }) {
    return AlertModel(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      message: message ?? this.message,
      value: value ?? this.value,
      threshold: threshold ?? this.threshold,
      timestamp: timestamp ?? this.timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }
}

enum AlertSeverity {
  critical,
  warning,
  info,
  low,
}

enum AlertCategory {
  temperature,
  humidity,
  dust,
  device,
  system,
}

// Extension to get colors for different alert types
extension AlertSeverityExtension on AlertSeverity {
  Color get color {
    switch (this) {
      case AlertSeverity.critical:
        return const Color(0xFFD32F2F); // Red
      case AlertSeverity.warning:
        return const Color(0xFFF57C00); // Orange
      case AlertSeverity.info:
        return const Color(0xFF1976D2); // Blue
      case AlertSeverity.low:
        return const Color(0xFF388E3C); // Green
    }
  }
  
  Color get backgroundColor {
    switch (this) {
      case AlertSeverity.critical:
        return const Color(0xFFFFEBEE); // Light red
      case AlertSeverity.warning:
        return const Color(0xFFFFF3E0); // Light orange
      case AlertSeverity.info:
        return const Color(0xFFE3F2FD); // Light blue
      case AlertSeverity.low:
        return const Color(0xFFE8F5E8); // Light green
    }
  }
}

extension AlertCategoryExtension on AlertCategory {
  Color get color {
    switch (this) {
      case AlertCategory.temperature:
        return const Color(0xFFFF5722); // Deep orange
      case AlertCategory.humidity:
        return const Color(0xFF03A9F4); // Light blue
      case AlertCategory.dust:
        return const Color(0xFF9C27B0); // Purple
      case AlertCategory.device:
        return const Color(0xFF607D8B); // Blue grey
      case AlertCategory.system:
        return const Color(0xFF795548); // Brown
    }
  }
}
