import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE Configuration Service - Giải pháp hiện đại cho việc cấu hình ESP32
/// Không cần chuyển WiFi network, không bị auto-switch
/// Được sử dụng bởi nhiều thiết bị IoT hiện đại
class BLEConfigService {
  static final BLEConfigService _instance = BLEConfigService._internal();
  factory BLEConfigService() => _instance;
  BLEConfigService._internal();
  
  // ESP32 BLE Service UUIDs
  static const String ESP32_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String WIFI_SSID_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String WIFI_PASS_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a9";
  static const String CONFIG_STATUS_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26aa";
  static const String DEVICE_INFO_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26ab";
  
  // State management
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamController<BLEConfigStatus>? _statusController;
  
  Stream<BLEConfigStatus> get statusStream => 
      _statusController?.stream ?? const Stream.empty();
  
  /// Initialize BLE service
  Future<void> initialize() async {
    _statusController = StreamController<BLEConfigStatus>.broadcast();
    
    // Check if Bluetooth is available
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth không được hỗ trợ trên thiết bị này');
    }
    
    // Request Bluetooth to be turned on
    await FlutterBluePlus.turnOn();
    
    if (kDebugMode) {
      print('🔵 BLE Config Service initialized');
    }
  }
  
  /// Scan for ESP32 devices with BLE
  Future<List<ESP32BLEDevice>> scanForESP32Devices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final devices = <ESP32BLEDevice>[];
    
    try {
      if (kDebugMode) {
        print('🔍 Scanning for ESP32 BLE devices...');
      }
      
      _updateStatus(BLEConfigStatus.scanning());
      
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [Guid(ESP32_SERVICE_UUID)],
      );
      
      // Listen to scan results
      await for (final result in FlutterBluePlus.scanResults) {
        for (final r in result) {
          // Filter ESP32 devices
          if (r.device.platformName.contains('ESP32') ||
              r.advertisementData.serviceUuids.contains(Guid(ESP32_SERVICE_UUID))) {
            
            final device = ESP32BLEDevice(
              device: r.device,
              name: r.device.platformName.isNotEmpty 
                  ? r.device.platformName 
                  : 'ESP32-${r.device.remoteId.str.substring(12)}',
              rssi: r.rssi,
              id: r.device.remoteId.str,
            );
            
            // Avoid duplicates
            if (!devices.any((d) => d.id == device.id)) {
              devices.add(device);
              
              if (kDebugMode) {
                print('📱 Found: ${device.name} (${device.rssi}dBm)');
              }
            }
          }
        }
      }
      
      _updateStatus(BLEConfigStatus.scanComplete(devices.length));
      
      if (kDebugMode) {
        print('✅ Scan complete. Found ${devices.length} ESP32 devices');
      }
      
      return devices;
    } catch (e) {
      if (kDebugMode) {
        print('❌ BLE scan error: $e');
      }
      _updateStatus(BLEConfigStatus.error(e.toString()));
      rethrow;
    }
  }
  
  /// Connect to ESP32 device via BLE
  Future<bool> connectToDevice(ESP32BLEDevice esp32Device) async {
    try {
      if (kDebugMode) {
        print('🔗 Connecting to ${esp32Device.name}...');
      }
      
      _updateStatus(BLEConfigStatus.connecting(esp32Device.name));
      
      // Disconnect from any previous device
      await _disconnectCurrent();
      
      // Connect to new device
      await esp32Device.device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );
      
      _connectedDevice = esp32Device.device;
      
      // Listen to connection state
      _connectionStateSubscription = esp32Device.device.connectionState.listen(
        (state) {
          if (state == BluetoothConnectionState.disconnected) {
            if (kDebugMode) {
              print('📱 Device disconnected');
            }
            _updateStatus(BLEConfigStatus.disconnected());
            _connectedDevice = null;
          }
        },
      );
      
      // Discover services
      final services = await esp32Device.device.discoverServices();
      
      // Verify ESP32 service exists
      final esp32Service = services.firstWhere(
        (s) => s.uuid == Guid(ESP32_SERVICE_UUID),
        orElse: () => throw Exception('ESP32 configuration service not found'),
      );
      
      if (kDebugMode) {
        print('✅ Connected to ${esp32Device.name}');
        print('📋 Found ${esp32Service.characteristics.length} characteristics');
      }
      
      _updateStatus(BLEConfigStatus.connected(esp32Device.name));
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Connection error: $e');
      }
      _updateStatus(BLEConfigStatus.error(e.toString()));
      return false;
    }
  }
  
  /// Configure WiFi credentials via BLE
  Future<bool> configureWiFi({
    required String ssid,
    required String password,
    Map<String, dynamic>? additionalConfig,
  }) async {
    if (_connectedDevice == null) {
      throw Exception('No device connected');
    }
    
    try {
      if (kDebugMode) {
        print('📡 Configuring WiFi via BLE...');
        print('  SSID: $ssid');
      }
      
      _updateStatus(BLEConfigStatus.configuring());
      
      // Get service and characteristics
      final services = await _connectedDevice!.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid == Guid(ESP32_SERVICE_UUID),
      );
      
      // Write SSID
      final ssidChar = service.characteristics.firstWhere(
        (c) => c.uuid == Guid(WIFI_SSID_CHAR_UUID),
      );
      await ssidChar.write(utf8.encode(ssid), withoutResponse: false);
      
      if (kDebugMode) {
        print('✅ SSID written');
      }
      
      // Write Password
      final passChar = service.characteristics.firstWhere(
        (c) => c.uuid == Guid(WIFI_PASS_CHAR_UUID),
      );
      await passChar.write(utf8.encode(password), withoutResponse: false);
      
      if (kDebugMode) {
        print('✅ Password written');
      }
      
      // Write additional config if provided
      if (additionalConfig != null) {
        // TODO: Implement additional config characteristics
        // For now, we'll just log it
        if (kDebugMode) {
          print('📝 Additional config: $additionalConfig');
        }
      }
      
      // Monitor configuration status
      final statusChar = service.characteristics.firstWhere(
        (c) => c.uuid == Guid(CONFIG_STATUS_CHAR_UUID),
      );
      
      // Enable notifications
      await statusChar.setNotifyValue(true);
      
      // Listen for status updates
      final completer = Completer<bool>();
      StreamSubscription<List<int>>? statusSubscription;
      
      statusSubscription = statusChar.lastValueStream.listen(
        (value) {
          if (value.isNotEmpty) {
            final status = utf8.decode(value);
            if (kDebugMode) {
              print('📊 Config status: $status');
            }
            
            if (status.contains('success')) {
              _updateStatus(BLEConfigStatus.configComplete());
              completer.complete(true);
              statusSubscription?.cancel();
            } else if (status.contains('error')) {
              _updateStatus(BLEConfigStatus.error('Configuration failed'));
              completer.complete(false);
              statusSubscription?.cancel();
            }
          }
        },
      );
      
      // Wait for configuration to complete (with timeout)
      final success = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          statusSubscription?.cancel();
          return false;
        },
      );
      
      if (kDebugMode) {
        print(success ? '✅ WiFi configured successfully' : '❌ WiFi configuration failed');
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Configuration error: $e');
      }
      _updateStatus(BLEConfigStatus.error(e.toString()));
      return false;
    }
  }
  
  /// Get device information via BLE
  Future<Map<String, dynamic>?> getDeviceInfo() async {
    if (_connectedDevice == null) {
      return null;
    }
    
    try {
      final services = await _connectedDevice!.discoverServices();
      final service = services.firstWhere(
        (s) => s.uuid == Guid(ESP32_SERVICE_UUID),
      );
      
      final infoChar = service.characteristics.firstWhere(
        (c) => c.uuid == Guid(DEVICE_INFO_CHAR_UUID),
      );
      
      final value = await infoChar.read();
      if (value.isNotEmpty) {
        final info = utf8.decode(value);
        return json.decode(info) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error reading device info: $e');
      }
    }
    
    return null;
  }
  
  /// Disconnect from current device
  Future<void> _disconnectCurrent() async {
    try {
      await _connectionStateSubscription?.cancel();
      await _connectedDevice?.disconnect();
      _connectedDevice = null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Disconnect error: $e');
      }
    }
  }
  
  /// Update status stream
  void _updateStatus(BLEConfigStatus status) {
    _statusController?.add(status);
  }
  
  /// Clean up resources
  Future<void> dispose() async {
    await _disconnectCurrent();
    await _statusController?.close();
  }
}

