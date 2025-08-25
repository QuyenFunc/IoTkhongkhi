import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import '../models/wifi_setup_models.dart';

/// Service for managing WiFi-based ESP32 device setup
/// Implements IP camera-style onboarding flow
class WiFiSetupService {
  static const String esp32HotspotPrefix = 'ESP32-Setup-';
  static const String esp32ConfigIP = '192.168.4.1';
  static const Duration scanTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 45);

  final NetworkInfo _networkInfo = NetworkInfo();
  String? _originalWiFiSSID;
  Timer? _statusCheckTimer;

  /// ESP32 device information from hotspot
  ESP32DeviceInfo? currentDevice;

  /// Request necessary WiFi permissions
  Future<bool> requestWiFiPermissions() async {
    try {
      if (kDebugMode) {
        print('🔵 Requesting WiFi permissions...');
      }

      final permissions = [
        Permission.location,
        Permission.nearbyWifiDevices,
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
            print('❌ WiFi permission denied: $permission -> $status');
          }
          return false;
        }
      }

      if (kDebugMode) {
        print('✅ All WiFi permissions granted');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting WiFi permissions: $e');
      }
      return false;
    }
  }

  /// Check if WiFi is enabled
  Future<bool> isWiFiEnabled() async {
    try {
      final canScan = await WiFiScan.instance.canStartScan();
      if (kDebugMode) {
        print('🔵 WiFi scan capability: $canScan');
      }
      return canScan == CanStartScan.yes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking WiFi status: $e');
      }
      return false;
    }
  }

  /// Scan for ESP32 setup hotspots
  Future<List<ESP32Hotspot>> scanForESP32Hotspots() async {
    try {
      if (kDebugMode) {
        print('🔵 Starting WiFi scan for ESP32 hotspots...');
      }

      // Check permissions first
      final hasPermissions = await requestWiFiPermissions();
      if (!hasPermissions) {
        throw Exception('WiFi permissions not granted. Please enable location and WiFi permissions.');
      }

      // Check if WiFi is enabled
      final isEnabled = await isWiFiEnabled();
      if (!isEnabled) {
        throw Exception('WiFi is not enabled. Please enable WiFi and try again.');
      }

      // Store current WiFi for later restoration
      _originalWiFiSSID = await _networkInfo.getWifiName();
      if (kDebugMode) {
        print('🔵 Current WiFi: $_originalWiFiSSID');
      }

      // Start WiFi scan
      final canStartScan = await WiFiScan.instance.canStartScan();
      if (canStartScan != CanStartScan.yes) {
        throw Exception('Cannot start WiFi scan: $canStartScan');
      }

      final startScanResult = await WiFiScan.instance.startScan();
      if (!startScanResult) {
        throw Exception('Failed to start WiFi scan');
      }

      if (kDebugMode) {
        print('🔵 WiFi scan started, waiting for results...');
      }

      // Wait for scan results with timeout
      List<WiFiAccessPoint> accessPoints = [];
      final completer = Completer<List<WiFiAccessPoint>>();
      Timer? timeoutTimer;

      final subscription = WiFiScan.instance.onScannedResultsAvailable.listen((results) {
        if (!completer.isCompleted) {
          timeoutTimer?.cancel();
          completer.complete(results);
        }
      });

      timeoutTimer = Timer(scanTimeout, () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.completeError('WiFi scan timeout');
        }
      });

      try {
        accessPoints = await completer.future;
      } finally {
        subscription.cancel();
        timeoutTimer?.cancel();
      }

      if (kDebugMode) {
        print('🔵 Found ${accessPoints.length} WiFi networks');
        for (final ap in accessPoints) {
          print('  📶 "${ap.ssid}" (${ap.level}dBm) - BSSID: ${ap.bssid}');
          if (ap.ssid.startsWith(esp32HotspotPrefix)) {
            print('    ✅ This is an ESP32 hotspot!');
          }
        }
      }

      // Filter ESP32 hotspots
      final esp32Hotspots = <ESP32Hotspot>[];
      for (final ap in accessPoints) {
        if (ap.ssid.startsWith(esp32HotspotPrefix)) {
          esp32Hotspots.add(ESP32Hotspot(
            ssid: ap.ssid,
            bssid: ap.bssid,
            level: ap.level,
            frequency: ap.frequency,
            capabilities: ap.capabilities,
            timestamp: ap.timestamp ?? DateTime.now().millisecondsSinceEpoch,
          ));

          if (kDebugMode) {
            print('✅ Found ESP32 hotspot: ${ap.ssid}');
          }
        }
      }

      if (kDebugMode) {
        print('🔵 Found ${esp32Hotspots.length} ESP32 hotspots');
      }

      // Add mock hotspot for testing if none found
      if (esp32Hotspots.isEmpty && kDebugMode) {
        esp32Hotspots.add(ESP32Hotspot(
          ssid: 'ESP32-Setup-TEST123',
          bssid: '00:11:22:33:44:55',
          level: -45,
          frequency: 2412,
          capabilities: '[WPA2-PSK-CCMP][ESS]',
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
        if (kDebugMode) {
          print('🔵 Added mock ESP32 hotspot for testing');
        }
      }

      return esp32Hotspots;
    } catch (e) {
      if (kDebugMode) {
        print('❌ WiFi scan error: $e');
      }
      rethrow;
    }
  }

  /// Connect to ESP32 hotspot
  Future<bool> connectToESP32Hotspot(ESP32Hotspot hotspot) async {
    try {
      if (kDebugMode) {
        print('🔵 Connecting to ESP32 hotspot: ${hotspot.ssid}');
      }

      // Note: Automatic WiFi connection requires platform-specific implementation
      // For now, we'll guide the user to connect manually
      if (kDebugMode) {
        print('🔵 Manual connection required for: ${hotspot.ssid}');
        print('🔵 Default password: 12345678');
      }

      // Wait for connection and verify
      return await _waitForESP32Connection();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to connect to ESP32 hotspot: $e');
      }
      return false;
    }
  }

  /// Wait for connection to ESP32 and verify
  Future<bool> _waitForESP32Connection() async {
    if (kDebugMode) {
      print('🔵 Waiting for ESP32 connection...');
    }

    for (int i = 0; i < 30; i++) {
      try {
        final currentSSID = await _networkInfo.getWifiName();
        if (currentSSID != null && currentSSID.startsWith(esp32HotspotPrefix)) {
          if (kDebugMode) {
            print('✅ Connected to ESP32 hotspot: $currentSSID');
          }

          // Test connection to ESP32
          final deviceInfo = await getESP32DeviceInfo();
          if (deviceInfo != null) {
            currentDevice = deviceInfo;
            return true;
          }
        }
      } catch (e) {
        // Continue waiting
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    if (kDebugMode) {
      print('❌ Timeout waiting for ESP32 connection');
    }
    return false;
  }

  /// Get device information from ESP32
  Future<ESP32DeviceInfo?> getESP32DeviceInfo() async {
    try {
      if (kDebugMode) {
        print('🔵 Getting ESP32 device info...');
      }

      final response = await http.get(
        Uri.parse('http://$esp32ConfigIP/api/info'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final deviceInfo = ESP32DeviceInfo.fromJson(data);

        if (kDebugMode) {
          print('✅ Got ESP32 device info: ${deviceInfo.deviceName}');
        }

        return deviceInfo;
      } else {
        if (kDebugMode) {
          print('❌ Failed to get device info: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting ESP32 device info: $e');
      }
      return null;
    }
  }

  /// Get available WiFi networks from ESP32
  Future<List<WiFiNetwork>> getAvailableNetworks() async {
    try {
      if (kDebugMode) {
        print('🔵 Getting available networks from ESP32...');
      }

      final response = await http.get(
        Uri.parse('http://$esp32ConfigIP/api/scan'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final networks = (data['networks'] as List)
            .map((network) => WiFiNetwork.fromJson(network))
            .toList();

        if (kDebugMode) {
          print('✅ Got ${networks.length} networks from ESP32');
        }

        return networks;
      } else {
        throw Exception('Failed to get networks: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting available networks: $e');
      }
      rethrow;
    }
  }

  /// Configure ESP32 WiFi credentials
  Future<bool> configureESP32WiFi(String ssid, String password) async {
    try {
      if (kDebugMode) {
        print('🔵 Configuring ESP32 WiFi: $ssid');
      }

      final response = await http.post(
        Uri.parse('http://$esp32ConfigIP/api/configure'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ssid': ssid,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ ESP32 WiFi configuration sent successfully');
        }

        // Start monitoring connection status
        return await _monitorESP32Connection();
      } else {
        final error = json.decode(response.body)['error'] ?? 'Unknown error';
        throw Exception('Configuration failed: $error');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error configuring ESP32 WiFi: $e');
      }
      rethrow;
    }
  }

  /// Monitor ESP32 connection status
  Future<bool> _monitorESP32Connection() async {
    if (kDebugMode) {
      print('🔵 Monitoring ESP32 connection status...');
    }

    final completer = Completer<bool>();
    int attempts = 0;
    const maxAttempts = 45; // 45 seconds timeout

    _statusCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      attempts++;

      try {
        final response = await http.get(
          Uri.parse('http://$esp32ConfigIP/api/status'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final state = data['state'];

          if (kDebugMode) {
            print('🔵 ESP32 status: $state (attempt $attempts/$maxAttempts)');
          }

          if (state == 'connected') {
            timer.cancel();
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          } else if (state == 'error') {
            timer.cancel();
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          }
        }
      } catch (e) {
        // ESP32 might be switching networks, continue monitoring
        if (kDebugMode && attempts % 5 == 0) {
          print('🔵 Status check failed (attempt $attempts): $e');
        }
      }

      if (attempts >= maxAttempts) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
    });

    return completer.future;
  }

  /// Restore original WiFi connection
  Future<void> restoreOriginalWiFi() async {
    try {
      _statusCheckTimer?.cancel();

      if (_originalWiFiSSID != null) {
        if (kDebugMode) {
          print('🔵 Restoring original WiFi connection: $_originalWiFiSSID');
        }
        // Note: Automatic WiFi switching requires platform-specific implementation
        // For now, user needs to manually reconnect
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error restoring WiFi: $e');
      }
    }
  }

  /// Cleanup resources
  void dispose() {
    _statusCheckTimer?.cancel();
  }
}
