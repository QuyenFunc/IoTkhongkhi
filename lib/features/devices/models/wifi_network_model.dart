import 'package:wifi_scan/wifi_scan.dart';

/// WiFi network information for display in network selector
class WiFiNetworkInfo {
  final String ssid;
  final String bssid;
  final int signalLevel;
  final int frequency;
  final bool isSecured;
  final String securityType;
  final int signalStrength; // 0-4 bars

  const WiFiNetworkInfo({
    required this.ssid,
    required this.bssid,
    required this.signalLevel,
    required this.frequency,
    required this.isSecured,
    required this.securityType,
    required this.signalStrength,
  });

  /// Create from WiFiScan WiFiAccessPoint
  factory WiFiNetworkInfo.fromWiFiAccessPoint(WiFiAccessPoint accessPoint) {
    // Calculate signal strength bars (0-4) from signal level (dBm)
    int calculateSignalBars(int signalLevel) {
      if (signalLevel >= -50) return 4; // Excellent
      if (signalLevel >= -60) return 3; // Good
      if (signalLevel >= -70) return 2; // Fair
      if (signalLevel >= -80) return 1; // Poor
      return 0; // Very poor
    }

    // Determine security type from capabilities string
    String getSecurityType(String capabilities) {
      if (capabilities.isEmpty) return 'Open';
      final caps = capabilities.toUpperCase();
      if (caps.contains('WPA3')) return 'WPA3';
      if (caps.contains('WPA2')) return 'WPA2';
      if (caps.contains('WPA')) return 'WPA';
      if (caps.contains('WEP')) return 'WEP';
      if (caps.contains('NONE') || caps.contains('OPEN')) return 'Open';
      return caps.isNotEmpty ? 'Secured' : 'Open';
    }

    final securityType = getSecurityType(accessPoint.capabilities);
    
    return WiFiNetworkInfo(
      ssid: accessPoint.ssid,
      bssid: accessPoint.bssid,
      signalLevel: accessPoint.level,
      frequency: accessPoint.frequency,
      isSecured: securityType != 'Open',
      securityType: securityType,
      signalStrength: calculateSignalBars(accessPoint.level),
    );
  }

  /// Get signal strength icon
  String get signalIcon {
    switch (signalStrength) {
      case 4:
        return '📶'; // Excellent
      case 3:
        return '📶'; // Good
      case 2:
        return '📶'; // Fair
      case 1:
        return '📶'; // Poor
      case 0:
      default:
        return '📶'; // Very poor
    }
  }

  /// Get signal strength text
  String get signalText {
    switch (signalStrength) {
      case 4:
        return 'Excellent';
      case 3:
        return 'Good';
      case 2:
        return 'Fair';
      case 1:
        return 'Poor';
      case 0:
      default:
        return 'Very Poor';
    }
  }

  /// Get security icon
  String get securityIcon {
    return isSecured ? '🔒' : '🔓';
  }

  /// Get frequency band
  String get frequencyBand {
    if (frequency >= 5000) return '5GHz';
    if (frequency >= 2400) return '2.4GHz';
    return 'Unknown';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WiFiNetworkInfo &&
          runtimeType == other.runtimeType &&
          ssid == other.ssid &&
          bssid == other.bssid;

  @override
  int get hashCode => ssid.hashCode ^ bssid.hashCode;

  @override
  String toString() {
    return 'WiFiNetworkInfo{ssid: $ssid, signalStrength: $signalStrength, isSecured: $isSecured, securityType: $securityType}';
  }
}

/// WiFi scan state
enum WiFiScanState {
  idle,
  scanning,
  completed,
  error,
  permissionDenied,
  notSupported,
}

/// WiFi scan result
class WiFiScanResult {
  final WiFiScanState state;
  final List<WiFiNetworkInfo> networks;
  final String? errorMessage;

  const WiFiScanResult({
    required this.state,
    this.networks = const [],
    this.errorMessage,
  });

  /// Create idle state
  factory WiFiScanResult.idle() {
    return const WiFiScanResult(state: WiFiScanState.idle);
  }

  /// Create scanning state
  factory WiFiScanResult.scanning() {
    return const WiFiScanResult(state: WiFiScanState.scanning);
  }

  /// Create completed state
  factory WiFiScanResult.completed(List<WiFiNetworkInfo> networks) {
    return WiFiScanResult(
      state: WiFiScanState.completed,
      networks: networks,
    );
  }

  /// Create error state
  factory WiFiScanResult.error(String message) {
    return WiFiScanResult(
      state: WiFiScanState.error,
      errorMessage: message,
    );
  }

  /// Create permission denied state
  factory WiFiScanResult.permissionDenied() {
    return const WiFiScanResult(
      state: WiFiScanState.permissionDenied,
      errorMessage: 'Location permission is required to scan WiFi networks',
    );
  }

  /// Create not supported state
  factory WiFiScanResult.notSupported() {
    return const WiFiScanResult(
      state: WiFiScanState.notSupported,
      errorMessage: 'WiFi scanning is not supported on this device',
    );
  }

  /// Check if scan is in progress
  bool get isScanning => state == WiFiScanState.scanning;

  /// Check if scan completed successfully
  bool get isCompleted => state == WiFiScanState.completed;

  /// Check if scan has error
  bool get hasError => state == WiFiScanState.error || 
                       state == WiFiScanState.permissionDenied || 
                       state == WiFiScanState.notSupported;

  @override
  String toString() {
    return 'WiFiScanResult{state: $state, networks: ${networks.length}, error: $errorMessage}';
  }
}
