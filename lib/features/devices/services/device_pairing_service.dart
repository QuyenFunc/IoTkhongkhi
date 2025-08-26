import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Service for handling device pairing with new userKey-based flow
class DevicePairingService {
  static final DevicePairingService _instance = DevicePairingService._internal();
  factory DevicePairingService() => _instance;
  DevicePairingService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  StreamSubscription<DatabaseEvent>? _pendingDevicesSubscription;

  /// Generate a unique user key for the current user
  String generateUserKey() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    // Generate a unique key based on user ID and timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userKey = '${user.uid.substring(0, 8)}_${timestamp.toString().substring(8)}';
    
    if (kDebugMode) {
      print('🔑 Generated user key: $userKey');
    }
    
    return userKey;
  }

  /// Start listening for pending devices with the user's key
  Stream<Map<String, dynamic>?> listenForPendingDevice(String userKey) {
    if (kDebugMode) {
      print('👂 Starting to listen for pending devices with userKey: $userKey');
      print('🔍 Firebase Database URL: ${_database.app.options.databaseURL}');
    }

    final controller = StreamController<Map<String, dynamic>?>.broadcast();

    // Listen to the entire pendingDevices node
    _pendingDevicesSubscription = _database.ref('pendingDevices').onValue.listen(
      (DatabaseEvent event) {
        try {
          if (kDebugMode) {
            print('📡 Firebase data received: ${event.snapshot.exists}');
          }
          
          if (event.snapshot.exists && event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            if (kDebugMode) {
              print('📊 Total pending devices: ${data.length}');
              print('🔍 Looking for userKey: $userKey');
            }
            
            // Look for device with matching userKey
            for (final entry in data.entries) {
              final deviceData = entry.value as Map<dynamic, dynamic>;
              final deviceUserKey = deviceData['userKey'] as String?;
              
              if (kDebugMode) {
                print('🔎 Device ${entry.key}: userKey = $deviceUserKey');
              }
              
              if (deviceUserKey == userKey) {
                if (kDebugMode) {
                  print('🎯 Found pending device with matching userKey!');
                  print('Device ID: ${entry.key}');
                  print('Device data: $deviceData');
                }
                
                // Convert to proper format
                final deviceInfo = Map<String, dynamic>.from(deviceData);
                deviceInfo['deviceId'] = entry.key;
                
                controller.add(deviceInfo);
                return;
              }
            }
          } else {
            if (kDebugMode) {
              print('📭 No pending devices found in Firebase');
            }
          }
          
          // No matching device found
          if (kDebugMode) {
            print('❌ No device found with userKey: $userKey');
          }
          controller.add(null);
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error processing pending devices: $e');
          }
          controller.addError(e);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('❌ Error listening to pending devices: $error');
        }
        controller.addError(error);
      },
    );

    return controller.stream;
  }

  /// Stop listening for pending devices
  void stopListening() {
    if (kDebugMode) {
      print('🛑 Stopping pending device listener');
    }
    
    _pendingDevicesSubscription?.cancel();
    _pendingDevicesSubscription = null;
  }

  /// Pair a device by moving it from pendingDevices to user's devices
  Future<bool> pairDevice({
    required String deviceId,
    required Map<String, dynamic> deviceData,
    String? customDeviceName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('🔗 Pairing device: $deviceId');
        print('User: ${user.uid}');
      }

      // Prepare device data for user's devices collection
      final userDeviceData = {
        'deviceId': deviceId,
        'deviceName': customDeviceName ?? deviceData['deviceName'] ?? 'ESP32 Air Monitor',
        'macAddress': deviceData['macAddress'],
        'ipAddress': deviceData['ipAddress'],
        'wifiSSID': deviceData['wifiSSID'],
        'status': 'online',
        'firmware': deviceData['firmware'] ?? '1.0.0',
        'location': 'Unknown',
        'createdAt': DateTime.now().toIso8601String(),
        'pairedAt': DateTime.now().toIso8601String(),
        'commands': {
          'restart': false,
          'reset': false,
          'updateInterval': 30,
          'requestData': false,
          'autoWarning': true,
        }
      };

      // Also register in deviceRegistry for Firebase rules
      final registryData = {
        'deviceId': deviceId,
        'ownerUID': user.uid,
        'deviceName': userDeviceData['deviceName'],
        'status': 'online',
        'registeredAt': DateTime.now().toIso8601String(),
      };

      // Batch write to move device from pending to paired
      final batch = <String, dynamic>{};
      batch['users/${user.uid}/devices/$deviceId'] = userDeviceData;
      // Also write to global devices collection so device list (which queries /devices by ownerId) can see it
      batch['devices/$deviceId'] = userDeviceData;
      batch['deviceRegistry/$deviceId'] = registryData;
      batch['pendingDevices/$deviceId'] = null; // Remove from pending

      await _database.ref().update(batch);

      if (kDebugMode) {
        print('✅ Device paired successfully!');
        print('Device moved to: users/${user.uid}/devices/$deviceId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error pairing device: $e');
      }
      return false;
    }
  }

  /// Get current user's devices
  Future<List<Map<String, dynamic>>> getUserDevices() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _database.ref('users/${user.uid}/devices').get();
      
      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final devicesData = snapshot.value as Map<dynamic, dynamic>;
      final devices = <Map<String, dynamic>>[];

      for (final entry in devicesData.entries) {
        final deviceData = Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>);
        deviceData['deviceId'] = entry.key;
        devices.add(deviceData);
      }

      if (kDebugMode) {
        print('📱 Found ${devices.length} user devices');
      }

      return devices;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user devices: $e');
      }
      return [];
    }
  }

  /// Listen to real-time sensor data for a device
  Stream<Map<String, dynamic>?> listenToDeviceData(String deviceId) {
    if (kDebugMode) {
      print('📊 Starting to listen to sensor data for device: $deviceId');
    }

    return _database.ref('sensorData/$deviceId/latest').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map<dynamic, dynamic>);
        
        if (kDebugMode) {
          print('📈 Received sensor data for $deviceId: $data');
        }
        
        return data;
      }
      return null;
    });
  }

  /// Send command to device
  Future<bool> sendCommandToDevice({
    required String deviceId,
    required String command,
    required dynamic value,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final commandPath = 'users/${user.uid}/devices/$deviceId/commands/$command';
      await _database.ref(commandPath).set(value);

      if (kDebugMode) {
        print('📤 Command sent to device $deviceId: $command = $value');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending command to device: $e');
      }
      return false;
    }
  }

  /// Remove device from user's collection
  Future<bool> removeDevice(String deviceId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Batch delete from both locations
      final batch = <String, dynamic>{};
      batch['users/${user.uid}/devices/$deviceId'] = null;
      batch['deviceRegistry/$deviceId'] = null;

      await _database.ref().update(batch);

      if (kDebugMode) {
        print('🗑️ Device $deviceId removed successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing device: $e');
      }
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopListening();
  }
}
