import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/alert_threshold_model.dart';
import '../../devices/services/notification_service.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final Uuid _uuid = const Uuid();

  /// Get alert thresholds for a device
  Stream<List<AlertThreshold>> getDeviceThresholds(String deviceId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _database
        .ref('users/${user.uid}/alertThresholds')
        .orderByChild('deviceId')
        .equalTo(deviceId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <AlertThreshold>[];
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final thresholds = <AlertThreshold>[];

      for (final entry in data.entries) {
        try {
          final thresholdData = Map<String, dynamic>.from(entry.value as Map);
          thresholdData['id'] = entry.key;
          
          // Convert type string to enum
          final typeKey = thresholdData['type'] as String;
          final type = AlertType.values.firstWhere(
            (t) => t.key == typeKey,
            orElse: () => AlertType.temperature,
          );
          thresholdData['type'] = type;

          // Convert timestamps
          if (thresholdData['createdAt'] is int) {
            thresholdData['createdAt'] = DateTime.fromMillisecondsSinceEpoch(
              thresholdData['createdAt'] as int,
            ).toIso8601String();
          }
          if (thresholdData['updatedAt'] is int) {
            thresholdData['updatedAt'] = DateTime.fromMillisecondsSinceEpoch(
              thresholdData['updatedAt'] as int,
            ).toIso8601String();
          }

          thresholds.add(AlertThreshold.fromJson(thresholdData));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing threshold ${entry.key}: $e');
          }
        }
      }

      return thresholds;
    });
  }

  /// Create or update alert threshold
  Future<AlertThreshold> saveThreshold(AlertThreshold threshold) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final thresholdData = threshold.toJson();
      
      // Convert type enum to string
      thresholdData['type'] = threshold.type.key;
      
      // Convert timestamps to milliseconds
      thresholdData['createdAt'] = threshold.createdAt.millisecondsSinceEpoch;
      if (threshold.updatedAt != null) {
        thresholdData['updatedAt'] = threshold.updatedAt!.millisecondsSinceEpoch;
      }
      
      // Remove ID from data as it's used as the key
      thresholdData.remove('id');

      await _database
          .ref('users/${user.uid}/alertThresholds/${threshold.id}')
          .set(thresholdData);

      if (kDebugMode) {
        print('Alert threshold saved: ${threshold.id}');
      }

      return threshold;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving threshold: $e');
      }
      rethrow;
    }
  }

  /// Delete alert threshold
  Future<void> deleteThreshold(String thresholdId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _database
          .ref('users/${user.uid}/alertThresholds/$thresholdId')
          .remove();

      if (kDebugMode) {
        print('Alert threshold deleted: $thresholdId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting threshold: $e');
      }
      rethrow;
    }
  }

  /// Create default thresholds for a new device
  Future<void> createDefaultThresholds(String deviceId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final defaultThresholds = [
        AlertThreshold(
          id: _uuid.v4(),
          deviceId: deviceId,
          userId: user.uid,
          type: AlertType.temperature,
          minValue: 15.0,
          maxValue: 35.0,
          enabled: true,
          createdAt: DateTime.now(),
        ),
        AlertThreshold(
          id: _uuid.v4(),
          deviceId: deviceId,
          userId: user.uid,
          type: AlertType.humidity,
          minValue: 30.0,
          maxValue: 80.0,
          enabled: true,
          createdAt: DateTime.now(),
        ),
        AlertThreshold(
          id: _uuid.v4(),
          deviceId: deviceId,
          userId: user.uid,
          type: AlertType.airQuality,
          minValue: 0.0,
          maxValue: 50.0,
          enabled: true,
          createdAt: DateTime.now(),
        ),
      ];

      for (final threshold in defaultThresholds) {
        await saveThreshold(threshold);
      }

      if (kDebugMode) {
        print('Default thresholds created for device: $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating default thresholds: $e');
      }
    }
  }

  /// Check sensor values against thresholds
  Future<void> checkThresholds({
    required String deviceId,
    required double temperature,
    required double humidity,
    required double airQuality,
    double? pm25,
    double? pm10,
    double? co2,
  }) async {
    try {
      final thresholds = await getDeviceThresholds(deviceId).first;
      
      final sensorValues = {
        AlertType.temperature: temperature,
        AlertType.humidity: humidity,
        AlertType.airQuality: airQuality,
        if (pm25 != null) AlertType.pm25: pm25,
        if (pm10 != null) AlertType.pm10: pm10,
        if (co2 != null) AlertType.co2: co2,
      };

      for (final threshold in thresholds) {
        if (!threshold.enabled) continue;

        final value = sensorValues[threshold.type];
        if (value == null) continue;

        // Check if value is outside threshold range
        if (value < threshold.minValue || value > threshold.maxValue) {
          await _triggerAlert(
            threshold: threshold,
            currentValue: value,
            isHigh: value > threshold.maxValue,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking thresholds: $e');
      }
    }
  }

  /// Trigger an alert
  Future<void> _triggerAlert({
    required AlertThreshold threshold,
    required double currentValue,
    required bool isHigh,
  }) async {
    try {
      final alertEvent = AlertEvent(
        id: _uuid.v4(),
        deviceId: threshold.deviceId,
        userId: threshold.userId,
        type: threshold.type,
        value: currentValue,
        threshold: isHigh ? threshold.maxValue : threshold.minValue,
        message: _generateAlertMessage(threshold.type, currentValue, isHigh),
        timestamp: DateTime.now(),
        acknowledged: false,
      );

      // Save alert event
      await _saveAlertEvent(alertEvent);

      // Send push notification
      await _notificationService.sendAlertNotification(
        title: 'Cảnh báo ${threshold.type.displayName}',
        body: alertEvent.message,
        deviceId: threshold.deviceId,
      );

      if (kDebugMode) {
        print('Alert triggered: ${alertEvent.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error triggering alert: $e');
      }
    }
  }

  /// Save alert event to database
  Future<void> _saveAlertEvent(AlertEvent alertEvent) async {
    try {
      final alertData = alertEvent.toJson();
      alertData['type'] = alertEvent.type.key;
      alertData['timestamp'] = alertEvent.timestamp.millisecondsSinceEpoch;
      if (alertEvent.acknowledgedAt != null) {
        alertData['acknowledgedAt'] = alertEvent.acknowledgedAt!.millisecondsSinceEpoch;
      }
      alertData.remove('id');

      await _database
          .ref('users/${alertEvent.userId}/alertEvents/${alertEvent.id}')
          .set(alertData);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving alert event: $e');
      }
    }
  }

  /// Generate alert message
  String _generateAlertMessage(AlertType type, double value, bool isHigh) {
    final direction = isHigh ? 'cao' : 'thấp';
    final valueStr = value.toStringAsFixed(1);
    
    switch (type) {
      case AlertType.temperature:
        return 'Nhiệt độ quá $direction: ${valueStr}°C';
      case AlertType.humidity:
        return 'Độ ẩm quá $direction: ${valueStr}%';
      case AlertType.airQuality:
        return 'Chất lượng không khí quá $direction: ${valueStr}μg/m³';
      case AlertType.pm25:
        return 'PM2.5 quá $direction: ${valueStr}μg/m³';
      case AlertType.pm10:
        return 'PM10 quá $direction: ${valueStr}μg/m³';
      case AlertType.co2:
        return 'CO2 quá $direction: ${valueStr}ppm';
    }
  }

  /// Get alert events for a device
  Stream<List<AlertEvent>> getDeviceAlerts(String deviceId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _database
        .ref('users/${user.uid}/alertEvents')
        .orderByChild('deviceId')
        .equalTo(deviceId)
        .limitToLast(50) // Limit to last 50 alerts
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <AlertEvent>[];
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final alerts = <AlertEvent>[];

      for (final entry in data.entries) {
        try {
          final alertData = Map<String, dynamic>.from(entry.value as Map);
          alertData['id'] = entry.key;
          
          // Convert type string to enum
          final typeKey = alertData['type'] as String;
          final type = AlertType.values.firstWhere(
            (t) => t.key == typeKey,
            orElse: () => AlertType.temperature,
          );
          alertData['type'] = type;

          // Convert timestamps
          if (alertData['timestamp'] is int) {
            alertData['timestamp'] = DateTime.fromMillisecondsSinceEpoch(
              alertData['timestamp'] as int,
            ).toIso8601String();
          }
          if (alertData['acknowledgedAt'] is int) {
            alertData['acknowledgedAt'] = DateTime.fromMillisecondsSinceEpoch(
              alertData['acknowledgedAt'] as int,
            ).toIso8601String();
          }

          alerts.add(AlertEvent.fromJson(alertData));
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

  /// Acknowledge alert
  Future<void> acknowledgeAlert(String alertId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _database
          .ref('users/${user.uid}/alertEvents/$alertId')
          .update({
        'acknowledged': true,
        'acknowledgedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (kDebugMode) {
        print('Alert acknowledged: $alertId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error acknowledging alert: $e');
      }
    }
  }
}
