import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../shared/models/device_model.dart' as device_models;
// QR Setup temporarily disabled - using placeholder models
import '../models/qr_setup_models_disabled.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Helper method to safely convert dynamic map to Map<String, dynamic>
  Map<String, dynamic> _convertDynamicMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      // Handle nested maps recursively
      final result = <String, dynamic>{};
      data.forEach((key, value) {
        final stringKey = key.toString();
        if (value is Map) {
          result[stringKey] = _convertDynamicMap(value);
        } else if (value is List) {
          result[stringKey] = value.map((item) {
            if (item is Map) {
              return _convertDynamicMap(item);
            }
            return item;
          }).toList();
        } else {
          result[stringKey] = value;
        }
      });
      return result;
    } else {
      throw ArgumentError('Cannot convert ${data.runtimeType} to Map<String, dynamic>');
    }
  }

  /// Validate if data represents a complete device record
  bool _isValidDeviceRecord(Map<String, dynamic> data) {
    // Check for required device fields
    final requiredFields = ['name', 'location', 'type', 'status', 'ownerId', 'createdAt'];

    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        return false;
      }
    }

    // Check if this is just a status update (has only status-related fields)
    final statusOnlyFields = ['status', 'lastSeen', 'message', 'ipAddress', 'networkInfo'];
    final dataKeys = data.keys.toSet();
    final hasOnlyStatusFields = dataKeys.difference({'id'}).every((key) => statusOnlyFields.contains(key));

    if (hasOnlyStatusFields) {
      return false; // This is just a status update, not a device record
    }

    return true;
  }

  /// Ensure required List fields are not null
  void _ensureListFields(Map<String, dynamic> data) {
    // Ensure capabilities is a List
    if (data['capabilities'] == null) {
      data['capabilities'] = <String>[];
    } else if (data['capabilities'] is! List) {
      data['capabilities'] = <String>[];
    }

    // Ensure configuration exists and has alertRecipients
    if (data['configuration'] != null && data['configuration'] is Map) {
      try {
        final config = _convertDynamicMap(data['configuration']);
        if (config['alertRecipients'] == null || config['alertRecipients'] is! List) {
          config['alertRecipients'] = <String>[];
        }
        if (config['customSettings'] == null || config['customSettings'] is! Map) {
          config['customSettings'] = <String, dynamic>{};
        }
        if (config['thresholds'] == null || config['thresholds'] is! Map) {
          config['thresholds'] = {
            'minTemperature': 0.0,
            'maxTemperature': 50.0,
            'minHumidity': 0.0,
            'maxHumidity': 100.0,
            'maxPM25': 50.0,
            'maxPM10': 100.0,
            'maxCO2': 1000.0,
            'maxVOC': 500.0,
          };
        }
        data['configuration'] = config;
      } catch (e) {
        if (kDebugMode) {
          print('Error converting configuration: $e');
        }
        // Create default configuration if conversion fails
        data['configuration'] = _defaultConfiguration(data['id']);
      }
    } else if (data['configuration'] == null) {
      // Create default configuration if missing
      data['configuration'] = _defaultConfiguration(data['id']);
    }
  }

  Map<String, dynamic> _defaultConfiguration(dynamic id) => {
        'mqttTopic': 'iot/devices/${id ?? 'unknown'}/data',
        'reportingInterval': 30,
        'thresholds': {
          'minTemperature': 0.0,
          'maxTemperature': 50.0,
          'minHumidity': 0.0,
          'maxHumidity': 100.0,
          'maxPM25': 50.0,
          'maxPM10': 100.0,
          'maxCO2': 1000.0,
          'maxVOC': 500.0,
        },
        'alertsEnabled': true,
        'alertRecipients': <String>[],
        'customSettings': <String, dynamic>{},
      };

  /// Normalize status field: accepts string or connection-status map
  void _normalizeStatus(Map<String, dynamic> data) {
    final statusVal = data['status'];
    if (statusVal is Map) {
      final conn = _convertDynamicMap(statusVal);
      final connStatus = (conn['status'] as String?)?.toLowerCase();
      // Preserve connection status for other UI parts if needed
      data['connectionStatus'] = conn;
      // Map to device status enum values
      switch (connStatus) {
        case 'online':
          data['status'] = 'active';
          break;
        case 'offline':
          data['status'] = 'inactive';
          break;
        case 'error':
          data['status'] = 'error';
          break;
        default:
          // Fallback to inactive
          data['status'] = 'inactive';
      }
    } else if (statusVal is String) {
      // Already a string; ensure it's one of enum values or map common aliases
      final s = statusVal.toLowerCase();
      if (s == 'online') data['status'] = 'active';
      if (s == 'offline') data['status'] = 'inactive';
    } else {
      // Missing or unexpected: default to inactive
      data['status'] = 'inactive';
    }
  }

  /// Get all devices for current user
  Stream<List<device_models.DeviceModel>> getUserDevices() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _database
        .child('devices')
        .orderByChild('ownerId')
        .equalTo(user.uid)
        .onValue
        .map((event) {
      try {
        final data = event.snapshot.value;
        if (kDebugMode) {
          print('📱 Raw device data from Firebase: $data');
          print('📱 Data type: ${data.runtimeType}');
        }

        if (data == null) {
          if (kDebugMode) {
            print('📱 No device data found');
          }
          return <device_models.DeviceModel>[];
        }

        // Handle different data types from Firebase
        Map<dynamic, dynamic> dataMap;
        if (data is Map<dynamic, dynamic>) {
          dataMap = data;
          if (kDebugMode) {
            print('📱 Found ${dataMap.length} device records');
          }
        } else {
          if (kDebugMode) {
            print('❌ Unexpected data type: ${data.runtimeType}');
          }
          return <device_models.DeviceModel>[];
        }

        return dataMap.entries.map((entry) {
          try {
            final deviceData = _convertDynamicMap(entry.value);
            deviceData['id'] = entry.key;

            // Validate that this is a complete device record
            if (!_isValidDeviceRecord(deviceData)) {
              if (kDebugMode) {
                print('❌ Skipping invalid device record ${entry.key}');
                print('   Available fields: ${deviceData.keys.toList()}');
                print('   Data: $deviceData');
              }
              return null;
            }

            if (kDebugMode) {
              print('✅ Valid device record found: ${entry.key} - ${deviceData['name']}');
            }

            // Normalize status (accepts map or string)
            _normalizeStatus(deviceData);

            // Ensure required List fields are not null
            _ensureListFields(deviceData);

            return device_models.DeviceModel.fromJson(deviceData);
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing device ${entry.key}: $e');
            }
            return null;
          }
        }).where((device) => device != null).cast<device_models.DeviceModel>().toList();
      } catch (e) {
        if (kDebugMode) {
          print('Error in getUserDevices: $e');
        }
        return <device_models.DeviceModel>[];
      }
    }).asBroadcastStream();
  }

  /// Get specific device by ID
  Stream<device_models.DeviceModel?> getDevice(String deviceId) {
    return _database
        .child('devices')
        .child(deviceId)
        .onValue
        .map((event) {
      try {
        final data = event.snapshot.value;
        if (data == null) return null;

        final deviceData = _convertDynamicMap(data);
        deviceData['id'] = deviceId;

        // Validate that this is a complete device record
        if (!_isValidDeviceRecord(deviceData)) {
          if (kDebugMode) {
            print('Skipping invalid device record $deviceId: missing required fields');
          }
          return null;
        }

        // Normalize status (accepts map or string)
        _normalizeStatus(deviceData);

        // Ensure required List fields are not null
        _ensureListFields(deviceData);

        return device_models.DeviceModel.fromJson(deviceData);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing device $deviceId: $e');
        }
        return null;
      }
    }).asBroadcastStream();
  }

  /// Get real-time sensor data for a device
  Stream<CurrentSensorData?> getDeviceSensorData(String deviceId) {
    return _database
        .child('devices')
        .child(deviceId)
        .child('current')
        .onValue
        .map((event) {
      try {
        final data = event.snapshot.value;
        if (data == null) return null;

        return CurrentSensorData.fromJson(_convertDynamicMap(data));
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing sensor data for $deviceId: $e');
        }
        return null;
      }
    }).asBroadcastStream();
  }

  /// Get historical sensor data
  Future<List<CurrentSensorData>> getHistoricalData(
    String deviceId, {
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    try {
      Query query = _database
          .child('devices')
          .child(deviceId)
          .child('history');

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
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      return data.values
          .map((item) => CurrentSensorData.fromJson(_convertDynamicMap(item)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      if (kDebugMode) {
        print('Error getting historical data: $e');
      }
      return [];
    }
  }

  /// Add new device (called during setup)
  Future<device_models.DeviceModel> addDevice(device_models.DeviceModel device) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final deviceData = device.toJson();
      deviceData.remove('id'); // Remove ID as it will be the key

      await _database
          .child('devices')
          .child(device.id)
          .set(deviceData);

      if (kDebugMode) {
        print('Device added successfully: ${device.id}');
      }

      return device;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding device: $e');
      }
      rethrow;
    }
  }

  /// Update device information
  Future<device_models.DeviceModel> updateDevice(device_models.DeviceModel device) async {
    try {
      final deviceData = device.toJson();
      deviceData.remove('id');
      deviceData['updatedAt'] = DateTime.now().toIso8601String();

      await _database
          .child('devices')
          .child(device.id)
          .update(deviceData);

      if (kDebugMode) {
        print('Device updated successfully: ${device.id}');
      }

      return device.copyWith(updatedAt: DateTime.now());
    } catch (e) {
      if (kDebugMode) {
        print('Error updating device: $e');
      }
      rethrow;
    }
  }

  /// Delete device
  Future<void> deleteDevice(String deviceId) async {
    try {
      await _database
          .child('devices')
          .child(deviceId)
          .remove();

      if (kDebugMode) {
        print('Device deleted successfully: $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting device: $e');
      }
      rethrow;
    }
  }

  /// Update device status
  Future<void> updateDeviceStatus(String deviceId, device_models.DeviceStatus status) async {
    try {
      await _database
          .child('devices')
          .child(deviceId)
          .update({
        'status': status.toString().split('.').last,
        'lastSeenAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating device status: $e');
      }
      rethrow;
    }
  }

  /// Send command to device
  Future<void> sendDeviceCommand(String deviceId, Map<String, dynamic> command) async {
    try {
      await _database
          .child('devices')
          .child(deviceId)
          .child('commands')
          .push()
          .set({
        ...command,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      if (kDebugMode) {
        print('Command sent to device $deviceId: $command');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending command: $e');
      }
      rethrow;
    }
  }

  /// Get device alerts
  Stream<List<DeviceAlert>> getDeviceAlerts(String deviceId) {
    return _database
        .child('devices')
        .child(deviceId)
        .child('alerts')
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <DeviceAlert>[];

      return data.entries.map((entry) {
        final alertData = _convertDynamicMap(entry.value);
        alertData['id'] = entry.key;
        return DeviceAlert.fromJson(alertData);
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }).asBroadcastStream();
  }

  /// Check device connectivity
  Future<bool> pingDevice(String deviceId) async {
    try {
      // Send ping command and wait for response
      await sendDeviceCommand(deviceId, {'type': 'ping'});
      
      // Wait for response (simplified - in real implementation, listen for response)
      await Future.delayed(const Duration(seconds: 5));
      
      // Check if device responded (simplified)
      final device = await getDevice(deviceId).first;
      return device?.status == device_models.DeviceStatus.active;
    } catch (e) {
      return false;
    }
  }

  /// Get device statistics
  Future<DeviceStatistics> getDeviceStatistics(String deviceId) async {
    try {
      final snapshot = await _database
          .child('devices')
          .child(deviceId)
          .child('statistics')
          .get();

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return DeviceStatistics.empty();
      }

      return DeviceStatistics.fromJson(_convertDynamicMap(data));
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device statistics: $e');
      }
      return DeviceStatistics.empty();
    }
  }

  /// Update device configuration
  Future<void> updateDeviceConfiguration(String deviceId, device_models.DeviceConfiguration configuration) async {
    try {
      await _database
          .child('devices')
          .child(deviceId)
          .update({
        'configuration': configuration.toJson(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('Device configuration updated successfully: $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating device configuration: $e');
      }
      rethrow;
    }
  }

  /// Calibrate device sensors
  Future<void> calibrateDevice(String deviceId, Map<String, double> calibrationValues) async {
    try {
      // Send calibration command to device
      await sendDeviceCommand(deviceId, {
        'type': 'calibrate',
        'calibrationValues': calibrationValues,
      });

      // Update device metadata with calibration info
      await _database
          .child('devices')
          .child(deviceId)
          .update({
        'metadata.lastCalibration': DateTime.now().toIso8601String(),
        'metadata.calibrationValues': calibrationValues,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('Device calibrated successfully: $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calibrating device: $e');
      }
      rethrow;
    }
  }

  /// Reset device to factory settings
  Future<void> resetDevice(String deviceId) async {
    try {
      // Send reset command to device
      await sendDeviceCommand(deviceId, {
        'type': 'factory_reset',
      });

      // Reset device configuration to default
      final defaultConfig = device_models.DeviceConfiguration.defaultConfiguration(deviceId);
      await updateDeviceConfiguration(deviceId, defaultConfig);

      if (kDebugMode) {
        print('Device reset to factory settings: $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting device: $e');
      }
      rethrow;
    }
  }

  /// Restart device
  Future<void> restartDevice(String deviceId) async {
    try {
      await sendDeviceCommand(deviceId, {
        'type': 'restart',
      });

      if (kDebugMode) {
        print('Device restart command sent: $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error restarting device: $e');
      }
      rethrow;
    }
  }

  /// Update device firmware
  Future<void> updateFirmware(String deviceId, String firmwareUrl) async {
    try {
      await sendDeviceCommand(deviceId, {
        'type': 'firmware_update',
        'firmwareUrl': firmwareUrl,
      });

      if (kDebugMode) {
        print('Firmware update command sent: $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating firmware: $e');
      }
      rethrow;
    }
  }

  /// Set device sleep mode
  Future<void> setDeviceSleepMode(String deviceId, bool enabled, int? sleepDuration) async {
    try {
      await sendDeviceCommand(deviceId, {
        'type': 'sleep_mode',
        'enabled': enabled,
        'duration': sleepDuration,
      });

      if (kDebugMode) {
        print('Sleep mode command sent: $deviceId, enabled: $enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting sleep mode: $e');
      }
      rethrow;
    }
  }

  /// Get device logs
  Future<List<DeviceLog>> getDeviceLogs(String deviceId, {int limit = 100}) async {
    try {
      final snapshot = await _database
          .child('devices')
          .child(deviceId)
          .child('logs')
          .orderByChild('timestamp')
          .limitToLast(limit)
          .get();

      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return [];
      }

      final logs = <DeviceLog>[];
      data.forEach((key, value) {
        try {
          final logData = _convertDynamicMap(value);
          logs.add(DeviceLog.fromJson(logData));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing log entry: $e');
          }
        }
      });

      // Sort by timestamp descending (newest first)
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device logs: $e');
      }
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up any subscriptions if needed
  }
}

