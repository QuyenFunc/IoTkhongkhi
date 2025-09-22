import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class SimplifiedFirebaseService {
  static final SimplifiedFirebaseService _instance = SimplifiedFirebaseService._internal();
  factory SimplifiedFirebaseService() => _instance;
  SimplifiedFirebaseService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Get all available devices
  Stream<List<DeviceData>> getAllDevices() {
    return _database.ref('devices').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <DeviceData>[];
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final devices = <DeviceData>[];

      for (final entry in data.entries) {
        try {
          final deviceData = Map<String, dynamic>.from(entry.value as Map);
          devices.add(DeviceData.fromJson(deviceData));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing device ${entry.key}: $e');
          }
        }
      }

      return devices;
    });
  }

  /// Get latest sensor data for a device
  Stream<SensorData?> getLatestSensorData(String deviceId) {
    return _database.ref('sensorData/$deviceId/latest').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }

      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return SensorData.fromJson(data);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing sensor data for $deviceId: $e');
        }
        return null;
      }
    });
  }

  /// Get historical sensor data for charts
  Future<List<SensorData>> getHistoricalData(String deviceId, {
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    try {
      Query query = _database.ref('sensorData/$deviceId/history');

      if (startTime != null) {
        query = query.orderByChild('timestamp').startAt(startTime.millisecondsSinceEpoch);
      }
      if (endTime != null) {
        query = query.endAt(endTime.millisecondsSinceEpoch);
      }
      if (limit != null) {
        query = query.limitToLast(limit);
      }

      final snapshot = await query.get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final sensorData = <SensorData>[];

      for (final entry in data.entries) {
        try {
          final pointData = Map<String, dynamic>.from(entry.value as Map);
          sensorData.add(SensorData.fromJson(pointData));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing historical data point: $e');
          }
        }
      }

      // Sort by timestamp
      sensorData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return sensorData;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting historical data: $e');
      }
      return [];
    }
  }

  /// Get alert thresholds for a device
  Future<AlertThresholds?> getAlertThresholds(String deviceId) async {
    try {
      final snapshot = await _database.ref('alertThresholds/$deviceId').get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return AlertThresholds.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting alert thresholds: $e');
      }
      return null;
    }
  }

  /// Set alert thresholds for a device
  Future<bool> setAlertThresholds(String deviceId, AlertThresholds thresholds) async {
    try {
      await _database.ref('alertThresholds/$deviceId').set(thresholds.toJson());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error setting alert thresholds: $e');
      }
      return false;
    }
  }

  /// Get alerts for a device
  Stream<List<AlertData>> getDeviceAlerts(String deviceId) {
    return _database.ref('alerts/$deviceId').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <AlertData>[];
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final alerts = <AlertData>[];

      for (final entry in data.entries) {
        try {
          final alertData = Map<String, dynamic>.from(entry.value as Map);
          alerts.add(AlertData.fromJson(alertData));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing alert ${entry.key}: $e');
          }
        }
      }

      // Sort by timestamp descending
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return alerts;
    });
  }

  /// Send command to device
  Future<bool> sendDeviceCommand(String deviceId, String command, dynamic value) async {
    try {
      final commandData = {
        'command': command,
        'value': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
      };

      await _database.ref('deviceCommands/$deviceId/$command').set(commandData);
      
      if (kDebugMode) {
        print('Command sent to device $deviceId: $command = $value');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending command: $e');
      }
      return false;
    }
  }

  /// Acknowledge alert
  Future<bool> acknowledgeAlert(String deviceId, String alertId) async {
    try {
      await _database.ref('alerts/$deviceId/$alertId').update({
        'acknowledged': true,
        'acknowledgedAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error acknowledging alert: $e');
      }
      return false;
    }
  }
}

// Data Models
class DeviceData {
  final String deviceId;
  final String deviceName;
  final String location;
  final String macAddress;
  final String ipAddress;
  final String wifiSSID;
  final String status;
  final DateTime lastSeen;
  final String firmware;

  DeviceData({
    required this.deviceId,
    required this.deviceName,
    required this.location,
    required this.macAddress,
    required this.ipAddress,
    required this.wifiSSID,
    required this.status,
    required this.lastSeen,
    required this.firmware,
  });

