import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../../../shared/models/device_model.dart' as device_models;
import 'device_service.dart';

class DeviceSetupService {
  static final DeviceSetupService _instance = DeviceSetupService._internal();
  factory DeviceSetupService() => _instance;
  DeviceSetupService._internal();

  final NetworkInfo _networkInfo = NetworkInfo();
  final DeviceService _deviceService = DeviceService();

  static const String setupSSIDPrefix = 'ESP32-AirMonitor-Setup';
  static const String setupIPAddress = '192.168.4.1';
  static const int setupPort = 80;

  /// Check if device is connected to setup hotspot
  Future<bool> isConnectedToSetupHotspot() async {
    try {
      final ssid = await _networkInfo.getWifiName();
      return ssid?.contains(setupSSIDPrefix) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking WiFi connection: $e');
      }
      return false;
    }
  }

  /// Scan for available ESP32 setup hotspots
  Future<List<SetupDevice>> scanForSetupDevices() async {
    try {
      // Request permissions
      final canScan = await _requestWiFiPermissions();
      if (!canScan) {
        throw Exception('WiFi permissions not granted');
      }

      // Check if WiFi scanning is supported
      final canGetScannedResults = await WiFiScan.instance.canGetScannedResults();
      if (canGetScannedResults != CanGetScannedResults.yes) {
        throw Exception('WiFi scanning not supported on this device');
      }

      // Start WiFi scan
      await WiFiScan.instance.startScan();
      
      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 3));

      // Get scan results
      final results = await WiFiScan.instance.getScannedResults();
      
      // Filter for ESP32 setup devices
      final setupDevices = <SetupDevice>[];
      for (final result in results) {
        if (result.ssid.startsWith(setupSSIDPrefix)) {
          final deviceId = _extractDeviceIdFromSSID(result.ssid);
          setupDevices.add(SetupDevice(
            deviceId: deviceId,
            ssid: result.ssid,
            signalStrength: result.level,
            isSecured: result.capabilities.contains('WPA') || result.capabilities.contains('WEP'),
          ));
        }
      }

      if (kDebugMode) {
        print('Found ${setupDevices.length} setup devices');
      }

      return setupDevices;
    } catch (e) {
      if (kDebugMode) {
        print('Error scanning for setup devices: $e');
      }
      return [];
    }
  }

  /// Connect to ESP32 setup hotspot
  Future<bool> connectToSetupDevice(SetupDevice device) async {
    try {
      // Note: Automatic WiFi connection requires platform-specific implementation
      // For now, we'll guide the user to connect manually
      return await isConnectedToSetupHotspot();
    } catch (e) {
      if (kDebugMode) {
        print('Error connecting to setup device: $e');
      }
      return false;
    }
  }

  /// Get device information from setup interface
  Future<DeviceSetupInfo?> getDeviceSetupInfo() async {
    try {
      final response = await http.get(
        Uri.http(setupIPAddress, '/api/info'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return DeviceSetupInfo.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device setup info: $e');
      }
      return null;
    }
  }

  /// Send WiFi configuration to ESP32
  Future<bool> configureDeviceWiFi(DeviceWiFiConfig config) async {
    try {
      final response = await http.post(
        Uri.http(setupIPAddress, '/api/wifi'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config.toJson()),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error configuring device WiFi: $e');
      }
      return false;
    }
  }

  /// Send Firebase configuration to ESP32
  Future<bool> configureDeviceFirebase(DeviceFirebaseConfig config) async {
    try {
      final response = await http.post(
        Uri.http(setupIPAddress, '/api/firebase'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config.toJson()),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error configuring device Firebase: $e');
      }
      return false;
    }
  }

  /// Complete device setup
  Future<bool> completeDeviceSetup(CompleteSetupConfig config) async {
    try {
      final response = await http.post(
        Uri.http(setupIPAddress, '/api/complete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config.toJson()),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        // Add device to Firebase
        final device = device_models.DeviceModel(
          id: config.deviceId,
          name: config.deviceName,
          location: config.location,
          type: device_models.DeviceType.esp32,
          status: device_models.DeviceStatus.active,
          ownerId: config.ownerId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          configuration: device_models.DeviceConfiguration.defaultConfiguration(config.deviceId),
          capabilities: ['temperature', 'humidity', 'pm25', 'pm10', 'co2', 'voc'],
        );

        await _deviceService.addDevice(device);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error completing device setup: $e');
      }
      return false;
    }
  }

  /// Test connection to setup interface
  Future<bool> testSetupConnection() async {
    try {
      final response = await http.get(
        Uri.http(setupIPAddress, '/'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Request necessary permissions for WiFi operations
  Future<bool> _requestWiFiPermissions() async {
    try {
      final permissions = [
        Permission.location,
        Permission.nearbyWifiDevices,
      ];

      final statuses = await permissions.request();
      return statuses.values.every((status) => status.isGranted);
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting WiFi permissions: $e');
      }
      return false;
    }
  }

  /// Extract device ID from SSID
  String _extractDeviceIdFromSSID(String ssid) {
    // ESP32-AirMonitor-Setup-ABCD1234 -> ABCD1234
    final parts = ssid.split('-');
    return parts.length >= 4 ? parts.last : ssid;
  }
}

/// Setup Device Model
class SetupDevice {
  final String deviceId;
  final String ssid;
  final int signalStrength;
  final bool isSecured;

  const SetupDevice({
    required this.deviceId,
    required this.ssid,
    required this.signalStrength,
    required this.isSecured,
  });

  String get displayName => 'Air Monitor $deviceId';
  
  String get signalStrengthText {
    if (signalStrength > -50) return 'Excellent';
    if (signalStrength > -60) return 'Good';
    if (signalStrength > -70) return 'Fair';
    return 'Poor';
  }
}

/// Device Setup Info Model
class DeviceSetupInfo {
  final String deviceId;
  final String macAddress;
  final String firmwareVersion;
  final String hardwareVersion;
  final String chipModel;
  final List<String> capabilities;

  const DeviceSetupInfo({
    required this.deviceId,
    required this.macAddress,
    required this.firmwareVersion,
    required this.hardwareVersion,
    required this.chipModel,
    required this.capabilities,
  });

  factory DeviceSetupInfo.fromJson(Map<String, dynamic> json) {
    return DeviceSetupInfo(
      deviceId: json['deviceId'] as String,
      macAddress: json['macAddress'] as String,
      firmwareVersion: json['firmwareVersion'] as String,
      hardwareVersion: json['hardwareVersion'] as String,
      chipModel: json['chipModel'] as String,
      capabilities: List<String>.from(json['capabilities'] as List),
    );
  }
}

/// WiFi Configuration Model
class DeviceWiFiConfig {
  final String ssid;
  final String password;
  final String? staticIP;
  final String? gateway;
  final String? subnet;

  const DeviceWiFiConfig({
    required this.ssid,
    required this.password,
    this.staticIP,
    this.gateway,
    this.subnet,
  });

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'password': password,
      'staticIP': staticIP,
      'gateway': gateway,
      'subnet': subnet,
    };
  }
}

/// Firebase Configuration Model
class DeviceFirebaseConfig {
  final String projectId;
  final String databaseURL;
  final String apiKey;

  const DeviceFirebaseConfig({
    required this.projectId,
    required this.databaseURL,
    required this.apiKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'databaseURL': databaseURL,
      'apiKey': apiKey,
    };
  }
}

/// Complete Setup Configuration Model
class CompleteSetupConfig {
  final String deviceId;
  final String deviceName;
  final String location;
  final String ownerId;
  final Map<String, dynamic>? additionalSettings;

  const CompleteSetupConfig({
    required this.deviceId,
    required this.deviceName,
    required this.location,
    required this.ownerId,
    this.additionalSettings,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'location': location,
      'ownerId': ownerId,
      'additionalSettings': additionalSettings,
    };
  }
}