/// Device Alert Model
class DeviceAlert {
  final String id;
  final String deviceId;
  final AlertType type;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  const DeviceAlert({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.isRead,
    this.data,
  });

  factory DeviceAlert.fromJson(Map<String, dynamic> json) {
    return DeviceAlert(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      type: AlertType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AlertType.other,
      ),
      message: json['message'] as String,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.info,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'type': type.name,
      'message': message,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }
}

enum AlertType {
  highTemperature,
  lowTemperature,
  highHumidity,
  lowHumidity,
  highPM25,
  highPM10,
  highCO2,
  highVOC,
  deviceOffline,
  deviceError,
  batteryLow,
  other,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

/// Device Statistics Model
class DeviceStatistics {
  final int totalDataPoints;
  final DateTime? firstDataPoint;
  final DateTime? lastDataPoint;
  final double averageTemperature;
  final double averageHumidity;
  final double averagePM25;
  final int alertCount;
  final double uptime;

  const DeviceStatistics({
    required this.totalDataPoints,
    this.firstDataPoint,
    this.lastDataPoint,
    required this.averageTemperature,
    required this.averageHumidity,
    required this.averagePM25,
    required this.alertCount,
    required this.uptime,
  });

  factory DeviceStatistics.fromJson(Map<String, dynamic> json) {
    return DeviceStatistics(
      totalDataPoints: json['totalDataPoints'] as int? ?? 0,
      firstDataPoint: json['firstDataPoint'] != null
          ? DateTime.parse(json['firstDataPoint'] as String)
          : null,
      lastDataPoint: json['lastDataPoint'] != null
          ? DateTime.parse(json['lastDataPoint'] as String)
          : null,
      averageTemperature: (json['averageTemperature'] as num?)?.toDouble() ?? 0.0,
      averageHumidity: (json['averageHumidity'] as num?)?.toDouble() ?? 0.0,
      averagePM25: (json['averagePM25'] as num?)?.toDouble() ?? 0.0,
      alertCount: json['alertCount'] as int? ?? 0,
      uptime: (json['uptime'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory DeviceStatistics.empty() {
    return const DeviceStatistics(
      totalDataPoints: 0,
      averageTemperature: 0.0,
      averageHumidity: 0.0,
      averagePM25: 0.0,
      alertCount: 0,
      uptime: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDataPoints': totalDataPoints,
      'firstDataPoint': firstDataPoint?.toIso8601String(),
      'lastDataPoint': lastDataPoint?.toIso8601String(),
      'averageTemperature': averageTemperature,
      'averageHumidity': averageHumidity,
      'averagePM25': averagePM25,
      'alertCount': alertCount,
      'uptime': uptime,
    };
  }
}

/// Device Log Model
class DeviceLog {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? category;
  final Map<String, dynamic>? metadata;

  const DeviceLog({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.category,
    this.metadata,
  });

  factory DeviceLog.fromJson(Map<String, dynamic> json) {
    return DeviceLog(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['level'],
        orElse: () => LogLevel.info,
      ),
      message: json['message'] ?? '',
      category: json['category'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.toString().split('.').last,
      'message': message,
      'category': category,
      'metadata': metadata,
    };
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}
