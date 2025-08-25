import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/device_model.dart';
import '../models/sensor_data.dart';

class DeviceService extends ChangeNotifier {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Current user ID
  String? get userId => _auth.currentUser?.uid;
  
  // Database references
  DatabaseReference get _devicesRef => _database.ref('devices');
  DatabaseReference get _sensorDataRef => _database.ref('sensorData');
  DatabaseReference get _usersRef => _database.ref('users');
  
  // Current data
  Map<String, DeviceModel> _devices = {};
  Map<String, SensorData> _latestSensorData = {};
  Map<String, List<SensorData>> _historicalData = {};
  
  // Loading states
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  Map<String, DeviceModel> get devices => _devices;
  Map<String, SensorData> get latestSensorData => _latestSensorData;
  Map<String, List<SensorData>> get historicalData => _historicalData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Stream subscriptions
  Map<String, StreamSubscription> _subscriptions = {};
  
  @override
  void dispose() {
    _subscriptions.values.forEach((subscription) => subscription.cancel());
    super.dispose();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Initialize device service for current user
  Future<void> initialize() async {
    if (userId == null) return;
    
    _setLoading(true);
    _setError(null);
    
    try {
      await loadUserDevices();
    } catch (e) {
      _setError('Khởi tạo dịch vụ thiết bị thất bại: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Load all devices for current user
  Future<void> loadUserDevices() async {
    if (userId == null) return;
    
    // Cancel existing subscriptions
    _subscriptions.values.forEach((sub) => sub.cancel());
    _subscriptions.clear();
    
    // Listen to user's devices
    _subscriptions['user_devices'] = _usersRef
        .child(userId!)
        .child('devices')
        .onValue
        .listen((event) {
      _devices.clear();
      
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> devicesData = event.snapshot.value as Map<dynamic, dynamic>;
        
        devicesData.forEach((key, value) {
          try {
            DeviceModel device = DeviceModel.fromJson(Map<String, dynamic>.from(value));
            device = device.copyWith(id: key);
            _devices[key] = device;
            
            // Start listening to sensor data for this device
            _listenToDeviceSensorData(key);
            
          } catch (e) {
            print('Error parsing device data for $key: $e');
          }
        });
      }
      
      notifyListeners();
    });
  }
  
  /// Listen to real-time sensor data for a device
  void _listenToDeviceSensorData(String deviceId) {
    _subscriptions['sensor_$deviceId'] = _sensorDataRef
        .child(deviceId)
        .orderByKey()
        .limitToLast(1)
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        if (data.isNotEmpty) {
          // Get the latest data entry
          var latestEntry = data.entries.last;
          var latestData = latestEntry.value;
          
          try {
            SensorData sensorData = SensorData.fromJson(Map<String, dynamic>.from(latestData));
            _latestSensorData[deviceId] = sensorData;
            notifyListeners();
          } catch (e) {
            print('Error parsing sensor data for $deviceId: $e');
          }
        }
      }
    });
  }
  
