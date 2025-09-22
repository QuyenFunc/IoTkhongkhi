import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service để duy trì kết nối liên tục với ESP32
/// Giải quyết vấn đề auto-switch network giữa các bước
class PersistentESP32Connection {
  static final PersistentESP32Connection _instance = PersistentESP32Connection._internal();
  factory PersistentESP32Connection() => _instance;
  PersistentESP32Connection._internal();
  
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();
  
  // Connection state
  bool _isConnectionActive = false;
  Timer? _keepAliveTimer;
  Timer? _reconnectTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  http.Client? _persistentClient;
  
  // Configuration
  static const String esp32APPrefix = 'ESP32-Setup-';
  static const String esp32IP = '192.168.4.1';
  static const int esp32Port = 80;
  static const Duration keepAliveInterval = Duration(seconds: 1); // Giảm xuống 1s
  static const Duration reconnectDelay = Duration(milliseconds: 500); // Nhanh hơn
  
  /// Bắt đầu session kết nối liên tục với ESP32
  Future<bool> startPersistentConnection() async {
    try {
      if (kDebugMode) {
        print('🔌 Starting persistent ESP32 connection...');
      }
      
      // Stop any existing connection
      await stopPersistentConnection();
      
      // Create persistent HTTP client with network binding
      _persistentClient = await _createNetworkBoundClient();
      
      // Start monitoring
      _startConnectivityMonitoring();
      _startKeepAlive();
      
      _isConnectionActive = true;
      
      if (kDebugMode) {
        print('✅ Persistent connection established');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to start persistent connection: $e');
      }
      return false;
    }
  }
  
  /// Dừng kết nối liên tục
  Future<void> stopPersistentConnection() async {
    if (kDebugMode) {
      print('🔌 Stopping persistent connection...');
    }
    
    _isConnectionActive = false;
    _keepAliveTimer?.cancel();
    _reconnectTimer?.cancel();
    _connectivitySubscription?.cancel();
    _persistentClient?.close();
    
    _keepAliveTimer = null;
    _reconnectTimer = null;
    _connectivitySubscription = null;
    _persistentClient = null;
  }
  
