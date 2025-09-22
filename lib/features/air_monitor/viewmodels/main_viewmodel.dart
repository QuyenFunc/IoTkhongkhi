import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data_model.dart';
import '../models/device_status_model.dart';
import '../models/control_model.dart';

/// ViewModel chính cho màn hình giám sát chất lượng không khí
class MainViewModel extends ChangeNotifier {
  // Firebase Database reference
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  // Stream subscriptions
  StreamSubscription<DatabaseEvent>? _sensorDataSubscription;
  StreamSubscription<DatabaseEvent>? _statusSubscription;
  StreamSubscription<DatabaseEvent>? _controlSubscription;
  StreamSubscription<DatabaseEvent>? _thresholdsSubscription;
  StreamSubscription<DatabaseEvent>? _alertSubscription;
  
  // Current data
  SensorData _sensorData = SensorData.empty();
  DeviceStatus _deviceStatus = DeviceStatus.offline();
  DeviceControl _deviceControl = DeviceControl.defaultControl();
  AlertThresholds _thresholds = AlertThresholds.defaultThresholds();
  
  // Loading states
  bool _isLoading = true;
  bool _isCommandLoading = false;
  String? _errorMessage;
  
  // Getters
  SensorData get sensorData => _sensorData;
  DeviceStatus get deviceStatus => _deviceStatus;
  DeviceControl get deviceControl => _deviceControl;
  AlertThresholds get thresholds => _thresholds;
  bool get isLoading => _isLoading;
  bool get isCommandLoading => _isCommandLoading;
  String? get errorMessage => _errorMessage;
  
  /// Khởi tạo và bắt đầu lắng nghe dữ liệu
  void initialize() {
    if (kDebugMode) {
      print('🚀 MainViewModel: Initializing...');
    }
    
    _startListening();
  }
  
  /// Bắt đầu lắng nghe các stream từ Firebase
  void _startListening() {
    // Lắng nghe dữ liệu cảm biến mới nhất
    _sensorDataSubscription = _database
        .ref('/air_monitor/latest_data')
        .onValue
        .listen(
      (DatabaseEvent event) {
        _handleSensorDataEvent(event);
      },
      onError: (error) {
        _handleError('Sensor Data', error);
      },
    );
    
    // Lắng nghe trạng thái thiết bị
    _statusSubscription = _database
        .ref('/air_monitor/status')
        .onValue
        .listen(
      (DatabaseEvent event) {
        _handleStatusEvent(event);
      },
      onError: (error) {
        _handleError('Device Status', error);
      },
    );
    
    // Lắng nghe trạng thái điều khiển
    _controlSubscription = _database
        .ref('/air_monitor/control')
        .onValue
        .listen(
      (DatabaseEvent event) {
        _handleControlEvent(event);
      },
      onError: (error) {
        _handleError('Device Control', error);
      },
    );
    
    // Lắng nghe ngưỡng cảnh báo
    _thresholdsSubscription = _database
        .ref('/air_monitor/thresholds')
        .onValue
        .listen(
      (DatabaseEvent event) {
        _handleThresholdsEvent(event);
      },
      onError: (error) {
        _handleError('Thresholds', error);
      },
    );
    
    // Lắng nghe cảnh báo
    _alertSubscription = _database
        .ref('/air_monitor/alert')
        .onValue
        .listen(
      (DatabaseEvent event) {
        _handleAlertEvent(event);
      },
      onError: (error) {
        _handleError('Alert', error);
      },
    );
    
    if (kDebugMode) {
      print('📡 MainViewModel: Started listening to Firebase streams');
    }
  }
  
