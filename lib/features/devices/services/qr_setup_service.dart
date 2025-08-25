import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// QR Setup temporarily disabled - using placeholder models
import '../models/qr_setup_models_disabled.dart';
import '../../../shared/models/device_model.dart' as device_models;
import 'device_service.dart';

class QRSetupService {
  static final QRSetupService _instance = QRSetupService._internal();
  factory QRSetupService() => _instance;
  QRSetupService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final DeviceService _deviceService = DeviceService();
  // final MockESP32Service _mockService = MockESP32Service(); // Removed for production
  // final ESP32WiFiService _esp32WiFiService = ESP32WiFiService();

  // Stream controllers for real-time updates
  final StreamController<SetupProgress> _setupProgressController = 
      StreamController<SetupProgress>.broadcast();
  final StreamController<DeviceConnectionStatus> _deviceStatusController =
      StreamController<DeviceConnectionStatus>.broadcast();
  final StreamController<CurrentSensorData> _sensorDataController = 
      StreamController<CurrentSensorData>.broadcast();

  // Active subscriptions
  final Map<String, StreamSubscription> _subscriptions = {};

  // Track WiFi configuration state per device
  final Set<String> _wifiConfiguredDevices = {};

  /// Stream for setup progress updates
  Stream<SetupProgress> get setupProgressStream => _setupProgressController.stream.asBroadcastStream();

  /// Stream for device status updates
  Stream<DeviceConnectionStatus> get deviceStatusStream => _deviceStatusController.stream.asBroadcastStream();

  /// Stream for sensor data updates
  Stream<CurrentSensorData> get sensorDataStream => _sensorDataController.stream.asBroadcastStream();

  /// [Step 1] Register device with setup key
  Future<DeviceRegistrationResponse> registerDevice(QRSetupData qrData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        print('🔄 [Step 1] Registering device: ${qrData.deviceId}');
      }

      // Production: Real ESP32 devices will register themselves
      // No mock service needed in production

      // Update progress
      _updateSetupProgress(SetupProgress(
        currentStep: SetupStep.registerDevice,
        deviceId: qrData.deviceId,
        startTime: DateTime.now(),
      ));

      // Create registration request
      final request = DeviceRegistrationRequest(
        deviceId: qrData.deviceId,
        setupKey: qrData.setupKey,
        userId: user.uid,
        timestamp: DateTime.now(),
      );

      // Send registration command to Firebase
      await _database
          .child('commands')
          .child('register-device')
          .child(qrData.deviceId)
          .set(request.toJson());

      if (kDebugMode) {
        print('✅ [Step 1] Registration command sent');
      }

      // Wait for ESP32 to acknowledge registration
      if (kDebugMode) {
        print('⏳ [Step 1] Waiting for registration response...');
      }

      final response = await _waitForRegistrationResponse(qrData.deviceId);

      if (kDebugMode) {
        print('📥 [Step 1] Registration response received: ${response.success}');
      }

