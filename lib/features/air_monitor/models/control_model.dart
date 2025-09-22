class DeviceControl {
  final String ledCommand;
  final int? lastCommandTime;

  const DeviceControl({
    required this.ledCommand,
    this.lastCommandTime,
  });

  factory DeviceControl.fromFirebase(Map<String, dynamic> data) {
    return DeviceControl(
      ledCommand: data['led_command'] as String? ?? 'OFF',
      lastCommandTime: _parseInt(data['last_command_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'led_command': ledCommand,
      'last_command_time': lastCommandTime,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory DeviceControl.defaultControl() {
    return const DeviceControl(
      ledCommand: 'OFF',
    );
  }

  bool get isLedOn => ledCommand == 'ON';

  DateTime? get lastCommandDateTime => 
      lastCommandTime != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastCommandTime!)
          : null;

  DeviceControl copyWithLedCommand(String newCommand) {
    return DeviceControl(
      ledCommand: newCommand,
      lastCommandTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  String toString() {
    return 'DeviceControl(ledCommand: $ledCommand, lastCommandTime: $lastCommandTime)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceControl &&
          runtimeType == other.runtimeType &&
          ledCommand == other.ledCommand &&
          lastCommandTime == other.lastCommandTime;

  @override
  int get hashCode => ledCommand.hashCode ^ lastCommandTime.hashCode;
}

enum LedCommand {
  on('ON'),
  off('OFF');

  const LedCommand(this.value);
  final String value;

  static LedCommand fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ON':
        return LedCommand.on;
      case 'OFF':
        return LedCommand.off;
      default:
        return LedCommand.off;
    }
  }

  String get displayText {
    switch (this) {
      case LedCommand.on:
        return 'Bật';
      case LedCommand.off:
        return 'Tắt';
    }
  }

  String get color {
    switch (this) {
      case LedCommand.on:
        return '#4CAF50';
      case LedCommand.off:
        return '#757575';
    }
  }

  LedCommand get toggle {
    switch (this) {
      case LedCommand.on:
        return LedCommand.off;
      case LedCommand.off:
        return LedCommand.on;
    }
  }
}

class AlertThresholds {
  final TemperatureThreshold temperature;
  final HumidityThreshold humidity;
  final PM25Threshold pm25;

  const AlertThresholds({
    required this.temperature,
    required this.humidity,
    required this.pm25,
  });

  factory AlertThresholds.fromFirebase(Map<String, dynamic> data) {
    return AlertThresholds(
      temperature: TemperatureThreshold.fromFirebase(
        Map<String, dynamic>.from(data['temperature'] ?? {}),
      ),
      humidity: HumidityThreshold.fromFirebase(
        Map<String, dynamic>.from(data['humidity'] ?? {}),
      ),
      pm25: PM25Threshold.fromFirebase(
        Map<String, dynamic>.from(data['pm25'] ?? {}),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature.toJson(),
      'humidity': humidity.toJson(),
      'pm25': pm25.toJson(),
    };
  }

  factory AlertThresholds.defaultThresholds() {
    return const AlertThresholds(
      temperature: TemperatureThreshold(min: 15.0, max: 35.0),
      humidity: HumidityThreshold(min: 30.0, max: 80.0),
      pm25: PM25Threshold(max: 50.0),
    );
  }
}

class TemperatureThreshold {
  final double min;
  final double max;

  const TemperatureThreshold({
    required this.min,
    required this.max,
  });

  factory TemperatureThreshold.fromFirebase(Map<String, dynamic> data) {
    return TemperatureThreshold(
      min: _parseDouble(data['min']) ?? 15.0,
      max: _parseDouble(data['max']) ?? 35.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class HumidityThreshold {
  final double min;
  final double max;

  const HumidityThreshold({
    required this.min,
    required this.max,
  });

  factory HumidityThreshold.fromFirebase(Map<String, dynamic> data) {
    return HumidityThreshold(
      min: TemperatureThreshold._parseDouble(data['min']) ?? 30.0,
      max: TemperatureThreshold._parseDouble(data['max']) ?? 80.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }
}

class PM25Threshold {
  final double max;

  const PM25Threshold({
    required this.max,
  });

  factory PM25Threshold.fromFirebase(Map<String, dynamic> data) {
    return PM25Threshold(
      max: TemperatureThreshold._parseDouble(data['max']) ?? 50.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'max': max,
    };
  }
}