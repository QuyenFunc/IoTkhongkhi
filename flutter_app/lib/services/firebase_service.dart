import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sensor_data.dart';
import '../models/device_model.dart';
import '../models/alert_model.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Current user ID
  String? get userId => _auth.currentUser?.uid;
  
  // Database references
  DatabaseReference get _devicesRef => _database.ref('devices');
  DatabaseReference get _sensorDataRef => _database.ref('sensorData');
  DatabaseReference get _alertsRef => _database.ref('alerts');
  DatabaseReference get _usersRef => _database.ref('users');
  
  // Stream subscriptions for real-time data
  Map<String, StreamSubscription> _subscriptions = {};
  
  // Current data
  Map<String, SensorData> _currentSensorData = {};
  Map<String, DeviceModel> _devices = {};
  List<AlertModel> _alerts = [];
  
  // Getters
  Map<String, SensorData> get currentSensorData => _currentSensorData;
  Map<String, DeviceModel> get devices => _devices;
  List<AlertModel> get alerts => _alerts;
  
  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  @override
  void dispose() {
    _subscriptions.values.forEach((subscription) => subscription.cancel());
    super.dispose();
  }
  
  /// Initialize Firebase listeners for user's devices
  Future<void> initializeUserData() async {
    if (userId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Listen to user's devices
      await _listenToUserDevices();
      
      // Listen to alerts
      await _listenToAlerts();
      
    } catch (e) {
      print('Error initializing user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Listen to user's devices
  Future<void> _listenToUserDevices() async {
    if (userId == null) return;
    
    _subscriptions['devices']?.cancel();
    _subscriptions['devices'] = _usersRef
        .child(userId!)
        .child('devices')
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> devicesData = event.snapshot.value as Map<dynamic, dynamic>;
        _devices.clear();
        
        devicesData.forEach((key, value) {
          try {
            DeviceModel device = DeviceModel.fromJson(Map<String, dynamic>.from(value));
            device.id = key;
            _devices[key] = device;
            
            // Start listening to sensor data for each device
            _listenToDeviceSensorData(key);
            
          } catch (e) {
            print('Error parsing device data: $e');
          }
        });
        
        notifyListeners();
      }
    });
  }
  
  /// Listen to sensor data for a specific device
  void _listenToDeviceSensorData(String deviceId) {
    _subscriptions['sensor_$deviceId']?.cancel();
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
          var latestKey = data.keys.first;
          var latestData = data[latestKey];
          
          try {
            SensorData sensorData = SensorData.fromJson(Map<String, dynamic>.from(latestData));
            _currentSensorData[deviceId] = sensorData;
            
            // Check for alerts based on thresholds
            _checkAlerts(deviceId, sensorData);
            
            notifyListeners();
          } catch (e) {
            print('Error parsing sensor data: $e');
          }
        }
      }
    });
  }
  
  /// Listen to user alerts
  Future<void> _listenToAlerts() async {
    if (userId == null) return;
    
    _subscriptions['alerts']?.cancel();
    _subscriptions['alerts'] = _alertsRef
        .child(userId!)
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> alertsData = event.snapshot.value as Map<dynamic, dynamic>;
        _alerts.clear();
        
        alertsData.forEach((key, value) {
          try {
            AlertModel alert = AlertModel.fromJson(Map<String, dynamic>.from(value));
            alert.id = key;
            _alerts.add(alert);
          } catch (e) {
            print('Error parsing alert data: $e');
          }
        });
        
        // Sort by timestamp descending
        _alerts.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));
        notifyListeners();
      }
    });
  }
  
  /// Send command to device (replaces Blynk virtual pins)
  Future<void> sendCommand(String deviceId, String command, dynamic value) async {
    if (userId == null) return;
    
    try {
      await _usersRef
          .child(userId!)
          .child('devices')
          .child(deviceId)
          .child('commands')
          .child(command)
          .set(value);
      
      print('Command sent: $command = $value to device $deviceId');
    } catch (e) {
      print('Error sending command: $e');
      throw e;
    }
  }
  
  /// Get historical sensor data
  Future<List<SensorData>> getHistoricalData(String deviceId, {int limit = 100}) async {
    try {
      DatabaseEvent event = await _sensorDataRef
          .child(deviceId)
          .orderByKey()
          .limitToLast(limit)
          .once();
      
      List<SensorData> historicalData = [];
      
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          try {
            SensorData sensorData = SensorData.fromJson(Map<String, dynamic>.from(value));
            historicalData.add(sensorData);
          } catch (e) {
            print('Error parsing historical data: $e');
          }
        });
        
        // Sort by timestamp
        historicalData.sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));
      }
      
      return historicalData;
    } catch (e) {
      print('Error getting historical data: $e');
      return [];
    }
  }
  
  /// Update device settings
  Future<void> updateDeviceSettings(String deviceId, Map<String, dynamic> settings) async {
    if (userId == null) return;
    
    try {
      await _usersRef
          .child(userId!)
          .child('devices')
          .child(deviceId)
          .child('settings')
          .update(settings);
      
      print('Device settings updated for $deviceId');
    } catch (e) {
      print('Error updating device settings: $e');
      throw e;
    }
  }
  
  /// Check for alerts based on sensor data and thresholds
  void _checkAlerts(String deviceId, SensorData sensorData) {
    if (userId == null) return;
    
    DeviceModel? device = _devices[deviceId];
    if (device?.settings == null) return;
    
    List<Map<String, dynamic>> alertsToSend = [];
    
    // Check temperature alerts
    if (sensorData.temperature != null) {
      double temp = sensorData.temperature!;
      if (device!.settings!.tempThreshold1 != null && temp < device.settings!.tempThreshold1!) {
        alertsToSend.add({
          'type': 'temperature_low',
          'message': 'Nhiệt độ thấp: ${temp.toStringAsFixed(1)}°C',
          'value': temp,
          'threshold': device.settings!.tempThreshold1,
        });
      } else if (device.settings!.tempThreshold2 != null && temp > device.settings!.tempThreshold2!) {
        alertsToSend.add({
          'type': 'temperature_high',
          'message': 'Nhiệt độ cao: ${temp.toStringAsFixed(1)}°C',
          'value': temp,
          'threshold': device.settings!.tempThreshold2,
        });
      }
    }
    
    // Check humidity alerts
    if (sensorData.humidity != null) {
      double humidity = sensorData.humidity!;
      if (device.settings!.humiThreshold1 != null && humidity < device.settings!.humiThreshold1!) {
        alertsToSend.add({
          'type': 'humidity_low',
          'message': 'Độ ẩm thấp: ${humidity.toStringAsFixed(1)}%',
          'value': humidity,
          'threshold': device.settings!.humiThreshold1,
        });
      } else if (device.settings!.humiThreshold2 != null && humidity > device.settings!.humiThreshold2!) {
        alertsToSend.add({
          'type': 'humidity_high',
          'message': 'Độ ẩm cao: ${humidity.toStringAsFixed(1)}%',
          'value': humidity,
          'threshold': device.settings!.humiThreshold2,
        });
      }
    }
    
    // Check dust alerts
    if (sensorData.dustPM25 != null) {
      double dust = sensorData.dustPM25!;
      if (device.settings!.dustThreshold1 != null && dust > device.settings!.dustThreshold1!) {
        String alertType = dust > (device.settings!.dustThreshold2 ?? 100) ? 'dust_critical' : 'dust_warning';
        String message = dust > (device.settings!.dustThreshold2 ?? 100) 
            ? 'Bụi PM2.5 nguy hiểm: ${dust.toStringAsFixed(1)} μg/m³'
            : 'Bụi PM2.5 cao: ${dust.toStringAsFixed(1)} μg/m³';
            
        alertsToSend.add({
          'type': alertType,
          'message': message,
          'value': dust,
          'threshold': device.settings!.dustThreshold1,
        });
      }
    }
    
    // Send alerts to Firebase
    for (var alertData in alertsToSend) {
      _sendAlert(deviceId, alertData);
    }
  }
  
  /// Send alert to Firebase
  Future<void> _sendAlert(String deviceId, Map<String, dynamic> alertData) async {
    if (userId == null) return;
    
    try {
      AlertModel alert = AlertModel(
        deviceId: deviceId,
        type: alertData['type'],
        message: alertData['message'],
        value: alertData['value'],
        threshold: alertData['threshold'],
        timestamp: DateTime.now().millisecondsSinceEpoch,
        acknowledged: false,
      );
      
      await _alertsRef
          .child(userId!)
          .push()
          .set(alert.toJson());
      
    } catch (e) {
      print('Error sending alert: $e');
    }
  }
  
  /// Acknowledge alert
  Future<void> acknowledgeAlert(String alertId) async {
    if (userId == null) return;
    
    try {
      await _alertsRef
          .child(userId!)
          .child(alertId)
          .update({
        'acknowledged': true,
        'acknowledgedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error acknowledging alert: $e');
      throw e;
    }
  }
  
  /// Clear all alerts
  Future<void> clearAllAlerts() async {
    if (userId == null) return;
    
    try {
      await _alertsRef.child(userId!).remove();
      _alerts.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing alerts: $e');
      throw e;
    }
  }
  
  /// Get device by ID
  DeviceModel? getDevice(String deviceId) {
    return _devices[deviceId];
  }
  
  /// Get latest sensor data for device
  SensorData? getLatestSensorData(String deviceId) {
    return _currentSensorData[deviceId];
  }
}