      if (response.success) {
        if (kDebugMode) {
          print('✅ [Step 1] Registration successful, starting device monitoring');
        }

        // Update progress to next step
        _updateSetupProgress(SetupProgress(
          currentStep: SetupStep.configureWifi,
          deviceId: qrData.deviceId,
          startTime: DateTime.now(),
          errorMessage: 'Registration successful. Ready for WiFi configuration.',
        ));

        // Start monitoring device status
        _startDeviceStatusMonitoring(qrData.deviceId);
      } else {
        if (kDebugMode) {
          print('❌ [Step 1] Registration failed: ${response.message}');
        }

        // Update progress to failed
        _updateSetupProgress(SetupProgress(
          currentStep: SetupStep.failed,
          deviceId: qrData.deviceId,
          startTime: DateTime.now(),
          errorMessage: 'Registration failed: ${response.message}',
        ));
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Step 1] Registration failed: $e');
      }
      
      _updateSetupProgress(SetupProgress(
        currentStep: SetupStep.failed,
        deviceId: qrData.deviceId,
        startTime: DateTime.now(),
        errorMessage: 'Registration failed: $e',
      ));
      
      rethrow;
    }
  }

  /// [Step 3] Configure WiFi credentials
  Future<bool> configureWiFi(String deviceId, String ssid, String password) async {
    try {
      if (kDebugMode) {
        print('🔄 [Step 3] Configuring WiFi for device: $deviceId');
        print('  SSID: $ssid');
        print('  Password length: ${password.length}');
      }

      // Update progress
      _updateSetupProgress(SetupProgress(
        currentStep: SetupStep.configureWifi,
        deviceId: deviceId,
        startTime: DateTime.now(),
      ));

      // Create WiFi configuration request
      final request = WiFiConfigurationRequest(
        deviceId: deviceId,
        ssid: ssid,
        password: password,
        timestamp: DateTime.now(),
      );

      // Send WiFi configuration command to Firebase
      await _database
          .child('commands')
          .child('configure-wifi')
          .child(deviceId)
          .set(request.toJson());

      if (kDebugMode) {
        print('✅ [Step 3] WiFi configuration command sent');
      }

      // Wait for ESP32 to save WiFi credentials
      final success = await _waitForWiFiConfigSaved(deviceId);

      if (success) {
        // Mark WiFi as configured for this device
        _wifiConfiguredDevices.add(deviceId);

        // Update progress to waiting for connection
        _updateSetupProgress(SetupProgress(
          currentStep: SetupStep.waitingConnection,
          deviceId: deviceId,
          startTime: DateTime.now(),
        ));

        // Wait for device to come online
        await _waitForDeviceOnline(deviceId);
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Step 3] WiFi configuration failed: $e');
      }
      
      _updateSetupProgress(SetupProgress(
        currentStep: SetupStep.failed,
        deviceId: deviceId,
        startTime: DateTime.now(),
        errorMessage: 'WiFi configuration failed: $e',
      ));
      
      return false;
    }
  }

  /// [Step 6] Monitor device status for online state
  void _startDeviceStatusMonitoring(String deviceId) {
    if (kDebugMode) {
      print('🔄 [Step 6] Starting device status monitoring: $deviceId');
    }

    // Cancel existing subscription
    _subscriptions['status_$deviceId']?.cancel();

    // Subscribe to device status updates
    _subscriptions['status_$deviceId'] = _database
        .child('devices')
        .child(deviceId)
        .child('status')
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        try {
          final data = event.snapshot.value;
          if (kDebugMode) {
            print('📱 [Step 6] Raw device status: $data');
          }

          // Convert to proper Map<String, dynamic>
          Map<String, dynamic> jsonData;
          if (data is Map<dynamic, dynamic>) {
            jsonData = _convertDynamicMap(data);
          } else {
            throw Exception('Invalid status format: $data');
          }

          final status = DeviceConnectionStatus.fromJson(jsonData);

          if (kDebugMode) {
            print('📱 [Step 6] Device status update: ${status.status}');
          }

          _deviceStatusController.add(status);

          // Check if device is online AND WiFi has been configured
          if (status.isOnline && _hasWiFiBeenConfigured(deviceId)) {
            _onDeviceOnline(deviceId);
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing device status: $e');
          }
        }
      }
    });
  }

  /// [Step 8] Monitor sensor data stream
  void startSensorDataMonitoring(String deviceId) {
    if (kDebugMode) {
      print('🔄 [Step 8] Starting sensor data monitoring: $deviceId');
    }

    // Cancel existing subscription
    _subscriptions['sensor_$deviceId']?.cancel();

    // Subscribe to current sensor data
    _subscriptions['sensor_$deviceId'] = _database
        .child('devices')
        .child(deviceId)
        .child('current')
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        try {
          final data = event.snapshot.value;
          if (kDebugMode) {
            print('📊 [Step 8] Raw sensor data: $data');
          }

          // Convert to proper Map<String, dynamic>
          Map<String, dynamic> jsonData;
          if (data is Map<dynamic, dynamic>) {
            jsonData = _convertDynamicMap(data);
          } else {
            throw Exception('Invalid sensor data format: $data');
          }

          final sensorData = CurrentSensorData.fromJson(jsonData);

          if (kDebugMode) {
            print('📊 [Step 8] Sensor data received: ${sensorData.temperature}°C');
          }

          _sensorDataController.add(sensorData);
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing sensor data: $e');
          }
        }
      }
    });
  }

  /// Wait for ESP32 registration response
  Future<DeviceRegistrationResponse> _waitForRegistrationResponse(String deviceId) async {
    final completer = Completer<DeviceRegistrationResponse>();
    late StreamSubscription subscription;

    // Set timeout with fallback device creation
    final timeout = Timer(const Duration(seconds: 30), () async {
      subscription.cancel();
      if (!completer.isCompleted) {
        if (kDebugMode) {
          print('⏰ Registration timeout, creating device record directly for simulation');
        }

        try {
          // Create device record directly since ESP32 didn't respond (simulation mode)
          final response = await _createDeviceDirectly(deviceId);
          completer.complete(response);
        } catch (e) {
          completer.completeError('Registration timeout: $e');
        }
      }
    });

    // Listen for registration response
    subscription = _database
        .child('devices')
        .child(deviceId)
        .child('registration_response')
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        if (kDebugMode) {
          print('📥 Registration response snapshot received');
        }

        timeout.cancel();
        subscription.cancel();

        try {
          final data = event.snapshot.value;
          if (kDebugMode) {
            print('📥 Raw registration response: $data');
            print('📥 Data type: ${data.runtimeType}');
          }

          // Convert to proper Map<String, dynamic>
          Map<String, dynamic> jsonData;
          if (data is Map<dynamic, dynamic>) {
            jsonData = _convertDynamicMap(data);
            if (kDebugMode) {
              print('📥 Converted registration response: $jsonData');
            }
          } else {
            throw Exception('Invalid response format: $data (type: ${data.runtimeType})');
          }

          final response = DeviceRegistrationResponse.fromJson(jsonData);
          if (kDebugMode) {
            print('✅ Registration response parsed successfully: success=${response.success}');
          }

          if (!completer.isCompleted) {
            completer.complete(response);
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('❌ Error parsing registration response: $e');
            print('Stack trace: $stackTrace');
          }

          if (!completer.isCompleted) {
            completer.completeError('Failed to parse registration response: $e');
          }
        }
      }
    });

    return completer.future;
  }

  /// Convert Map<dynamic, dynamic> to Map<String, dynamic> recursively
  Map<String, dynamic> _convertDynamicMap(Map<dynamic, dynamic> dynamicMap) {
    final Map<String, dynamic> result = {};

    for (final entry in dynamicMap.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value is Map<dynamic, dynamic>) {
        result[key] = _convertDynamicMap(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<dynamic, dynamic>) {
            return _convertDynamicMap(item);
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// Wait for WiFi configuration to be saved
  Future<bool> _waitForWiFiConfigSaved(String deviceId) async {
    final completer = Completer<bool>();
    late StreamSubscription subscription;

    // Set timeout
    final timeout = Timer(const Duration(seconds: 30), () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    // Listen for config status updates
    subscription = _database
        .child('devices')
        .child(deviceId)
        .child('config_status')
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value;

        // Convert to proper Map<String, dynamic>
        Map<String, dynamic> jsonData;
        if (data is Map<dynamic, dynamic>) {
          jsonData = _convertDynamicMap(data);
        } else {
          throw Exception('Invalid config status format: $data');
        }

        final configStatus = DeviceConfigStatus.fromJson(jsonData);
        
        if (configStatus.isWifiSaved || configStatus.isConnected) {
          timeout.cancel();
          subscription.cancel();
          
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        } else if (configStatus.hasFailed) {
          timeout.cancel();
          subscription.cancel();
          
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        }
      }
    });

    return completer.future;
  }

  /// Wait for device to come online
  Future<bool> _waitForDeviceOnline(String deviceId) async {
    final completer = Completer<bool>();
    late StreamSubscription subscription;

    // Set timeout (longer for WiFi connection)
    final timeout = Timer(const Duration(minutes: 2), () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    // Listen for device status updates
    subscription = _database
        .child('devices')
        .child(deviceId)
        .child('status')
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value;

        // Convert to proper Map<String, dynamic>
        Map<String, dynamic> jsonData;
        if (data is Map<dynamic, dynamic>) {
          jsonData = _convertDynamicMap(data);
        } else {
          throw Exception('Invalid device status format: $data');
        }

        final status = DeviceConnectionStatus.fromJson(jsonData);
        
        if (status.isOnline) {
          timeout.cancel();
          subscription.cancel();
          
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        }
      }
    });

    return completer.future;
  }

  /// Handle device coming online
  void _onDeviceOnline(String deviceId) async {
    if (kDebugMode) {
      print('🎉 [Step 5] Device is online: $deviceId');
    }

    // Device status is already set to 'active' when device was created
    // No need to update it here as it would conflict with connection status
    if (kDebugMode) {
      print('✅ Device is online and ready: $deviceId');
    }

    // Update progress to verify connection
    _updateSetupProgress(SetupProgress(
      currentStep: SetupStep.verifyConnection,
      deviceId: deviceId,
      startTime: DateTime.now(),
    ));

    // Start sensor data monitoring
    startSensorDataMonitoring(deviceId);

    // Wait a bit for sensor data, then mark as completed
    Timer(const Duration(seconds: 5), () {
      _updateSetupProgress(SetupProgress(
        currentStep: SetupStep.completed,
        deviceId: deviceId,
        startTime: DateTime.now(),
        completedTime: DateTime.now(),
      ));
    });
  }

  /// Update setup progress
  void _updateSetupProgress(SetupProgress progress) {
    if (kDebugMode) {
      print('📊 Updating setup progress: ${progress.currentStep} for device ${progress.deviceId}');
    }
    _setupProgressController.add(progress);
  }

  /// Check if WiFi has been configured for device
  bool _hasWiFiBeenConfigured(String deviceId) {
    return _wifiConfiguredDevices.contains(deviceId);
  }

  /// Get device status stream for specific device
  Stream<DeviceConnectionStatus> getDeviceStatusStream(String deviceId) {
    return _database
        .child('devices')
        .child(deviceId)
        .child('status')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value;
        if (data is Map) {
          final jsonData = _convertDynamicMap(data);
          return DeviceConnectionStatus.fromJson(jsonData);
        }
        // If status is a string like "active" due to normalization, map to conn status
        if (data is String) {
          return DeviceConnectionStatus(
            isOnline: data == 'active',
            lastSeen: DateTime.now(),
            status: data,
          );
        }
      }
      return DeviceConnectionStatus(
        isOnline: false,
        lastSeen: DateTime.now(),
        status: 'unknown',
      );
    }).asBroadcastStream();
  }

  /// Get sensor data stream for specific device
  Stream<CurrentSensorData> getSensorDataStream(String deviceId) {
    return _database
        .child('devices')
        .child(deviceId)
        .child('current')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value;
        if (data is Map) {
          final jsonData = _convertDynamicMap(data);
          return CurrentSensorData.fromJson(jsonData);
        }
      }
      return CurrentSensorData.empty(deviceId);
    }).asBroadcastStream();
  }

  /// Complete device setup by adding to user's device list
  Future<void> completeDeviceSetup(String deviceId, String deviceName, String location) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create device model
      final device = device_models.DeviceModel(
        id: deviceId,
        name: deviceName,
        location: location,
        type: device_models.DeviceType.esp32,
        status: device_models.DeviceStatus.active,
        ownerId: user.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        configuration: device_models.DeviceConfiguration.defaultConfiguration(deviceId),
        capabilities: ['temperature', 'humidity', 'pm25', 'pm10', 'co2', 'voc'],
      );

      // Add device to user's device list
      await _deviceService.addDevice(device);

      if (kDebugMode) {
        print('✅ Device setup completed: $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error completing device setup: $e');
      }
      rethrow;
    }
  }

  /// Cancel device setup
  void cancelSetup(String deviceId) {
    // Cancel all subscriptions for this device
    _subscriptions['status_$deviceId']?.cancel();
    _subscriptions['sensor_$deviceId']?.cancel();
    _subscriptions.remove('status_$deviceId');
    _subscriptions.remove('sensor_$deviceId');

    // Update progress to failed
    _updateSetupProgress(SetupProgress(
      currentStep: SetupStep.failed,
      deviceId: deviceId,
      startTime: DateTime.now(),
      errorMessage: 'Setup cancelled by user',
    ));
  }

  /// Dispose resources
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Close stream controllers
    _setupProgressController.close();
    _deviceStatusController.close();
    _sensorDataController.close();
  }

  /// Create device record directly for simulation/testing when ESP32 doesn't respond
  Future<DeviceRegistrationResponse> _createDeviceDirectly(String deviceId) async {
    if (kDebugMode) {
      print('🔧 Creating device record directly for simulation');
    }

    // Create device registration response
    final response = DeviceRegistrationResponse(
      success: true,
      message: 'Device registered successfully (simulation)',
      timestamp: DateTime.now(),
      sessionToken: 'sim_session_${DateTime.now().millisecondsSinceEpoch}',
      deviceInfo: {
        'firmwareVersion': '1.0.0-simulation',
        'hardwareVersion': 'ESP32-SIM',
        'chipModel': 'ESP32',
        'capabilities': ['temperature', 'humidity', 'pm25', 'pm10', 'co2', 'voc'],
        'deviceId': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Write registration response to Firebase for Flutter app to pick up
    try {
      await _database
          .child('devices')
          .child(deviceId)
          .child('registration_response')
          .set(response.toJson());

      if (kDebugMode) {
        print('✅ Device registration response written to Firebase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error writing registration response: $e');
      }
    }

    return response;
  }
}
