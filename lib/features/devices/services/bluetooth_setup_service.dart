import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Service for Bluetooth device discovery and setup
class BluetoothSetupService {
  static final BluetoothSetupService _instance = BluetoothSetupService._internal();
  factory BluetoothSetupService() => _instance;
  BluetoothSetupService._internal();

  static const String deviceNamePrefix = 'ESP32-BLK-AirMonitor';

  BluetoothConnection? _connection;

  /// Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      final isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (kDebugMode) {
        print('🔵 Bluetooth enabled: $isEnabled');
      }
      return isEnabled ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking Bluetooth availability: $e');
      }
      return false;
    }
  }

  /// Request to enable Bluetooth if not enabled
  Future<bool> requestBluetoothEnable() async {
    try {
      if (kDebugMode) {
        print('🔵 Requesting Bluetooth enable...');
      }

      final isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled == true) {
        if (kDebugMode) {
          print('✅ Bluetooth already enabled');
        }
        return true;
      }

      // Request to enable Bluetooth
      final enableResult = await FlutterBluetoothSerial.instance.requestEnable();

      if (kDebugMode) {
        print('📱 Bluetooth enable result: $enableResult');
      }

      return enableResult == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting Bluetooth enable: $e');
      }
      return false;
    }
  }

  /// Request necessary Bluetooth permissions
  Future<bool> requestBluetoothPermissions() async {
    try {
      if (kDebugMode) {
        print('🔵 Requesting Bluetooth permissions...');
      }

      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // Required for Bluetooth scanning on Android
      ];

      final statuses = await permissions.request();

      if (kDebugMode) {
        print('🔵 Permission request results:');
        for (final permission in permissions) {
          print('  📱 $permission: ${statuses[permission]}');
        }
      }

      // Check if all permissions are granted
      for (final permission in permissions) {
        final status = statuses[permission];
        if (status != PermissionStatus.granted) {
          if (kDebugMode) {
            print('❌ Bluetooth permission denied: $permission -> $status');
          }
          return false;
        }
      }

      if (kDebugMode) {
        print('✅ All Bluetooth permissions granted');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting Bluetooth permissions: $e');
      }
      return false;
    }
  }

  /// Scan for ESP32 Bluetooth devices
  Future<List<ESP32BluetoothDevice>> scanForDevices() async {
    try {
      if (kDebugMode) {
        print('🔵 Starting Bluetooth scan for ESP32 devices...');
      }

      // Check permissions first
      final hasPermissions = await requestBluetoothPermissions();
      if (!hasPermissions) {
        throw Exception('Bluetooth permissions not granted. Please enable Bluetooth permissions in Settings.');
      }

      // Request Bluetooth enable if not enabled
      final isEnabled = await requestBluetoothEnable();
      if (!isEnabled) {
        throw Exception('Bluetooth is not enabled. Please enable Bluetooth and try again.');
      }

      if (kDebugMode) {
        print('✅ Bluetooth permissions and enable checks passed');
      }

      final esp32Devices = <ESP32BluetoothDevice>[];

      // Get bonded devices first
      if (kDebugMode) {
        print('🔵 Checking bonded devices...');
      }
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();

      if (kDebugMode) {
        print('🔵 Found ${bondedDevices.length} bonded devices');
        for (final device in bondedDevices) {
          print('  📱 Bonded: ${device.name} (${device.address})');
        }
      }

      // Check bonded devices for ESP32
      for (final device in bondedDevices) {
        if (device.name?.contains(deviceNamePrefix) == true) {
          esp32Devices.add(ESP32BluetoothDevice(
            name: device.name ?? 'Unknown',
            address: device.address,
            rssi: -50, // Default RSSI for bonded devices
            isConnectable: true,
            bluetoothDevice: device,
          ));

          if (kDebugMode) {
            print('✅ Added bonded ESP32: ${device.name}');
          }
        }
      }

      // Start discovery for new devices
      if (kDebugMode) {
        print('🔵 Starting device discovery...');
      }

      final discoveryResults = FlutterBluetoothSerial.instance.startDiscovery();

      // Set up timeout for discovery
      final discoveryTimeout = Timer(const Duration(seconds: 15), () {
        if (kDebugMode) {
          print('🔵 Discovery timeout reached');
        }
      });

      try {
        await for (final result in discoveryResults) {
          if (kDebugMode) {
            print('🔍 Found device: "${result.device.name}" (${result.device.address}) RSSI: ${result.rssi}');
          }

          // Check if device name contains our prefix (case insensitive)
          final deviceName = result.device.name ?? '';
          if (deviceName.toLowerCase().contains(deviceNamePrefix.toLowerCase())) {
            // Check if not already in bonded list
            final isAlreadyAdded = esp32Devices.any((d) => d.address == result.device.address);
            if (!isAlreadyAdded) {
              esp32Devices.add(ESP32BluetoothDevice(
                name: deviceName,
                address: result.device.address,
                rssi: result.rssi,
                isConnectable: true,
                bluetoothDevice: result.device,
              ));

              if (kDebugMode) {
                print('✅ Added ESP32 device: $deviceName');
              }
            }
          }
        }
      } finally {
        discoveryTimeout.cancel();
      }

      if (kDebugMode) {
        print('🔵 Found ${esp32Devices.length} ESP32 Bluetooth devices');
        for (final device in esp32Devices) {
          print('  - ${device.name} (${device.address}) RSSI: ${device.rssi}');
        }
      }

      // Add mock device for testing if no real devices found
      if (esp32Devices.isEmpty) {
        if (kDebugMode) {
          print('🔵 No ESP32 devices found, adding mock device for testing');
        }
        esp32Devices.add(ESP32BluetoothDevice(
          name: 'ESP32-BLK-AirMonitor-TEST123',
          address: '00:11:22:33:44:55',
          rssi: -45,
          isConnectable: true,
        ));
      }

      return esp32Devices;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Bluetooth scan failed: $e');
      }
      rethrow;
    }
  }

  /// Connect to a Bluetooth device
  Future<bool> connectToDevice(ESP32BluetoothDevice device) async {
    try {
      if (kDebugMode) {
        print('🔵 Connecting to Bluetooth device: ${device.name}');
      }

      // Close existing connection if any
      await _connection?.close();

      // Connect to device
      _connection = await BluetoothConnection.toAddress(device.address);

      if (_connection?.isConnected == true) {
        if (kDebugMode) {
          print('✅ Connected to Bluetooth device: ${device.name}');
        }
        return true;
      } else {
        throw Exception('Failed to establish connection');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to connect to Bluetooth device: $e');
      }
      return false;
    }
  }

  /// Send command to ESP32 via Bluetooth
  Future<String?> sendCommand(String command) async {
    try {
      if (_connection?.isConnected != true) {
        throw Exception('Not connected to device');
      }

      if (kDebugMode) {
        print('🔵 Sending command: $command');
      }

      // Send command
      _connection!.output.add(utf8.encode('$command\n'));
      await _connection!.output.allSent;

      // Wait for response
      final completer = Completer<String>();
      final subscription = _connection!.input!.listen((Uint8List data) {
        final response = utf8.decode(data).trim();
        if (kDebugMode) {
          print('🔵 Received response: $response');
        }
        completer.complete(response);
      });

      // Timeout after 10 seconds
      final response = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          subscription.cancel();
          throw Exception('Command timeout');
        },
      );

      subscription.cancel();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send command: $e');
      }
      return null;
    }
  }

  /// Get device info via Bluetooth
  Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      final response = await sendCommand('GET_INFO');
      if (response != null) {
        return jsonDecode(response) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get device info: $e');
      }
      return null;
    }
  }

  /// Send WiFi configuration via Bluetooth
  Future<bool> configureWiFiViaBluetooth({
    required ESP32BluetoothDevice device,
    required String ssid,
    required String password,
    required String deviceId,
  }) async {
    try {
      if (kDebugMode) {
        print('🔵 Configuring WiFi via Bluetooth...');
        print('  Device: ${device.name}');
        print('  SSID: $ssid');
        print('  Device ID: $deviceId');
      }

      // Send WiFi configuration
      final wifiCommand = 'SET_WIFI:$ssid,$password';
      final response = await sendCommand(wifiCommand);

      if (response == 'WIFI_SAVED') {
        if (kDebugMode) {
          print('✅ WiFi credentials saved');
        }

        // Wait for connection attempt
        await Future.delayed(const Duration(seconds: 5));

        // Complete setup
        final setupResponse = await sendCommand('COMPLETE_SETUP');
        if (setupResponse == 'SETUP_COMPLETE') {
          if (kDebugMode) {
            print('✅ Setup completed successfully');
          }
          return true;
        } else {
          throw Exception('Setup completion failed: $setupResponse');
        }
      } else {
        throw Exception('WiFi configuration failed: $response');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to configure WiFi via Bluetooth: $e');
      }
      return false;
    }
  }

  /// Disconnect from Bluetooth device
  Future<void> disconnect(ESP32BluetoothDevice device) async {
    try {
      if (kDebugMode) {
        print('🔵 Disconnecting from Bluetooth device: ${device.name}');
      }

      await _connection?.close();
      _connection = null;

      if (kDebugMode) {
        print('✅ Disconnected from Bluetooth device');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disconnecting from Bluetooth device: $e');
      }
    }
  }

  /// Check if currently connected to a device
  bool get isConnected => _connection?.isConnected == true;
}

/// Bluetooth device model
class ESP32BluetoothDevice {
  final String name;
  final String address;
  final int rssi; // Signal strength
  final bool isConnectable;
  final BluetoothDevice? bluetoothDevice; // Flutter Bluetooth Serial device

  const ESP32BluetoothDevice({
    required this.name,
    required this.address,
    required this.rssi,
    required this.isConnectable,
    this.bluetoothDevice,
  });

  String get signalStrengthText {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Good';
    if (rssi >= -70) return 'Fair';
    return 'Weak';
  }

  String get deviceId {
    // Extract device ID from name (e.g., ESP32-AirMonitor-001 -> 001)
    final parts = name.split('-');
    return parts.length >= 3 ? parts.last : 'Unknown';
  }

  @override
  String toString() {
    return 'BluetoothDevice(name: $name, address: $address, rssi: $rssi)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BluetoothDevice && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}
