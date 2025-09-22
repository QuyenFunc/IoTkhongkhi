import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DeviceControlService {
  static final DeviceControlService _instance = DeviceControlService._internal();
  factory DeviceControlService() => _instance;
  DeviceControlService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send restart command to device
  Future<bool> restartDevice(String deviceId) async {
    return await _sendCommand(deviceId, 'restart', true);
  }

  /// Send factory reset command to device
  Future<bool> factoryResetDevice(String deviceId) async {
    return await _sendCommand(deviceId, 'factoryReset', true);
  }

  /// Toggle LED indicator on device
  Future<bool> toggleLED(String deviceId, bool enabled) async {
    return await _sendCommand(deviceId, 'ledEnabled', enabled);
  }

  /// Set data update interval (in seconds)
  Future<bool> setUpdateInterval(String deviceId, int intervalSeconds) async {
    if (intervalSeconds < 5 || intervalSeconds > 3600) {
      throw ArgumentError('Update interval must be between 5 and 3600 seconds');
    }
    return await _sendCommand(deviceId, 'updateInterval', intervalSeconds);
  }

  /// Set device location/name
  Future<bool> setDeviceLocation(String deviceId, String location) async {
    if (location.trim().isEmpty) {
      throw ArgumentError('Location cannot be empty');
    }
    return await _sendCommand(deviceId, 'location', location.trim());
  }

  /// Enable/disable WiFi AP mode for configuration
  Future<bool> toggleConfigMode(String deviceId, bool enabled) async {
    return await _sendCommand(deviceId, 'configMode', enabled);
  }

  /// Set WiFi credentials (for reconfiguration)
  Future<bool> setWiFiCredentials({
    required String deviceId,
    required String ssid,
    required String password,
  }) async {
    if (ssid.trim().isEmpty) {
      throw ArgumentError('SSID cannot be empty');
    }

    final success = await _sendCommand(deviceId, 'wifiConfig', {
      'ssid': ssid.trim(),
      'password': password,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    return success;
  }

  /// Calibrate sensors
  Future<bool> calibrateSensors(String deviceId) async {
    return await _sendCommand(deviceId, 'calibrate', true);
  }

  /// Get device status and last command results
  Stream<Map<String, dynamic>?> getDeviceStatus(String deviceId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _database
        .ref('users/${user.uid}/devices/$deviceId/status')
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }

      try {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing device status: $e');
        }
        return null;
      }
    });
  }

  /// Get command history for device
  Future<List<Map<String, dynamic>>> getCommandHistory(String deviceId) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _database
          .ref('users/${user.uid}/devices/$deviceId/commandHistory')
          .limitToLast(20)
          .get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final commands = <Map<String, dynamic>>[];

      for (final entry in data.entries) {
        final commandData = Map<String, dynamic>.from(entry.value as Map);
        commandData['id'] = entry.key;
        commands.add(commandData);
      }

      // Sort by timestamp descending
      commands.sort((a, b) {
        final aTime = a['timestamp'] as int? ?? 0;
        final bTime = b['timestamp'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      return commands;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting command history: $e');
      }
      return [];
    }
  }

  /// Send command to device via Firebase
  Future<bool> _sendCommand(String deviceId, String command, dynamic value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final commandId = 'cmd_${timestamp}_${command}';

      // Send command to device's command queue
      await _database
          .ref('users/${user.uid}/devices/$deviceId/commands/$command')
          .set({
        'value': value,
        'timestamp': timestamp,
        'status': 'pending',
        'commandId': commandId,
      });

      // Also add to command history
      await _database
          .ref('users/${user.uid}/devices/$deviceId/commandHistory/$commandId')
          .set({
        'command': command,
        'value': value,
        'timestamp': timestamp,
        'status': 'sent',
      });

      if (kDebugMode) {
        print('📤 Command sent to device $deviceId: $command = $value');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending command: $e');
      }
      return false;
    }
  }

  /// Clear completed commands (cleanup)
  Future<void> clearCompletedCommands(String deviceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _database
          .ref('users/${user.uid}/devices/$deviceId/commands')
          .get();

      if (!snapshot.exists || snapshot.value == null) return;

      final commands = Map<String, dynamic>.from(snapshot.value as Map);
      final batch = <Future<void>>[];

      for (final entry in commands.entries) {
        final commandData = entry.value as Map<dynamic, dynamic>;
        final status = commandData['status'] as String?;
        
        if (status == 'completed' || status == 'failed') {
          batch.add(_database
              .ref('users/${user.uid}/devices/$deviceId/commands/${entry.key}')
              .remove());
        }
      }

      await Future.wait(batch);

      if (kDebugMode) {
        print('🧹 Cleared ${batch.length} completed commands for device $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing commands: $e');
      }
    }
  }

  /// Check if device is online (based on last seen timestamp)
  Future<bool> isDeviceOnline(String deviceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _database
          .ref('users/${user.uid}/devices/$deviceId/lastSeen')
          .get();

      if (!snapshot.exists || snapshot.value == null) {
        return false;
      }

      final lastSeen = snapshot.value as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      final diffMinutes = (now - lastSeen) / (1000 * 60);

      // Consider device online if last seen within 5 minutes
      return diffMinutes <= 5;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking device online status: $e');
      }
      return false;
    }
  }

  /// Get device configuration
  Future<Map<String, dynamic>?> getDeviceConfig(String deviceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _database
          .ref('users/${user.uid}/devices/$deviceId/config')
          .get();

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device config: $e');
      }
      return null;
    }
  }

  /// Update device configuration
  Future<bool> updateDeviceConfig(String deviceId, Map<String, dynamic> config) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _database
          .ref('users/${user.uid}/devices/$deviceId/config')
          .update(config);

      if (kDebugMode) {
        print('📝 Device config updated for $deviceId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating device config: $e');
      }
      return false;
    }
  }
}