  /// Giám sát thay đổi kết nối mạng
  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) async {
        if (!_isConnectionActive) return;
        
        final hasWifi = results.contains(ConnectivityResult.wifi);
        
        if (hasWifi) {
          final isESP32 = await _isConnectedToESP32();
          
          if (!isESP32 && _isConnectionActive) {
            if (kDebugMode) {
              print('⚠️ Lost ESP32 connection - attempting to reconnect...');
            }
            _scheduleReconnect();
          }
        }
      },
    );
  }
  
  /// Keep-alive để giữ kết nối với phát hiện disconnect nhanh
  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    
    _keepAliveTimer = Timer.periodic(keepAliveInterval, (timer) async {
      if (!_isConnectionActive) {
        timer.cancel();
        return;
      }
      
      try {
        // Kiểm tra WiFi trước khi ping
        final isESP32 = await _isConnectedToESP32();
        if (!isESP32) {
          throw Exception('Not connected to ESP32 network');
        }
        
        final client = _persistentClient ?? await _createNetworkBoundClient();
        
        // Send keep-alive ping với timeout ngắn
        final response = await client.get(
          Uri.http('$esp32IP:$esp32Port', '/ping'),
        ).timeout(const Duration(milliseconds: 1500)); // Giảm timeout
        
        if (response.statusCode != 200) {
          throw Exception('Keep-alive ping failed with status ${response.statusCode}');
        }
        
        if (kDebugMode && DateTime.now().second % 5 == 0) {
          print('💓 Keep-alive OK');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Keep-alive failed: $e');
        }
        
        // Lập tức kiểm tra và xử lý
        await _handleConnectionLoss();
      }
    });
  }
  
  /// Xử lý khi mất kết nối
  Future<void> _handleConnectionLoss() async {
    if (!_isConnectionActive) return;
    
    if (kDebugMode) {
      print('🚨 Connection loss detected - checking network status...');
    }
    
    // Kiểm tra lại network state
    final isESP32 = await _isConnectedToESP32();
    
    if (!isESP32) {
      if (kDebugMode) {
        print('📱 Network switched away from ESP32 - attempting immediate reconnect...');
      }
      
      // Dừng keep-alive và bắt đầu reconnect process
      _keepAliveTimer?.cancel();
      _scheduleReconnect();
    } else {
      if (kDebugMode) {
        print('📶 Still on ESP32 network but ping failed - retrying...');
      }
      
      // Vẫn trên ESP32 nhưng ping fail - có thể là network congestion
      // Đợi một chút rồi thử lại
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
  
  /// Callback khi cần user reconnect
  Function(String message)? _onReconnectNeeded;
  
  /// Set callback cho reconnect
  void setReconnectCallback(Function(String message)? callback) {
    _onReconnectNeeded = callback;
  }
  
  /// Lên lịch reconnect với thông báo cho user
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    
    if (!_isConnectionActive) return;
    
    // Thông báo user cần kết nối lại
    if (_onReconnectNeeded != null) {
      _onReconnectNeeded!('Kết nối ESP32 bị ngắt. Vui lòng kết nối lại WiFi ESP32 và tiếp tục.');
    }
    
    _reconnectTimer = Timer(reconnectDelay, () async {
      if (!_isConnectionActive) return;
      
      if (kDebugMode) {
        print('🔄 Checking ESP32 connection status...');
      }
      
      final isConnected = await _isConnectedToESP32();
      if (isConnected) {
        if (kDebugMode) {
          print('✅ ESP32 connection restored');
        }
        
        // Kiểm tra thực tế có thể ping được không
        try {
          final client = _persistentClient ?? await _createNetworkBoundClient();
          final response = await client.get(
            Uri.http('$esp32IP:$esp32Port', '/ping'),
          ).timeout(const Duration(seconds: 2));
          
          if (response.statusCode == 200) {
            if (kDebugMode) {
              print('✅ ESP32 ping successful - resuming operations');
            }
            
            // Thông báo kết nối thành công
            if (_onReconnectNeeded != null) {
              _onReconnectNeeded!('Đã kết nối lại ESP32 thành công!');
            }
            
            _startKeepAlive();
            return;
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ ESP32 ping still failing: $e');
          }
        }
      }
      
      // Vẫn chưa kết nối được - retry
      if (_isConnectionActive) {
        if (kDebugMode) {
          print('🔄 Still not connected to ESP32 - retrying...');
        }
        _scheduleReconnect();
      }
    });
  }
  
  /// Kiểm tra kết nối ESP32
  Future<bool> _isConnectedToESP32() async {
    try {
      final wifiName = await _networkInfo.getWifiName();
      final cleanName = wifiName?.replaceAll('"', '') ?? '';
      return cleanName.startsWith(esp32APPrefix);
    } catch (e) {
      return false;
    }
  }
  
  /// Thực hiện request với auto-reconnect và timeout ngắn
  Future<T?> executeRequest<T>({
    required Future<T> Function(http.Client client) request,
    int maxRetries = 3,
    Duration? timeout,
  }) async {
    if (!_isConnectionActive) {
      await startPersistentConnection();
    }
    
    for (int i = 0; i < maxRetries; i++) {
      try {
        // Kiểm tra kết nối ESP32 trước mỗi request
        final isESP32 = await _isConnectedToESP32();
        if (!isESP32) {
          if (kDebugMode) {
            print('⚠️ Not on ESP32 network (attempt ${i + 1}/$maxRetries)');
          }
          
          if (i == 0) {
            // Lần đầu fail thì trigger reconnect callback
            _scheduleReconnect();
          }
          
          // Wait for reconnection với timeout tăng dần
          await Future.delayed(Duration(seconds: 2 + i));
          
          // Check again
          final reconnected = await _isConnectedToESP32();
          if (!reconnected) {
            if (i == maxRetries - 1) {
              throw Exception('Failed to reconnect to ESP32 after $maxRetries attempts');
            }
            continue; // Thử lại vòng lặp
          }
        }
        
        // Execute request với timeout ngắn hơn
        final client = _persistentClient ?? await _createNetworkBoundClient();
        final effectiveTimeout = timeout ?? const Duration(seconds: 3); // Giảm timeout mặc định
        
        final result = await request(client).timeout(effectiveTimeout);
        
        if (kDebugMode && i > 0) {
          print('✅ Request succeeded on attempt ${i + 1}');
        }
        
        return result;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Request failed (attempt ${i + 1}/$maxRetries): $e');
        }
        
        if (i == maxRetries - 1) {
          rethrow;
        }
        
        // Check if it's a network issue
        if (e.toString().contains('TimeoutException') || 
            e.toString().contains('SocketException') ||
            e.toString().contains('Connection')) {
          
          // Network issue - check connection
          final stillConnected = await _isConnectedToESP32();
          if (!stillConnected) {
            if (kDebugMode) {
              print('🚨 Network connection lost during request');
            }
            _scheduleReconnect();
          }
        }
        
        // Exponential backoff with jitter
        final delay = Duration(milliseconds: 500 * (1 << i) + (i * 100));
        await Future.delayed(delay);
      }
    }
    
    return null;
  }
  
  /// Thực hiện toàn bộ flow cấu hình trong một session
  Future<bool> configureESP32InOneSession({
    required String ssid,
    required String password,
    required String deviceId,
    required Map<String, dynamic> additionalConfig,
    required Function(String status) onStatusUpdate,
  }) async {
    try {
      // Start persistent connection
      final connected = await startPersistentConnection();
      if (!connected) {
        throw Exception('Failed to establish persistent connection');
      }
      
      onStatusUpdate('Đã kết nối với ESP32');
      
      // Step 1: Get device info
      final deviceInfo = await executeRequest<Map<String, dynamic>>(
        request: (client) async {
          final response = await client.get(
            Uri.http('$esp32IP:$esp32Port', '/api/device/info'),
          ).timeout(const Duration(seconds: 10));
          
          if (response.statusCode == 200) {
            return json.decode(response.body) as Map<String, dynamic>;
          }
          throw Exception('Failed to get device info');
        },
      );
      
      if (deviceInfo == null) {
        throw Exception('Unable to get device info');
      }
      
      onStatusUpdate('Đã lấy thông tin thiết bị');
      
      // Step 2: Scan WiFi networks
      final networks = await executeRequest<List<dynamic>>(
        request: (client) async {
          final response = await client.get(
            Uri.http('$esp32IP:$esp32Port', '/api/scan'),
          ).timeout(const Duration(seconds: 15));
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body) as Map<String, dynamic>;
            return data['networks'] as List<dynamic>;
          }
          throw Exception('Failed to scan networks');
        },
      );
      
      onStatusUpdate('Đã quét ${networks?.length ?? 0} mạng WiFi');
      
      // Step 3: Configure WiFi
      final configResult = await executeRequest<bool>(
        request: (client) async {
          final config = {
            'ssid': ssid,
            'password': password,
            'deviceId': deviceId,
            ...additionalConfig,
          };
          
          final response = await client.post(
            Uri.http('$esp32IP:$esp32Port', '/api/wifi/configure'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(config),
          ).timeout(const Duration(seconds: 20));
          
          if (response.statusCode == 200) {
            final result = json.decode(response.body) as Map<String, dynamic>;
            return result['success'] as bool? ?? false;
          }
          return false;
        },
      );
      
      if (configResult == true) {
        onStatusUpdate('Cấu hình WiFi thành công!');
        
        // Keep connection alive for a bit to ensure config is saved
        await Future.delayed(const Duration(seconds: 3));
        
        return true;
      } else {
        throw Exception('WiFi configuration failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Configuration failed: $e');
      }
      onStatusUpdate('Lỗi: ${e.toString()}');
      return false;
    } finally {
      // Stop persistent connection after configuration
      await stopPersistentConnection();
    }
  }
  
  /// Create network-bound HTTP client for Android
  Future<http.Client> _createNetworkBoundClient() async {
    if (!Platform.isAndroid) {
      return http.Client();
    }

    try {
      // Create HTTP client with custom connection factory
      final httpClient = HttpClient();
      
      // Bind to WiFi interface for Android
      httpClient.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) async {
        try {
          // Get WiFi interface
          final interfaces = await NetworkInterface.list();
          final wifiInterface = interfaces.firstWhere(
            (i) => i.name.toLowerCase().contains('wlan') || 
                   i.name.toLowerCase().contains('wifi'),
            orElse: () => interfaces.first,
          );
          
          // Use startConnect to get ConnectionTask
          return Socket.startConnect(
            uri.host,
            uri.port,
            sourceAddress: wifiInterface.addresses.first,
          );
        } catch (e) {
          // Fallback to normal connection
          return Socket.startConnect(uri.host, uri.port);
        }
      };
      
      if (kDebugMode) {
        print('✅ Created network-bound HTTP client for ESP32');
      }
      
      return IOClient(httpClient);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to create bound client: $e');
      }
      return http.Client();
    }
  }

  /// Get connection status
  bool get isActive => _isConnectionActive;
}