  factory DeviceData.fromJson(Map<String, dynamic> json) {
    return DeviceData(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      location: json['location'] as String,
      macAddress: json['macAddress'] as String,
      ipAddress: json['ipAddress'] as String,
      wifiSSID: json['wifiSSID'] as String,
      status: json['status'] as String,
      lastSeen: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(json['lastSeen']?.toString() ?? '0') ?? 0,
      ),
      firmware: json['firmware'] as String,
    );
  }

  bool get isOnline {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    return difference.inMinutes < 5; // Consider offline if not seen for 5 minutes
  }
}

class SensorData {
  final DateTime timestamp;
  final String deviceId;
  final double temperature;
  final double humidity;
  final double airQuality;
  final double? pm25;
  final double? pm10;
  final double? co2;
  final String status;
  final int? battery;
  final int? rssi;

  SensorData({
    required this.timestamp,
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.airQuality,
    this.pm25,
    this.pm10,
    this.co2,
    required this.status,
    this.battery,
    this.rssi,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
      ),
      deviceId: json['deviceId'] as String,
      temperature: double.tryParse(json['temperature']?.toString() ?? '0') ?? 0.0,
      humidity: double.tryParse(json['humidity']?.toString() ?? '0') ?? 0.0,
      airQuality: double.tryParse(json['airQuality']?.toString() ?? '0') ?? 0.0,
      pm25: double.tryParse(json['pm25']?.toString() ?? ''),
      pm10: double.tryParse(json['pm10']?.toString() ?? ''),
      co2: double.tryParse(json['co2']?.toString() ?? ''),
      status: json['status'] as String? ?? 'online',
      battery: int.tryParse(json['battery']?.toString() ?? ''),
      rssi: int.tryParse(json['rssi']?.toString() ?? ''),
    );
  }
}

class AlertThresholds {
  final ThresholdConfig temperature;
  final ThresholdConfig humidity;
  final ThresholdConfig airQuality;

  AlertThresholds({
    required this.temperature,
    required this.humidity,
    required this.airQuality,
  });

  factory AlertThresholds.fromJson(Map<String, dynamic> json) {
    return AlertThresholds(
      temperature: ThresholdConfig.fromJson(json['temperature'] as Map<String, dynamic>),
      humidity: ThresholdConfig.fromJson(json['humidity'] as Map<String, dynamic>),
      airQuality: ThresholdConfig.fromJson(json['airQuality'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'temperature': temperature.toJson(),
    'humidity': humidity.toJson(),
    'airQuality': airQuality.toJson(),
  };
}

class ThresholdConfig {
  final double min;
  final double max;
  final bool enabled;

  ThresholdConfig({
    required this.min,
    required this.max,
    required this.enabled,
  });

  factory ThresholdConfig.fromJson(Map<String, dynamic> json) {
    return ThresholdConfig(
      min: double.tryParse(json['min']?.toString() ?? '0') ?? 0.0,
      max: double.tryParse(json['max']?.toString() ?? '0') ?? 0.0,
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
    'enabled': enabled,
  };
}

class AlertData {
  final String alertId;
  final String deviceId;
  final String type;
  final String message;
  final double value;
  final double threshold;
  final DateTime timestamp;
  final bool acknowledged;
  final DateTime? acknowledgedAt;

  AlertData({
    required this.alertId,
    required this.deviceId,
    required this.type,
    required this.message,
    required this.value,
    required this.threshold,
    required this.timestamp,
    required this.acknowledged,
    this.acknowledgedAt,
  });

  factory AlertData.fromJson(Map<String, dynamic> json) {
    return AlertData(
      alertId: json['alertId'] as String,
      deviceId: json['deviceId'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      value: double.tryParse(json['value']?.toString() ?? '0') ?? 0.0,
      threshold: double.tryParse(json['threshold']?.toString() ?? '0') ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
      ),
      acknowledged: json['acknowledged'] as bool? ?? false,
      acknowledgedAt: json['acknowledgedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              int.tryParse(json['acknowledgedAt']?.toString() ?? '0') ?? 0,
            )
          : null,
    );
  }
}
