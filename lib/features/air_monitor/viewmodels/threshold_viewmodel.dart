import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

class ThresholdViewModel extends ChangeNotifier {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  double _temperatureMin = 15.0;
  double _temperatureMax = 35.0;
  bool _temperatureEnabled = true;
  
  double _humidityMin = 30.0;
  double _humidityMax = 80.0;
  bool _humidityEnabled = true;
  
  double _pm25Min = 0.0;
  double _pm25Max = 50.0;
  bool _pm25Enabled = true;
  
  bool _isLoading = false;
  bool _isSaving = false;
  
  double get temperatureMin => _temperatureMin;
  double get temperatureMax => _temperatureMax;
  bool get temperatureEnabled => _temperatureEnabled;
  
  double get humidityMin => _humidityMin;
  double get humidityMax => _humidityMax;
  bool get humidityEnabled => _humidityEnabled;
  
  double get pm25Min => _pm25Min;
  double get pm25Max => _pm25Max;
  bool get pm25Enabled => _pm25Enabled;
  
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  
  ThresholdViewModel() {
    _loadThresholds();
  }
  
  Future<void> _loadThresholds() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _database.ref('/air_monitor/thresholds').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        if (data['temperature'] != null) {
          final temp = Map<String, dynamic>.from(data['temperature']);
          _temperatureMin = (temp['min'] as num).toDouble();
          _temperatureMax = (temp['max'] as num).toDouble();
          _temperatureEnabled = temp['enabled'] as bool? ?? true;
        }
        
        if (data['humidity'] != null) {
          final hum = Map<String, dynamic>.from(data['humidity']);
          _humidityMin = (hum['min'] as num).toDouble();
          _humidityMax = (hum['max'] as num).toDouble();
          _humidityEnabled = hum['enabled'] as bool? ?? true;
        }
        
        if (data['pm25'] != null) {
          final pm = Map<String, dynamic>.from(data['pm25']);
          _pm25Min = (pm['min'] as num).toDouble();
          _pm25Max = (pm['max'] as num).toDouble();
          _pm25Enabled = pm['enabled'] as bool? ?? true;
        }
      }
    } catch (e) {
      print('Error loading thresholds: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  void setTemperatureMin(double value) {
    if (value < _temperatureMax) {
      _temperatureMin = value;
      notifyListeners();
    }
  }
  
  void setTemperatureMax(double value) {
    if (value > _temperatureMin) {
      _temperatureMax = value;
      notifyListeners();
    }
  }
  
  void setTemperatureEnabled(bool value) {
    _temperatureEnabled = value;
    notifyListeners();
  }
  
  void setHumidityMin(double value) {
    if (value < _humidityMax) {
      _humidityMin = value;
      notifyListeners();
    }
  }
  
  void setHumidityMax(double value) {
    if (value > _humidityMin) {
      _humidityMax = value;
      notifyListeners();
    }
  }
  
  void setHumidityEnabled(bool value) {
    _humidityEnabled = value;
    notifyListeners();
  }
  
  void setPm25Min(double value) {
    if (value < _pm25Max) {
      _pm25Min = value;
      notifyListeners();
    }
  }
  
  void setPm25Max(double value) {
    if (value > _pm25Min) {
      _pm25Max = value;
      notifyListeners();
    }
  }
  
  void setPm25Enabled(bool value) {
    _pm25Enabled = value;
    notifyListeners();
  }
  
  Future<bool> saveThresholds() async {
    _isSaving = true;
    notifyListeners();
    
    try {
      final thresholds = {
        'temperature': {
          'min': _temperatureMin,
          'max': _temperatureMax,
          'enabled': _temperatureEnabled,
        },
        'humidity': {
          'min': _humidityMin,
          'max': _humidityMax,
          'enabled': _humidityEnabled,
        },
        'pm25': {
          'min': _pm25Min,
          'max': _pm25Max,
          'enabled': _pm25Enabled,
        },
        'updated_at': ServerValue.timestamp,
      };
      
      await _database.ref('/air_monitor/thresholds').set(thresholds);
      
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error saving thresholds: $e');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
