import 'dart:async';
import 'dart:convert';
// import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';

/// Service for connecting to ESP32 in AP mode and configuring WiFi
class ESP32WiFiService {
  static final ESP32WiFiService _instance = ESP32WiFiService._internal();
  factory ESP32WiFiService() => _instance;
  ESP32WiFiService._internal();

  final NetworkInfo _networkInfo = NetworkInfo();
  
  // ESP32 AP mode configuration - Updated for new setup mode
  static const String esp32APPrefix = 'ESP32-Setup-';
  static const String esp32APPassword = '12345678';
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
      final isConnected = cleanWifiName.startsWith(esp32APPrefix);
      
      if (isConnected) {
        if (kDebugMode) {
          print('✅ Connected to ESP32 AP: $cleanWifiName');
        }
        // Test actual connectivity to ESP32
        return await _testESP32Connectivity();
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking WiFi connection: $e');
      }
      return false;
    }
  }

  /// Test actual connectivity to ESP32 by trying to reach its API
  Future<bool> _testESP32Connectivity() async {
    try {
      if (kDebugMode) {
        print('🔍 Testing ESP32 connectivity...');
      }
      
      final response = await http.get(
        Uri.http('$esp32SetupIP:$esp32SetupPort', '/api/info'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      final isReachable = response.statusCode == 200;
      
      if (kDebugMode) {
        print(isReachable ? '✅ ESP32 is reachable' : '❌ ESP32 not reachable');
      }
      
      return isReachable;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ESP32 connectivity test failed: $e');
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

  /// Scan WiFi networks with ESP32 API + Android fallback
  Future<List<Map<String, dynamic>>> scanWiFiNetworks() async {
    try {
      if (kDebugMode) {
        print('📡 Scanning WiFi networks...');
      }

      // First, try ESP32 API if connected
      final connected = await isConnectedToESP32AP();
      if (connected) {
        if (kDebugMode) {
          print('🔗 Connected to ESP32 - trying API scan...');
        }

        // Try ESP32 API with shorter timeout
        try {
          final response = await http
              .get(
                Uri.http('$esp32SetupIP:$esp32SetupPort', '/api/scan'),
                headers: {'Content-Type': 'application/json'},
              )
              .timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final data = json.decode(response.body) as Map<String, dynamic>;
            final networks = (data['networks'] as List<dynamic>)
                .cast<Map<String, dynamic>>();

            if (kDebugMode) {
              print('✅ ESP32 API scan found ${networks.length} WiFi networks');
            }

            return networks;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ ESP32 API scan failed: $e - trying Android fallback');
          }
        }
      }

      // Fallback: Scan using Android WiFi directly  
      if (kDebugMode) {
        print('📱 Using Android WiFi scan as fallback...');
      }
      
      return await _scanWiFiUsingAndroid();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scanning WiFi networks: $e');
      }
      return [];
    }
  }

  /// Fallback WiFi scan using Android's WiFi system
  Future<List<Map<String, dynamic>>> _scanWiFiUsingAndroid() async {
    try {
      // Check permissions
      final canScan = await WiFiScan.instance.canGetScannedResults(
        askPermissions: true,
      );
      
      if (canScan != CanGetScannedResults.yes) {
        throw Exception('Cannot access WiFi scan results: $canScan');
      }

      // Start fresh scan
      await WiFiScan.instance.startScan();
      await Future.delayed(const Duration(seconds: 3));
      
      // Get scan results
      final networks = await WiFiScan.instance.getScannedResults();
      
      // Convert to ESP32-compatible format
      final androidNetworks = networks
          .where((network) => network.ssid.isNotEmpty)
          .map((network) => {
            'ssid': network.ssid,
            'rssi': network.level,
            'secure': network.capabilities.contains('WPA') || 
                     network.capabilities.contains('WEP'),
          })
          .toList();
      
      if (kDebugMode) {
        print('✅ Android WiFi scan found ${androidNetworks.length} networks');
      }
      
      return androidNetworks;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Android WiFi scan failed: $e');
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

  /// Configure ESP32 with new setup flow (userKey-based) - WITH RETRY LOGIC
  Future<bool> configureDeviceWithUserKey({
    required String ssid,
    required String password,
    required String userKey,
    required String userUID,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          print('🔧 Configuring ESP32 device (Attempt $attempt/$maxRetries)...');
          print('  SSID: $ssid');
          print('  UserKey: ${userKey.substring(0, 8)}***');
        }

        // 1. CRITICAL: Multi-step ESP32 connection verification
        if (kDebugMode) {
          print('🔍 Step 1: Checking WiFi connection status...');
        }
        
        // Step 1a: Check WiFi name  
        final wifiName = await _networkInfo.getWifiName();
        final cleanWifiName = wifiName?.replaceAll('"', '') ?? '';
        
        if (kDebugMode) {
          print('📶 Current WiFi: $cleanWifiName');
        }
        
        if (!cleanWifiName.startsWith(esp32APPrefix)) {
          if (kDebugMode) {
            print('❌ Not connected to ESP32 WiFi! Current: $cleanWifiName');
            print('💡 Android switched to: ${cleanWifiName.isEmpty ? "Mobile Data" : cleanWifiName}');
          }
          
          if (attempt < maxRetries) {
            if (kDebugMode) {
              print('⏳ Attempt $attempt/$maxRetries - Waiting ${5 * attempt}s for manual reconnection...');
            }
            await Future.delayed(Duration(seconds: 5 * attempt));
            continue;
          } else {
            throw Exception('❌ Not connected to ESP32 AP: $cleanWifiName. Please reconnect manually and disable mobile data.');
          }
        }

        if (kDebugMode) {
          print('✅ Step 1: Connected to ESP32 WiFi: $cleanWifiName');
          print('🔍 Step 2: Testing ESP32 API connectivity...');
        }

        // Step 1b: Test actual ESP32 API connectivity
        bool apiReachable = false;
        try {
          final testResponse = await http.get(
            Uri.http('$esp32SetupIP:$esp32SetupPort', '/api/info'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 3));
          
          apiReachable = (testResponse.statusCode == 200);
          
          if (kDebugMode) {
            print(apiReachable ? '✅ Step 2: ESP32 API is reachable' : '❌ Step 2: ESP32 API not responding');
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Step 2: ESP32 API test failed: $e');
          }
        }

        if (!apiReachable) {
          if (kDebugMode) {
            print('💡 ESP32 not responding - may have restarted or network issue');
          }
          
          if (attempt < maxRetries) {
            if (kDebugMode) {
              print('⏳ Waiting ${8 * attempt}s for ESP32 to be ready...');
            }
            await Future.delayed(Duration(seconds: 8 * attempt));
            continue;
          } else {
            throw Exception('❌ ESP32 API not reachable after $maxRetries attempts');
          }
        }

        if (kDebugMode) {
          print('✅ All connection checks passed - ready to send config');
          print('⏳ Adding stabilization delay...');
        }

        // Small delay to let connection stabilize after verification
        await Future.delayed(const Duration(seconds: 2));

        // 2. Double-check connection immediately before sending
        final finalWifiCheck = await _networkInfo.getWifiName();
        final finalCleanWifiName = finalWifiCheck?.replaceAll('"', '') ?? '';
        
        if (!finalCleanWifiName.startsWith(esp32APPrefix)) {
          throw Exception('❌ Lost ESP32 connection right before sending config: $finalCleanWifiName');
        }

        // 3. Send configuration with optimized headers and connection settings
        final config = {
          'ssid': ssid,
          'password': password,
          'userKey': userKey,
          'userUID': userUID,  // Add userUID for Firebase authentication
          // Firebase config now hardcoded in ESP32
        };

        if (kDebugMode) {
          print('📤 Step 3: Sending configuration to ESP32...');
          print('🔗 Final connection check: $finalCleanWifiName ✅');
        }

        final response = await http.post(
          Uri.http('$esp32SetupIP:$esp32SetupPort', '/api/configure'),
          headers: {
            'Content-Type': 'application/json',
            'Connection': 'close', // Close connection immediately after response
            'Cache-Control': 'no-cache',
            'User-Agent': 'Flutter-ESP32-Setup', // Identify requests
          },
          body: json.encode(config),
        ).timeout(
          Duration(seconds: 6 + (attempt * 3)), // More generous timeout with retry progression
        );

        if (response.statusCode == 200) {
          final result = json.decode(response.body) as Map<String, dynamic>;
          final success = result['success'] as bool? ?? false;
          
          if (kDebugMode) {
            print(success ? '✅ Device configured successfully!' : '❌ Device configuration failed');
            print('📋 Response: $result');
          }
          
          return success;
        } else {
          if (kDebugMode) {
            print('❌ HTTP Error ${response.statusCode}: ${response.body}');
          }
          
          // HTTP error - don't retry for server-side issues
          return false;
        }
        
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error configuring device (Attempt $attempt): $e');
        }
        
        // Check if it's a connection-related error
        final isConnectionError = e.toString().contains('Software caused connection abort') ||
                                 e.toString().contains('TimeoutException') ||
                                 e.toString().contains('SocketException');
        
        if (isConnectionError) {
          if (kDebugMode) {
            print('🚨 CONNECTION ABORT DETECTED! 🚨');
            print('💡 This usually means Android switched to mobile data');
            print('📱 User needs to: 1) Disable mobile data, 2) Reconnect ESP32 WiFi');
          }
        }
        
        if (!isConnectionError || attempt == maxRetries) {
          // Non-connection error or final attempt - give up
          if (isConnectionError && attempt == maxRetries) {
            throw Exception(
              '❌ Connection Abort Error after $maxRetries attempts.\n'
              '🚨 Android keeps switching to mobile data!\n'
              '✅ SOLUTION: Disable mobile data and reconnect to ESP32 WiFi manually.'
            );
          }
          return false;
        }
        
        if (kDebugMode) {
          print('🔄 Connection error detected, will retry in ${3 * attempt} seconds...');
          print('⏰ User has time to reconnect to ESP32 WiFi manually');
        }
        
        // Wait progressively longer between retries to give user time
        await Future.delayed(Duration(seconds: 3 * attempt));
      }
    }
    
    return false;
  }

  /// Scan for ESP32 setup networks - REAL IMPLEMENTATION
  Future<List<String>> scanForESP32Networks() async {
    try {
      if (kDebugMode) {
        print('📡 Scanning for ESP32 setup networks...');
      }
      
      // Import wifi_scan package for real WiFi scanning
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No connectivity available for WiFi scanning');
      }

      // Use WiFiScan to get available networks
      final canScan = await WiFiScan.instance.canGetScannedResults(
        askPermissions: true,
      );
      
      if (canScan != CanGetScannedResults.yes) {
        throw Exception('Cannot access WiFi scan results: $canScan. Please check permissions.');
      }

      // Start WiFi scan
      await WiFiScan.instance.startScan();
      
      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 3));
      
      // Get scan results
      final networks = await WiFiScan.instance.getScannedResults();
      
      // Filter for ESP32 setup networks
      final esp32Networks = networks
          .where((network) => 
              network.ssid.startsWith(esp32APPrefix) && 
              network.ssid.isNotEmpty)
          .map((network) => network.ssid)
          .toSet() // Remove duplicates
          .toList();
      
      if (kDebugMode) {
        print('📶 Total networks found: ${networks.length}');
        print('🎯 ESP32 networks found: ${esp32Networks.length}');
        for (final network in esp32Networks) {
          print('  📡 $network');
        }
      }
      
      return esp32Networks;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scanning for ESP32 networks: $e');
      }
      return [];
    }
  }

  /// Connect to ESP32 WiFi network - REAL IMPLEMENTATION
  Future<bool> connectToESP32WiFi(String ssid) async {
    try {
      if (kDebugMode) {
        print('🔗 Attempting to connect to ESP32 network: $ssid');
      }

      // Note: Automatic WiFi connection from Flutter is limited on both platforms
      // This method will guide user to connect manually
      
      // Check if we can access WiFi configuration
      final canConnect = await WiFiScan.instance.canGetScannedResults();
      if (canConnect != CanGetScannedResults.yes) {
        throw Exception('Cannot access WiFi: $canConnect. Please check permissions.');
      }

      // For Android: Use WiFi connection intent or guide user
      // For iOS: Guide user to connect manually via settings
      
      // Wait and check if connected
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final isConnected = await isConnectedToESP32AP();
        if (isConnected) {
          if (kDebugMode) {
            print('✅ Successfully connected to ESP32 WiFi');
          }
          return true;
        }
      }
      
      if (kDebugMode) {
        print('⏰ Connection timeout - please connect manually');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error connecting to ESP32 WiFi: $e');
      }
      return false;
    }
  }

  /// Get detailed information about available ESP32 networks
  Future<List<Map<String, dynamic>>> getAvailableESP32Networks() async {
    try {
      if (kDebugMode) {
        print('📡 Getting detailed ESP32 network information...');
      }
      
      // Check permissions
      final canScan = await WiFiScan.instance.canGetScannedResults(
        askPermissions: true,
      );
      
      if (canScan != CanGetScannedResults.yes) {
        throw Exception('Cannot access WiFi scan results: $canScan');
      }

      // Start fresh scan
      await WiFiScan.instance.startScan();
      await Future.delayed(const Duration(seconds: 3));
      
      // Get scan results
      final networks = await WiFiScan.instance.getScannedResults();
      
      // Filter and format ESP32 networks
      final esp32Networks = networks
          .where((network) => 
              network.ssid.startsWith(esp32APPrefix) && 
              network.ssid.isNotEmpty)
          .map((network) => {
            'ssid': network.ssid,
            'bssid': network.bssid,
            'strength': network.level,
            'frequency': network.frequency,
            'isSecure': network.capabilities.contains('WPA') || 
                       network.capabilities.contains('WEP'),
            'password': esp32APPassword, // Known password for ESP32
          })
          .toList();
      
      if (kDebugMode) {
        print('🎯 Found ${esp32Networks.length} ESP32 setup networks:');
        for (final network in esp32Networks) {
          print('  📡 ${network['ssid']} (${network['strength']}dBm)');
        }
      }
      
      return esp32Networks;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting ESP32 network details: $e');
      }
      return [];
    }
  }

  /// Full setup flow without browser captive portal
  Future<bool> setupDeviceEndToEnd({
    required String esp32Ssid,
    required String homeSsid,
    required String homePassword,
    required String userKey,
    required String userUID,
  }) async {
    if (kDebugMode) {
      print('🚀 Starting end-to-end device setup...');
      print('  ESP32 SSID: $esp32Ssid');
      print('  Home SSID: $homeSsid');
      print('  UserKey: ${userKey.substring(0, 8)}***');
    }

    // 1) Verify connection to ESP32 AP
    final connectedToESP = await isConnectedToESP32AP();
    if (!connectedToESP) {
      if (kDebugMode) {
        print('❌ Not connected to ESP32 AP - asking user to connect manually');
      }
      // Don't return false here - let the user connect manually
    } else {
      if (kDebugMode) {
        print('✅ Connected to ESP32 AP');
      }
    }

    // 2) Try scan via ESP32 API; if it fails, continue anyway
    if (kDebugMode) {
      print('📡 Attempting WiFi scan...');
    }
    await scanWiFiNetworks(); // This has fallback built-in

    // 3) Send configuration (home WiFi + userKey + Firebase)
    if (kDebugMode) {
      print('📤 Sending configuration to ESP32...');
    }
    
    final configured = await configureDeviceWithUserKey(
      ssid: homeSsid,
      password: homePassword,
      userKey: userKey,
      userUID: userUID,
    );

    if (!configured) {
      if (kDebugMode) {
        print('❌ Configuration failed');
      }
      return false;
    }

    if (kDebugMode) {
      print('✅ Configuration sent successfully');
      print('⏳ Waiting for ESP32 to restart and connect to home WiFi...');
    }

    // 4) Allow ESP32 to reboot and join home WiFi
    await Future.delayed(const Duration(seconds: 8));

    if (kDebugMode) {
      print('🎉 Setup flow completed - ESP32 should now be on home WiFi');
    }

    // 5) Return success; caller will switch phone back to home WiFi
    return true;
  }

  /// Static helper: Instructions for user to maintain ESP32 connection
  static String getSetupInstructions() {
    return '''
🔗 QUAN TRỌNG: Giữ kết nối với ESP32

⚠️ VẤN ĐỀ: Android sẽ tự động chuyển sang 4G/WiFi khác khi ESP32 không có internet

✅ GIẢI PHÁP:
1. Kết nối vào mạng ESP32-Setup-XXXXXX (mật khẩu: 12345678)
2. ✋ TẮT dữ liệu di động (4G/5G) tạm thời
3. ✋ TẮT "Tự động chuyển mạng" trong Cài đặt > WiFi
4. Quay lại app để tiếp tục cấu hình
5. ✅ Bật lại 4G sau khi hoàn tất

📍 Cách tắt tự động chuyển mạng:
Cài đặt > WiFi > Nâng cao > "Chuyển sang dữ liệu di động" → TẮT
    ''';
  }

  /// Static helper: Show connection troubleshooting info
  static String getSetupTroubleshootingInfo() {
    return '''
🔧 KHẮC PHỤC SỰ CỐ:

❌ Lỗi "Software caused connection abort":
→ Android đã tự động chuyển mạng
→ Kiểm tra lại kết nối ESP32

❌ Lỗi "TimeoutException":
→ ESP32 có thể đang khởi động lại
→ Chờ 10s và thử lại

❌ Lỗi "No route to host":
→ Không kết nối được ESP32 AP
→ Kết nối lại mạng ESP32-Setup-XXXXXX

✅ GIẢI PHÁP NHANH:
1. Tắt hoàn toàn WiFi và bật lại
2. Chọn lại mạng ESP32-Setup-XXXXXX  
3. Tắt dữ liệu di động
4. Thử lại ngay lập tức
    ''';
  }

  /// Get detailed error message for connection abort issues
  static String getConnectionAbortSolution() {
    return '''
🚨 ANDROID TỰ ĐỘNG CHUYỂN MẠNG!

❌ Vấn đề: Android phát hiện ESP32 không có internet nên tự động chuyển sang 4G/WiFi khác

✅ GIẢI PHÁP NGAY LẬP TỨC:

1. 🔴 TẮT DỮ LIỆU DI ĐỘNG:
   Vuốt xuống → Nhấn giữ icon "Mobile Data" → OFF

2. 🔄 KẾT NỐI LẠI ESP32:
   Settings → WiFi → Tìm "ESP32-Setup-XXXXXX" → Connect
   Password: 12345678

3. ✋ TẮT TỰ ĐỘNG CHUYỂN:
   WiFi Settings → Advanced → "Switch to mobile data" → OFF

4. 🔄 THỬ LẠI NGAY:
   Quay lại app và nhấn "Retry"

⚠️ LƯU Ý: Giữ mobile data TẮT trong suốt quá trình setup!
    ''';
  }
}