  /// Xử lý sự kiện dữ liệu cảm biến
  void _handleSensorDataEvent(DatabaseEvent event) {
    try {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _sensorData = SensorData.fromFirebase(data);
        
        if (kDebugMode) {
          print('📊 MainViewModel: Sensor data updated: $_sensorData');
        }
        
        _setLoading(false);
        _clearError();
        notifyListeners();
      }
    } catch (e) {
      _handleError('Parsing sensor data', e);
    }
  }
  
  /// Xử lý sự kiện trạng thái thiết bị
  void _handleStatusEvent(DatabaseEvent event) {
    try {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _deviceStatus = DeviceStatus.fromFirebase(data);
        
        if (kDebugMode) {
          print('📱 MainViewModel: Device status updated: $_deviceStatus');
        }
        
        notifyListeners();
      }
    } catch (e) {
      _handleError('Parsing device status', e);
    }
  }
  
  /// Xử lý sự kiện điều khiển thiết bị
  void _handleControlEvent(DatabaseEvent event) {
    try {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _deviceControl = DeviceControl.fromFirebase(data);
        
        if (kDebugMode) {
          print('🎛️ MainViewModel: Device control updated: $_deviceControl');
        }
        
        notifyListeners();
      }
    } catch (e) {
      _handleError('Parsing device control', e);
    }
  }
  
  /// Xử lý sự kiện ngưỡng cảnh báo
  void _handleThresholdsEvent(DatabaseEvent event) {
    try {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _thresholds = AlertThresholds.fromFirebase(data);
        
        if (kDebugMode) {
          print('⚠️ MainViewModel: Thresholds updated: $_thresholds');
        }
        
        notifyListeners();
      }
    } catch (e) {
      _handleError('Parsing thresholds', e);
    }
  }
  
  /// Gửi lệnh điều khiển LED
  Future<bool> setLedCommand(LedCommand command) async {
    _setCommandLoading(true);
    
    try {
      if (kDebugMode) {
        print('💡 MainViewModel: Sending LED command: ${command.value}');
      }
      
      await _database.ref('/air_monitor/control/led_command').set(command.value);
      
      if (kDebugMode) {
        print('✅ MainViewModel: LED command sent successfully');
      }
      
      _setCommandLoading(false);
      return true;
    } catch (e) {
      _handleError('Sending LED command', e);
      _setCommandLoading(false);
      return false;
    }
  }
  
  /// Toggle LED (bật/tắt)
  Future<bool> toggleLed() async {
    final currentCommand = LedCommand.fromString(_deviceControl.ledCommand);
    return await setLedCommand(currentCommand.toggle);
  }
  
  /// Cập nhật ngưỡng cảnh báo
  Future<bool> updateThresholds(AlertThresholds newThresholds) async {
    try {
      if (kDebugMode) {
        print('⚠️ MainViewModel: Updating thresholds');
      }
      
      await _database.ref('/air_monitor/thresholds').set(newThresholds.toJson());
      
      if (kDebugMode) {
        print('✅ MainViewModel: Thresholds updated successfully');
      }
      
      return true;
    } catch (e) {
      _handleError('Updating thresholds', e);
      return false;
    }
  }
  
  /// Kiểm tra xem có cảnh báo nào không
  bool get hasAlerts {
    if (!_sensorData.isValid) return false;
    
    final temp = _sensorData.temperature;
    final humi = _sensorData.humidity;
    final pm25 = _sensorData.pm25;
    
    return temp < _thresholds.temperature.min ||
           temp > _thresholds.temperature.max ||
           humi < _thresholds.humidity.min ||
           humi > _thresholds.humidity.max ||
           pm25 > _thresholds.pm25.max;
  }
  
  /// Lấy danh sách các cảnh báo hiện tại
  List<String> get currentAlerts {
    final alerts = <String>[];
    
    if (!_sensorData.isValid) return alerts;
    
    final temp = _sensorData.temperature;
    final humi = _sensorData.humidity;
    final pm25 = _sensorData.pm25;
    
    if (temp < _thresholds.temperature.min) {
      alerts.add('Nhiệt độ quá thấp (${temp.toStringAsFixed(1)}°C)');
    } else if (temp > _thresholds.temperature.max) {
      alerts.add('Nhiệt độ quá cao (${temp.toStringAsFixed(1)}°C)');
    }
    
    if (humi < _thresholds.humidity.min) {
      alerts.add('Độ ẩm quá thấp (${humi.toStringAsFixed(1)}%)');
    } else if (humi > _thresholds.humidity.max) {
      alerts.add('Độ ẩm quá cao (${humi.toStringAsFixed(1)}%)');
    }
    
    if (pm25 > _thresholds.pm25.max) {
      alerts.add('Chất lượng không khí kém (PM2.5: ${pm25.toStringAsFixed(1)}μg/m³)');
    }
    
    return alerts;
  }
  
  /// Refresh dữ liệu
  Future<void> refresh() async {
    _setLoading(true);
    _clearError();
    
    // Firebase Realtime Database sẽ tự động cập nhật qua streams
    // Chỉ cần chờ một chút để đảm bảo có dữ liệu mới
    await Future.delayed(const Duration(seconds: 1));
    
    if (_sensorData.timestamp == 0) {
      _setError('Chưa có dữ liệu từ ESP32');
    }
    
    _setLoading(false);
  }
  
  /// Helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  void _setCommandLoading(bool loading) {
    if (_isCommandLoading != loading) {
      _isCommandLoading = loading;
      notifyListeners();
    }
  }
  
  void _setError(String error) {
    _errorMessage = error;
    _setLoading(false);
    notifyListeners();
    
    if (kDebugMode) {
      print('❌ MainViewModel Error: $error');
    }
  }
  
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  /// Xử lý sự kiện cảnh báo
  void _handleAlertEvent(DatabaseEvent event) {
    try {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final isActive = data['active'] as bool? ?? false;
        final reason = data['reason'] as String? ?? '';
        
        if (isActive) {
          if (kDebugMode) {
            print('🚨 MainViewModel: Alert triggered: $reason');
          }
          // Alert sẽ được xử lý bởi AlertService trong MainScreen
        }
      }
    } catch (e) {
      _handleError('Parsing alert', e);
    }
  }

  void _handleError(String operation, dynamic error) {
    _setError('Lỗi $operation: ${error.toString()}');
  }
  
  /// Cleanup
  @override
  void dispose() {
    if (kDebugMode) {
      print('🧹 MainViewModel: Disposing...');
    }
    
    _sensorDataSubscription?.cancel();
    _statusSubscription?.cancel();
    _controlSubscription?.cancel();
    _thresholdsSubscription?.cancel();
    _alertSubscription?.cancel();
    
    super.dispose();
  }
}
