import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../models/wifi_network_model.dart';

/// Service for scanning and managing WiFi networks
class WiFiScannerService {
  static final WiFiScannerService _instance = WiFiScannerService._internal();
  factory WiFiScannerService() => _instance;
  WiFiScannerService._internal();

  final StreamController<WiFiScanResult> _scanResultController = 
      StreamController<WiFiScanResult>.broadcast();

  /// Stream of WiFi scan results
  Stream<WiFiScanResult> get scanResultStream => _scanResultController.stream;

  /// Current scan result
  WiFiScanResult _currentResult = WiFiScanResult.idle();
  WiFiScanResult get currentResult => _currentResult;

  /// Check if WiFi scanning is supported
  Future<bool> isWiFiScanSupported() async {
    try {
      final canGetScannedResults = await WiFiScan.instance.canGetScannedResults();
      final canStartScan = await WiFiScan.instance.canStartScan();
      
      if (kDebugMode) {
        print('📡 WiFi scan support: canGetScannedResults=$canGetScannedResults, canStartScan=$canStartScan');
      }
      
      return canGetScannedResults == CanGetScannedResults.yes && 
             canStartScan == CanStartScan.yes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking WiFi scan support: $e');
      }
      return false;
    }
  }

  /// Request necessary permissions for WiFi scanning
  Future<bool> requestPermissions() async {
    try {
      if (kDebugMode) {
        print('🔐 Requesting WiFi scan permissions...');
      }

      // On Android, we need location permission for WiFi scanning
      if (Platform.isAndroid) {
        final locationStatus = await Permission.location.request();
        
        if (locationStatus != PermissionStatus.granted) {
          if (kDebugMode) {
            print('❌ Location permission denied');
          }
          return false;
        }

        // Also check for nearby WiFi devices permission (Android 13+)
        if (await Permission.nearbyWifiDevices.isDenied) {
          final nearbyWifiStatus = await Permission.nearbyWifiDevices.request();
          if (nearbyWifiStatus != PermissionStatus.granted) {
            if (kDebugMode) {
              print('⚠️ Nearby WiFi devices permission denied, but continuing...');
            }
          }
        }
      }

      // On iOS, we might need location permission as well
      if (Platform.isIOS) {
        final locationStatus = await Permission.location.request();
        if (locationStatus != PermissionStatus.granted) {
          if (kDebugMode) {
            print('❌ Location permission denied on iOS');
          }
          return false;
        }
      }

      if (kDebugMode) {
        print('✅ WiFi scan permissions granted');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting permissions: $e');
      }
      return false;
    }
  }

  /// Start WiFi network scan
  Future<void> startScan() async {
    try {
      if (kDebugMode) {
        print('📡 Starting WiFi scan...');
      }

      // Update state to scanning
      _updateScanResult(WiFiScanResult.scanning());

      // Check if WiFi scanning is supported
      if (!await isWiFiScanSupported()) {
        _updateScanResult(WiFiScanResult.notSupported());
        return;
      }

      // Request permissions
      if (!await requestPermissions()) {
        _updateScanResult(WiFiScanResult.permissionDenied());
        return;
      }

      // Start the scan
      final canStartScan = await WiFiScan.instance.canStartScan();
      if (canStartScan == CanStartScan.yes) {
        final startScanResult = await WiFiScan.instance.startScan();

        if (kDebugMode) {
          print('📡 WiFi scan started with result: $startScanResult');
        }

        // Wait a bit for scan to complete, then get results
        await Future.delayed(const Duration(seconds: 3));
        await getScannedResults();
      } else {
        throw Exception('Cannot start WiFi scan: $canStartScan');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ WiFi scan failed: $e');
      }
      _updateScanResult(WiFiScanResult.error(e.toString()));
    }
  }

  /// Get scanned WiFi networks
  Future<void> getScannedResults() async {
    try {
      if (kDebugMode) {
        print('📡 Getting WiFi scan results...');
      }

      final canGetResults = await WiFiScan.instance.canGetScannedResults();
      if (canGetResults != CanGetScannedResults.yes) {
        throw Exception('Cannot get scan results: $canGetResults');
      }

      final accessPoints = await WiFiScan.instance.getScannedResults();
      
      if (kDebugMode) {
        print('📡 Found ${accessPoints.length} WiFi networks');
      }

      // Convert to our model and filter/sort
      final networks = accessPoints
          .where((ap) => ap.ssid.isNotEmpty) // Filter out hidden networks
          .map((ap) => WiFiNetworkInfo.fromWiFiAccessPoint(ap))
          .toSet() // Remove duplicates
          .toList();

      // Sort by signal strength (strongest first)
      networks.sort((a, b) => b.signalStrength.compareTo(a.signalStrength));

      if (kDebugMode) {
        print('📡 Processed ${networks.length} unique networks');
        for (final network in networks.take(5)) {
          print('  - ${network.ssid} (${network.signalText}, ${network.securityType})');
        }
      }

      _updateScanResult(WiFiScanResult.completed(networks));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting scan results: $e');
      }
      _updateScanResult(WiFiScanResult.error(e.toString()));
    }
  }

  /// Refresh scan (start new scan)
  Future<void> refreshScan() async {
    await startScan();
  }

  // Mock methods removed - production only uses real WiFi scanning



  /// Update scan result and notify listeners
  void _updateScanResult(WiFiScanResult result) {
    _currentResult = result;
    _scanResultController.add(result);
  }

  /// Dispose resources
  void dispose() {
    _scanResultController.close();
  }
}
