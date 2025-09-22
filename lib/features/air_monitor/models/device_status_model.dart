class DeviceStatus {
  final bool isOnline;
  final int lastSeen;
  final DeviceInfo? deviceInfo;

  const DeviceStatus({
    required this.isOnline,
    required this.lastSeen,
    this.deviceInfo,
  });

  factory DeviceStatus.fromFirebase(Map<String, dynamic> data) {
    final rawLastSeen = _parseInt(data['last_seen']);
    // Convert seconds → milliseconds if needed
    final lastSeenMs = rawLastSeen < 2000000000 ? rawLastSeen * 1000 : rawLastSeen;

    return DeviceStatus(
      isOnline: data['is_online'] as bool? ?? false,
      lastSeen: lastSeenMs,
      deviceInfo: data['device_info'] != null
          ? DeviceInfo.fromFirebase(Map<String, dynamic>.from(data['device_info']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_online': isOnline,
      'last_seen': lastSeen,
      'device_info': deviceInfo?.toJson(),
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory DeviceStatus.offline() {
    return const DeviceStatus(
      isOnline: false,
      lastSeen: 0,
    );
  }

  DateTime get lastSeenDateTime => DateTime.fromMillisecondsSinceEpoch(lastSeen);

  bool get isReallyOnline {
    // Nếu ESP32 đang gửi dữ liệu (isOnline = true) thì coi là online
    // Không cần kiểm tra lastSeen nữa vì Firebase real-time sẽ tự động cập nhật isOnline
    return isOnline;
  }

  String get statusText {
    if (lastSeen == 0) return 'Chưa kết nối';
    
    // Ưu tiên isOnline flag từ Firebase
    if (isOnline) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeDiff = now - lastSeen;
      
      if (timeDiff < 60000) { // < 1 phút
        return 'Đang hoạt động';
      } else if (timeDiff < 180000) { // < 3 phút
        return 'Trực tuyến';
      } else {
        return 'Kết nối chậm';
      }
    } else {
      // Nếu isOnline = false, kiểm tra lastSeen
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeDiff = now - lastSeen;
      
      if (timeDiff < 300000) { // < 5 phút
        return 'Vừa mất kết nối';
      } else {
        return 'Ngoại tuyến';
      }
    }
  }

  String get statusColor {
    if (lastSeen == 0) return '#9E9E9E'; // Gray
    
    // Ưu tiên isOnline flag từ Firebase
    if (isOnline) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeDiff = now - lastSeen;
      
      if (timeDiff < 60000) { // < 1 phút - Xanh lá đậm
        return '#4CAF50';
      } else if (timeDiff < 180000) { // < 3 phút - Xanh lá
        return '#66BB6A';
      } else { // > 3 phút nhưng vẫn online - Vàng
        return '#FF9800';
      }
    } else {
      // Nếu offline
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeDiff = now - lastSeen;
      
      if (timeDiff < 300000) { // < 5 phút - Cam
        return '#FF5722';
      } else { // > 5 phút - Đỏ
        return '#F44336';
      }
    }
  }

  String get timeSinceLastSeen {
    if (lastSeen == 0) return 'Chưa bao giờ';
    
    final now = DateTime.now();
    final lastSeenDate = lastSeenDateTime;
    var diff = now.difference(lastSeenDate);

    // Guard: nếu timestamp ở tương lai (do lệch thời gian), coi là vừa xong
    if (diff.isNegative) {
      return 'Vừa xong';
    }

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} giây trước';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }

  @override
  String toString() {
    return 'DeviceStatus(isOnline: $isOnline, lastSeen: $lastSeen)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceStatus &&
          runtimeType == other.runtimeType &&
          isOnline == other.isOnline &&
          lastSeen == other.lastSeen &&
          deviceInfo == other.deviceInfo;

  @override
  int get hashCode => isOnline.hashCode ^ lastSeen.hashCode ^ deviceInfo.hashCode;
}

class DeviceInfo {
  final String deviceId;
  final String macAddress;
  final String ipAddress;
  final String wifiSsid;
  final int? rssi;
  final String firmwareVersion;

  const DeviceInfo({
    required this.deviceId,
    required this.macAddress,
    required this.ipAddress,
    required this.wifiSsid,
    this.rssi,
    required this.firmwareVersion,
  });

  factory DeviceInfo.fromFirebase(Map<String, dynamic> data) {
    return DeviceInfo(
      deviceId: data['device_id'] as String? ?? '',
      macAddress: data['mac_address'] as String? ?? '',
      ipAddress: data['ip_address'] as String? ?? '',
      wifiSsid: data['wifi_ssid'] as String? ?? '',
      rssi: data['rssi'] as int?,
      firmwareVersion: data['firmware_version'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'mac_address': macAddress,
      'ip_address': ipAddress,
      'wifi_ssid': wifiSsid,
      'rssi': rssi,
      'firmware_version': firmwareVersion,
    };
  }

  String get signalStrengthText {
    if (rssi == null) return 'Không xác định';
    final signal = rssi!;
    if (signal >= -30) return 'Rất tốt';
    if (signal >= -67) return 'Tốt';
    if (signal >= -70) return 'Trung bình';
    if (signal >= -80) return 'Yếu';
    return 'Rất yếu';
  }

  int get signalBars {
    if (rssi == null) return 0;
    final signal = rssi!;
    if (signal >= -30) return 4;
    if (signal >= -67) return 3;
    if (signal >= -70) return 2;
    if (signal >= -80) return 1;
    return 0;
  }

  @override
  String toString() {
    return 'DeviceInfo(deviceId: $deviceId, ip: $ipAddress, wifi: $wifiSsid)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceInfo &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          macAddress == other.macAddress &&
          ipAddress == other.ipAddress &&
          wifiSsid == other.wifiSsid &&
          rssi == other.rssi &&
          firmwareVersion == other.firmwareVersion;

  @override
  int get hashCode =>
      deviceId.hashCode ^
      macAddress.hashCode ^
      ipAddress.hashCode ^
      wifiSsid.hashCode ^
      rssi.hashCode ^
      firmwareVersion.hashCode;
}