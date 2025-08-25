import 'dart:async';
import 'dart:convert';
// import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

/// Service for connecting to ESP32 in AP mode and configuring WiFi
class ESP32WiFiService {
  static final ESP32WiFiService _instance = ESP32WiFiService._internal();
  factory ESP32WiFiService() => _instance;
  ESP32WiFiService._internal();

  final NetworkInfo _networkInfo = NetworkInfo();
  
  // ESP32 AP mode configuration
  static const String esp32APPrefix = 'ESP32_Setup_';
  static const String esp32APPassword = 'setup123';
  static const String esp32SetupIP = '192.168.4.1';
  static const int esp32SetupPort = 80;

  /// Check if currently connected to ESP32 AP
  Future<bool> isConnectedToESP32AP() async {
    try {
      final wifiName = await _networkInfo.getWifiName();
      if (kDebugMode) {
        print('📶 Current WiFi: $wifiName');
      }
      
      // Remove quotes if present
      final cleanWifiName = wifiName?.replaceAll('"', '') ?? '';
      return cleanWifiName.startsWith(esp32APPrefix);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking WiFi connection: $e');
      }
      return false;
    }
  }

  /// Get ESP32 device info
  Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      if (kDebugMode) {
        print('📡 Getting ESP32 device info...');
      }

      final response = await http.get(
        Uri.http('$esp32SetupIP:$esp32SetupPort', '/api/info'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (kDebugMode) {
          print('✅ ESP32 device info received: $data');
        }
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting device info: $e');
      }
      return null;
    }
  }

  /// Scan WiFi networks from ESP32
  Future<List<Map<String, dynamic>>> scanWiFiNetworks() async {
    try {
      if (kDebugMode) {
        print('📡 Scanning WiFi networks from ESP32...');
      }

      final response = await http.get(
        Uri.http('$esp32SetupIP:$esp32SetupPort', '/api/wifi/scan'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final networks = (data['networks'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        
        if (kDebugMode) {
          print('✅ Found ${networks.length} WiFi networks');
        }
        
        return networks;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scanning WiFi networks: $e');
      }
      return [];
    }
  }

  /// Configure WiFi credentials on ESP32
  Future<bool> configureWiFi({
    required String ssid,
    required String password,
    required String deviceId,
    required String firebaseUrl,
    required String firebaseAuth,
  }) async {
    try {
      if (kDebugMode) {
        print('📡 Configuring WiFi on ESP32...');
        print('  SSID: $ssid');
        print('  Device ID: $deviceId');
      }

      final config = {
        'ssid': ssid,
        'password': password,
        'deviceId': deviceId,
        'firebase': {
          'url': firebaseUrl,
          'auth': firebaseAuth,
        },
      };

      final response = await http.post(
        Uri.http('$esp32SetupIP:$esp32SetupPort', '/api/wifi/configure'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        final success = result['success'] as bool? ?? false;
        
        if (kDebugMode) {
          print(success ? '✅ WiFi configured successfully' : '❌ WiFi configuration failed');
          print('Response: $result');
        }
        
        return success;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error configuring WiFi: $e');
      }
      return false;
    }
  }

  /// Check ESP32 connection status
  Future<Map<String, dynamic>?> getConnectionStatus() async {
    try {
      final response = await http.get(
        Uri.http('$esp32SetupIP:$esp32SetupPort', '/api/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting connection status: $e');
      }
      return null;
    }
  }

  /// Wait for ESP32 to connect to WiFi
  Future<bool> waitForWiFiConnection({
    Duration timeout = const Duration(minutes: 2),
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    if (kDebugMode) {
      print('⏳ Waiting for ESP32 to connect to WiFi...');
    }

    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      try {
        final status = await getConnectionStatus();
        if (status != null) {
          final wifiStatus = status['wifi'] as Map<String, dynamic>?;
          final isConnected = wifiStatus?['connected'] as bool? ?? false;
          
          if (isConnected) {
            if (kDebugMode) {
              print('✅ ESP32 connected to WiFi: ${wifiStatus?['ssid']}');
              print('IP Address: ${wifiStatus?['ip']}');
            }
            return true;
          }
          
          if (kDebugMode) {
            print('⏳ ESP32 still connecting... Status: ${wifiStatus?['status']}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⏳ Polling connection status... ($e)');
        }
      }
      
      await Future.delayed(pollInterval);
    }
    
    if (kDebugMode) {
      print('❌ Timeout waiting for ESP32 WiFi connection');
    }
    return false;
  }

  /// Restart ESP32 to exit AP mode
  Future<bool> restartESP32() async {
    try {
      if (kDebugMode) {
        print('🔄 Restarting ESP32...');
      }

      final response = await http.post(
        Uri.http('$esp32SetupIP:$esp32SetupPort', '/api/restart'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ ESP32 restart command sent');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error restarting ESP32: $e');
      }
      return false;
    }
  }

  /// Get instructions for connecting to ESP32 AP
  String getConnectionInstructions(String deviceId) {
    return '''
To configure your ESP32 device:

1. Put your ESP32 device in setup mode (usually by holding a button during power-on)

2. Connect your phone to the ESP32's WiFi network:
   • Network name: ${esp32APPrefix}$deviceId
   • Password: $esp32APPassword

3. Return to this app to continue setup

The ESP32 will create a temporary WiFi network for configuration. After setup is complete, it will connect to your home WiFi network.
''';
  }

  /// Check if device is reachable
  Future<bool> isESP32Reachable() async {
    try {
      final response = await http.get(
        Uri.http('$esp32SetupIP:$esp32SetupPort', '/api/ping'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
