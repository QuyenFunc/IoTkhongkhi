/// Data models for WiFi-based ESP32 setup

/// ESP32 hotspot information
class ESP32Hotspot {
  final String ssid;
  final String bssid;
  final int level; // Signal strength in dBm
  final int frequency;
  final String capabilities;
  final int timestamp;

  ESP32Hotspot({
    required this.ssid,
    required this.bssid,
    required this.level,
    required this.frequency,
    required this.capabilities,
    required this.timestamp,
  });

  /// Extract device ID from SSID
  String get deviceId {
    if (ssid.startsWith('ESP32-Setup-')) {
      return ssid.substring(12); // Remove "ESP32-Setup-" prefix
    }
    return ssid;
  }

  /// Get signal strength description
  String get signalStrength {
    if (level >= -30) return 'Excellent';
    if (level >= -50) return 'Good';
    if (level >= -70) return 'Fair';
    return 'Weak';
  }

  /// Check if network is secured
  bool get isSecured {
    return !capabilities.contains('OPEN');
  }

  @override
  String toString() {
    return 'ESP32Hotspot(ssid: $ssid, level: ${level}dBm, deviceId: $deviceId)';
  }
}

/// ESP32 device information
class ESP32DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String firmwareVersion;
  final String state;
  final String apSSID;
  final String apPassword;
  final String? wifiSSID;
  final String? wifiIP;
  final int? wifiRSSI;

  ESP32DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.firmwareVersion,
    required this.state,
    required this.apSSID,
    required this.apPassword,
    this.wifiSSID,
    this.wifiIP,
    this.wifiRSSI,
  });

  factory ESP32DeviceInfo.fromJson(Map<String, dynamic> json) {
    return ESP32DeviceInfo(
      deviceId: json['deviceId'] ?? '',
      deviceName: json['deviceName'] ?? '',
      firmwareVersion: json['firmwareVersion'] ?? '',
      state: json['state'] ?? '',
      apSSID: json['apSSID'] ?? '',
      apPassword: json['apPassword'] ?? '',
      wifiSSID: json['wifiSSID'],
      wifiIP: json['wifiIP'],
      wifiRSSI: json['wifiRSSI'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'firmwareVersion': firmwareVersion,
      'state': state,
      'apSSID': apSSID,
      'apPassword': apPassword,
      if (wifiSSID != null) 'wifiSSID': wifiSSID,
      if (wifiIP != null) 'wifiIP': wifiIP,
      if (wifiRSSI != null) 'wifiRSSI': wifiRSSI,
    };
  }

  /// Check if device is in setup mode
  bool get isInSetupMode => state == 'setup';

  /// Check if device is connecting to WiFi
  bool get isConnecting => state == 'connecting';

  /// Check if device is connected to WiFi
  bool get isConnected => state == 'connected';

  /// Check if device has an error
  bool get hasError => state == 'error';

  @override
  String toString() {
    return 'ESP32DeviceInfo(deviceName: $deviceName, state: $state, deviceId: $deviceId)';
  }
}

/// WiFi network information from ESP32 scan
class WiFiNetwork {
  final String ssid;
  final int rssi;
  final String encryption;

  WiFiNetwork({
    required this.ssid,
    required this.rssi,
    required this.encryption,
  });

  factory WiFiNetwork.fromJson(Map<String, dynamic> json) {
    return WiFiNetwork(
      ssid: json['ssid'] ?? '',
      rssi: json['rssi'] ?? 0,
      encryption: json['encryption'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'rssi': rssi,
      'encryption': encryption,
    };
  }

  /// Check if network is open (no password required)
  bool get isOpen => encryption == 'open';

  /// Check if network is secured
  bool get isSecured => !isOpen;

  /// Get signal strength description
  String get signalStrength {
    if (rssi >= -30) return 'Excellent';
    if (rssi >= -50) return 'Good';
    if (rssi >= -70) return 'Fair';
    return 'Weak';
  }

  /// Get signal strength icon
  String get signalIcon {
    if (rssi >= -30) return '📶';
    if (rssi >= -50) return '📶';
    if (rssi >= -70) return '📶';
    return '📶';
  }

  /// Get security icon
  String get securityIcon => isSecured ? '🔒' : '🔓';

  @override
  String toString() {
    return 'WiFiNetwork(ssid: $ssid, rssi: ${rssi}dBm, encryption: $encryption)';
  }
}

/// WiFi setup progress state
enum WiFiSetupState {
  scanning,
  hotspotFound,
  connecting,
  connected,
  configuring,
  completed,
  error,
}

/// WiFi setup progress information
class WiFiSetupProgress {
  final WiFiSetupState state;
  final String message;
  final double progress; // 0.0 to 1.0
  final ESP32DeviceInfo? deviceInfo;
  final String? errorMessage;

  WiFiSetupProgress({
    required this.state,
    required this.message,
    required this.progress,
    this.deviceInfo,
    this.errorMessage,
  });

  /// Create progress for scanning state
  factory WiFiSetupProgress.scanning() {
    return WiFiSetupProgress(
      state: WiFiSetupState.scanning,
      message: 'Scanning for ESP32 devices...',
      progress: 0.1,
    );
  }

  /// Create progress for hotspot found state
  factory WiFiSetupProgress.hotspotFound(ESP32DeviceInfo deviceInfo) {
    return WiFiSetupProgress(
      state: WiFiSetupState.hotspotFound,
      message: 'Found device: ${deviceInfo.deviceName}',
      progress: 0.2,
      deviceInfo: deviceInfo,
    );
  }

  /// Create progress for connecting state
  factory WiFiSetupProgress.connecting(ESP32DeviceInfo deviceInfo) {
    return WiFiSetupProgress(
      state: WiFiSetupState.connecting,
      message: 'Connecting to ${deviceInfo.apSSID}...',
      progress: 0.3,
      deviceInfo: deviceInfo,
    );
  }

  /// Create progress for connected state
  factory WiFiSetupProgress.connected(ESP32DeviceInfo deviceInfo) {
    return WiFiSetupProgress(
      state: WiFiSetupState.connected,
      message: 'Connected to device. Opening configuration...',
      progress: 0.5,
      deviceInfo: deviceInfo,
    );
  }

  /// Create progress for configuring state
  factory WiFiSetupProgress.configuring(ESP32DeviceInfo deviceInfo, String targetSSID) {
    return WiFiSetupProgress(
      state: WiFiSetupState.configuring,
      message: 'Configuring device for $targetSSID...',
      progress: 0.7,
      deviceInfo: deviceInfo,
    );
  }

  /// Create progress for completed state
  factory WiFiSetupProgress.completed(ESP32DeviceInfo deviceInfo) {
    return WiFiSetupProgress(
      state: WiFiSetupState.completed,
      message: 'Setup completed successfully!',
      progress: 1.0,
      deviceInfo: deviceInfo,
    );
  }

  /// Create progress for error state
  factory WiFiSetupProgress.error(String errorMessage) {
    return WiFiSetupProgress(
      state: WiFiSetupState.error,
      message: 'Setup failed',
      progress: 0.0,
      errorMessage: errorMessage,
    );
  }

  /// Check if setup is in progress
  bool get isInProgress {
    return state != WiFiSetupState.completed && state != WiFiSetupState.error;
  }

  /// Check if setup is completed
  bool get isCompleted => state == WiFiSetupState.completed;

  /// Check if setup has error
  bool get hasError => state == WiFiSetupState.error;

  @override
  String toString() {
    return 'WiFiSetupProgress(state: $state, message: $message, progress: ${(progress * 100).toInt()}%)';
  }
}
