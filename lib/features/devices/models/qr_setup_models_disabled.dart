// QR Setup Models temporarily disabled - focusing on WiFi hotspot and Bluetooth connections
// This file is commented out to disable QR code functionality

import 'package:flutter/material.dart';

// All QR-related models are temporarily disabled to focus on WiFi hotspot and Bluetooth connections
// This is a placeholder file to prevent import errors

// Placeholder classes to prevent compilation errors
class QRSetupData {
  final String deviceId;
  final String setupKey;
  final String encryptedWifi;
  final String? deviceName;
  final String? firmwareVersion;

  const QRSetupData({
    required this.deviceId,
    required this.setupKey,
    required this.encryptedWifi,
    this.deviceName,
    this.firmwareVersion,
  });

  // Placeholder methods
  factory QRSetupData.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('QR Setup temporarily disabled');
  }
  
  Map<String, dynamic> toJson() {
    throw UnimplementedError('QR Setup temporarily disabled');
  }

  static QRSetupData? fromQRString(String qrString) {
    return null; // Always return null when disabled
  }
}

// Other placeholder classes
class DeviceRegistrationRequest {
  final String deviceId;
  final String setupKey;
  final String userId;
  final DateTime timestamp;

  const DeviceRegistrationRequest({
    required this.deviceId,
    required this.setupKey,
    required this.userId,
    required this.timestamp,
  });

  factory DeviceRegistrationRequest.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('QR Setup temporarily disabled');
  }
  
  Map<String, dynamic> toJson() {
    throw UnimplementedError('QR Setup temporarily disabled');
  }
}

class DeviceRegistrationResponse {
  final bool success;
  final String? message;
  final DateTime timestamp;
  final String? sessionToken; // Added for compatibility
  final Map<String, dynamic>? deviceInfo; // Added for compatibility

  const DeviceRegistrationResponse({
    required this.success,
    this.message,
    required this.timestamp,
    this.sessionToken,
    this.deviceInfo,
  });

  factory DeviceRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationResponse(
      success: json['success'] ?? false,
      message: json['message'],
      timestamp: DateTime.now(),
      sessionToken: json['sessionToken'],
      deviceInfo: json['deviceInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'sessionToken': sessionToken,
      'deviceInfo': deviceInfo,
    };
  }
}

// Enum placeholders
enum SetupStep {
  registerDevice,
  configureWifi,
  waitingConnection,
  verifyConnection,
  completed,
  failed,
}

class SetupProgress {
  final SetupStep currentStep;
  final String deviceId;
  final DateTime startTime;
  final DateTime? completedTime; // Added for compatibility
  final String? errorMessage;

  const SetupProgress({
    required this.currentStep,
    required this.deviceId,
    required this.startTime,
    this.completedTime,
    this.errorMessage,
  });

  factory SetupProgress.fromJson(Map<String, dynamic> json) {
    return SetupProgress(
      currentStep: SetupStep.values.firstWhere(
        (e) => e.toString().split('.').last == json['currentStep'],
        orElse: () => SetupStep.registerDevice,
      ),
      deviceId: json['deviceId'] ?? '',
      startTime: DateTime.now(),
      completedTime: json['completedTime'] != null ? DateTime.parse(json['completedTime']) : null,
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStep': currentStep.toString().split('.').last,
      'deviceId': deviceId,
      'startTime': startTime.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }
}

class DeviceConnectionStatus {
  final bool isOnline;
  final DateTime lastSeen;
  final String? wifiSSID;
  final int? signalStrength;
  final String status; // Added for compatibility

  const DeviceConnectionStatus({
    required this.isOnline,
    required this.lastSeen,
    this.wifiSSID,
    this.signalStrength,
    this.status = 'unknown',
  });

  factory DeviceConnectionStatus.fromJson(Map<String, dynamic> json) {
    return DeviceConnectionStatus(
      isOnline: json['isOnline'] ?? false,
      lastSeen: DateTime.now(),
      wifiSSID: json['wifiSSID'],
      signalStrength: json['signalStrength'],
      status: json['status'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'wifiSSID': wifiSSID,
      'signalStrength': signalStrength,
      'status': status,
    };
  }
}

class CurrentSensorData {
  final String deviceId;
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double pm25;
  final double pm10;
  final double co2;
  final double voc;

  const CurrentSensorData({
    required this.deviceId,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.pm25,
    required this.pm10,
    required this.co2,
    required this.voc,
  });

  factory CurrentSensorData.fromJson(Map<String, dynamic> json) {
    return CurrentSensorData(
      deviceId: json['deviceId'] ?? '',
      timestamp: DateTime.now(),
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      pm25: (json['pm25'] ?? 0.0).toDouble(),
      pm10: (json['pm10'] ?? 0.0).toDouble(),
      co2: (json['co2'] ?? 0.0).toDouble(),
      voc: (json['voc'] ?? 0.0).toDouble(),
    );
  }

  // Factory method for empty data
  factory CurrentSensorData.empty(String deviceId) {
    return CurrentSensorData(
      deviceId: deviceId,
      timestamp: DateTime.now(),
      temperature: 0.0,
      humidity: 0.0,
      pm25: 0.0,
      pm10: 0.0,
      co2: 0.0,
      voc: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'pm25': pm25,
      'pm10': pm10,
      'co2': co2,
      'voc': voc,
    };
  }

  // Placeholder method - return SensorData for compatibility
  SensorData toSensorData() {
    return SensorData(
      deviceId: deviceId,
      timestamp: timestamp,
      temperature: temperature,
      humidity: humidity,
      pm25: pm25,
      pm10: pm10,
      co2: co2,
      voc: voc,
      aqi: 0, // Default AQI
      alerts: {}, // Empty alerts
    );
  }
}

// SensorData class for compatibility with device_detail_screen.dart
class SensorData {
  final String deviceId;
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double pm25;
  final double pm10;
  final double co2;
  final double voc;
  final int aqi;
  final Map<String, bool> alerts;

  const SensorData({
    required this.deviceId,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.pm25,
    required this.pm10,
    required this.co2,
    required this.voc,
    required this.aqi,
    required this.alerts,
  });

  // Helper properties for UI
  bool get hasAlerts => alerts.values.any((alert) => alert);

  String get airQualityLevel {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Color get airQualityColor {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }
}

// Additional classes needed for QR setup service compatibility
class WiFiConfigurationRequest {
  final String deviceId;
  final String ssid;
  final String password;
  final DateTime timestamp;

  const WiFiConfigurationRequest({
    required this.deviceId,
    required this.ssid,
    required this.password,
    required this.timestamp,
  });

  factory WiFiConfigurationRequest.fromJson(Map<String, dynamic> json) {
    return WiFiConfigurationRequest(
      deviceId: json['deviceId'] ?? '',
      ssid: json['ssid'] ?? '',
      password: json['password'] ?? '',
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'ssid': ssid,
      'password': password,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class DeviceConfigStatus {
  final bool isWifiSaved;
  final bool isConnected;
  final String? errorMessage;

  const DeviceConfigStatus({
    required this.isWifiSaved,
    required this.isConnected,
    this.errorMessage,
  });

  // Helper getter for compatibility
  bool get hasFailed => errorMessage != null;

  factory DeviceConfigStatus.fromJson(Map<String, dynamic> json) {
    return DeviceConfigStatus(
      isWifiSaved: json['isWifiSaved'] ?? false,
      isConnected: json['isConnected'] ?? false,
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isWifiSaved': isWifiSaved,
      'isConnected': isConnected,
      'errorMessage': errorMessage,
    };
  }
}