/// ESP32 BLE Device model
class ESP32BLEDevice {
  final BluetoothDevice device;
  final String name;
  final int rssi;
  final String id;
  
  ESP32BLEDevice({
    required this.device,
    required this.name,
    required this.rssi,
    required this.id,
  });
  
  String get signalStrength {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Good';
    if (rssi >= -70) return 'Fair';
    return 'Poor';
  }
}

/// BLE Configuration Status
class BLEConfigStatus {
  final String message;
  final bool isInProgress;
  final bool isError;
  final dynamic data;
  
  BLEConfigStatus({
    required this.message,
    this.isInProgress = false,
    this.isError = false,
    this.data,
  });
  
  factory BLEConfigStatus.scanning() => BLEConfigStatus(
    message: 'Đang tìm kiếm thiết bị ESP32...',
    isInProgress: true,
  );
  
  factory BLEConfigStatus.scanComplete(int count) => BLEConfigStatus(
    message: 'Tìm thấy $count thiết bị',
    data: count,
  );
  
  factory BLEConfigStatus.connecting(String deviceName) => BLEConfigStatus(
    message: 'Đang kết nối với $deviceName...',
    isInProgress: true,
  );
  
  factory BLEConfigStatus.connected(String deviceName) => BLEConfigStatus(
    message: 'Đã kết nối với $deviceName',
  );
  
  factory BLEConfigStatus.disconnected() => BLEConfigStatus(
    message: 'Đã ngắt kết nối',
  );
  
  factory BLEConfigStatus.configuring() => BLEConfigStatus(
    message: 'Đang cấu hình WiFi...',
    isInProgress: true,
  );
  
  factory BLEConfigStatus.configComplete() => BLEConfigStatus(
    message: 'Cấu hình WiFi thành công!',
  );
  
  factory BLEConfigStatus.error(String error) => BLEConfigStatus(
    message: error,
    isError: true,
  );
}