  /// Get historical sensor data for a device
  Future<List<SensorData>> getHistoricalSensorData(String deviceId, {int limit = 100}) async {
    try {
      DatabaseEvent event = await _sensorDataRef
          .child(deviceId)
          .orderByKey()
          .limitToLast(limit)
          .once();
      
      List<SensorData> data = [];
      
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> sensorData = event.snapshot.value as Map<dynamic, dynamic>;
        
        sensorData.forEach((key, value) {
          try {
            SensorData sensor = SensorData.fromJson(Map<String, dynamic>.from(value));
            data.add(sensor);
          } catch (e) {
            print('Error parsing historical data: $e');
          }
        });
        
        // Sort by timestamp
        data.sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));
      }
      
      _historicalData[deviceId] = data;
      notifyListeners();
      
      return data;
    } catch (e) {
      print('Error getting historical data: $e');
      return [];
    }
  }
  
  /// Send command to device (replaces Blynk virtual pins)
  /// V3 equivalent - Manual air quality check
  Future<bool> checkAirQuality(String deviceId) async {
    return await sendCommand(deviceId, 'checkAirQuality', true);
  }
  
  /// V4 equivalent - Toggle auto warning
  Future<bool> toggleAutoWarning(String deviceId, bool enabled) async {
    return await sendCommand(deviceId, 'autoWarning', enabled);
  }
  
  /// Send generic command to device
  Future<bool> sendCommand(String deviceId, String command, dynamic value) async {
    if (userId == null) {
      _setError('Người dùng chưa đăng nhập');
      return false;
    }
    
    try {
      await _usersRef
          .child(userId!)
          .child('devices')
          .child(deviceId)
          .child('commands')
          .child(command)
          .set({
        'value': value,
        'timestamp': ServerValue.timestamp,
        'executed': false,
      });
      
      print('Command sent: $command = $value to device $deviceId');
      return true;
    } catch (e) {
      _setError('Gửi lệnh thất bại: $e');
      return false;
    }
  }
  
  /// Update device settings (thresholds)
  Future<bool> updateDeviceSettings(String deviceId, DeviceSettings settings) async {
    if (userId == null) {
      _setError('Người dùng chưa đăng nhập');
      return false;
    }
    
    try {
      await _usersRef
          .child(userId!)
          .child('devices')
          .child(deviceId)
          .child('settings')
          .set(settings.toJson());
      
      // Also send as command to device
      await sendCommand(deviceId, 'updateSettings', settings.toJson());
      
      return true;
    } catch (e) {
      _setError('Cập nhật cài đặt thất bại: $e');
      return false;
    }
  }
  
  /// Add new device
  Future<bool> addDevice(String deviceId, String deviceName, String? location) async {
    if (userId == null) {
      _setError('Người dùng chưa đăng nhập');
      return false;
    }
    
    try {
      DeviceModel newDevice = DeviceModel(
        id: deviceId,
        name: deviceName,
        location: location,
        status: 'pending',
        settings: DeviceSettings.defaultSettings(),
      );
      
      await _usersRef
          .child(userId!)
          .child('devices')
          .child(deviceId)
          .set(newDevice.toJson());
      
      return true;
    } catch (e) {
      _setError('Thêm thiết bị thất bại: $e');
      return false;
    }
  }
  
  /// Update device info
  Future<bool> updateDeviceInfo(String deviceId, String name, String? location) async {
    if (userId == null) {
      _setError('Người dùng chưa đăng nhập');
      return false;
    }
    
    try {
      await _usersRef
          .child(userId!)
          .child('devices')
          .child(deviceId)
          .update({
        'name': name,
        'location': location,
      });
      
      return true;
    } catch (e) {
      _setError('Cập nhật thông tin thiết bị thất bại: $e');
      return false;
    }
  }
  
  /// Remove device
  Future<bool> removeDevice(String deviceId) async {
    if (userId == null) {
      _setError('Người dùng chưa đăng nhập');
      return false;
    }
    
    try {
      // Remove from user's devices
      await _usersRef
          .child(userId!)
          .child('devices')
          .child(deviceId)
          .remove();
      
      // Cancel sensor data subscription
      _subscriptions['sensor_$deviceId']?.cancel();
      _subscriptions.remove('sensor_$deviceId');
      
      // Remove from local data
      _devices.remove(deviceId);
      _latestSensorData.remove(deviceId);
      _historicalData.remove(deviceId);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Xóa thiết bị thất bại: $e');
      return false;
    }
  }
  
  /// Restart device
  Future<bool> restartDevice(String deviceId) async {
    return await sendCommand(deviceId, 'restart', true);
  }
  
  /// Reset device to factory settings
  Future<bool> resetDevice(String deviceId) async {
    return await sendCommand(deviceId, 'reset', true);
  }
  
  /// Get device by ID
  DeviceModel? getDevice(String deviceId) {
    return _devices[deviceId];
  }
  
  /// Get latest sensor data for device
  SensorData? getLatestSensorData(String deviceId) {
    return _latestSensorData[deviceId];
  }
  
  /// Get all online devices
  List<DeviceModel> get onlineDevices {
    return _devices.values.where((device) => device.isOnline).toList();
  }
  
  /// Get all offline devices
  List<DeviceModel> get offlineDevices {
    return _devices.values.where((device) => device.isOffline).toList();
  }
  
  /// Get device count by status
  int get deviceCount => _devices.length;
  int get onlineDeviceCount => onlineDevices.length;
  int get offlineDeviceCount => offlineDevices.length;
  
  /// Check if any device has critical alerts
  bool get hasCriticalAlerts {
    for (var deviceId in _devices.keys) {
      SensorData? data = _latestSensorData[deviceId];
      DeviceModel? device = _devices[deviceId];
      
      if (data != null && device?.settings != null) {
        // Check critical thresholds
        if (data.temperature != null && device!.settings!.tempThreshold2 != null) {
          if (data.temperature! > device.settings!.tempThreshold2! + 5) return true; // 5 degrees over max
        }
        
        if (data.dustPM25 != null && device.settings!.dustThreshold2 != null) {
          if (data.dustPM25! > device.settings!.dustThreshold2!) return true;
        }
      }
    }
    return false;
  }
  
  /// Get overall air quality status
  String get overallAirQualityStatus {
    if (_latestSensorData.isEmpty) return 'unknown';
    
    List<String> statuses = _latestSensorData.values
        .map((data) => data.dustStatus)
        .toList();
    
    if (statuses.contains('hazardous')) return 'hazardous';
    if (statuses.contains('unhealthy')) return 'unhealthy';
    if (statuses.contains('unhealthy_sensitive')) return 'unhealthy_sensitive';
    if (statuses.contains('moderate')) return 'moderate';
    if (statuses.contains('good')) return 'good';
    
    return 'unknown';
  }
  
  /// Calculate average values across all devices
  Map<String, double> get averageValues {
    if (_latestSensorData.isEmpty) return {};
    
    List<SensorData> validData = _latestSensorData.values
        .where((data) => data.isValid)
        .toList();
    
    if (validData.isEmpty) return {};
    
    double avgTemp = validData
        .map((data) => data.temperature ?? 0)
        .reduce((a, b) => a + b) / validData.length;
        
    double avgHumidity = validData
        .map((data) => data.humidity ?? 0)
        .reduce((a, b) => a + b) / validData.length;
        
    double avgDust = validData
        .map((data) => data.dustPM25 ?? 0)
        .reduce((a, b) => a + b) / validData.length;
    
    return {
      'temperature': avgTemp,
      'humidity': avgHumidity,
      'dustPM25': avgDust,
    };
  }
}