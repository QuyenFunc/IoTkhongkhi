import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  // Stream controllers
  final StreamController<DashboardStats> _statsController = StreamController<DashboardStats>.broadcast();
  final StreamController<List<DeviceInfo>> _devicesController = StreamController<List<DeviceInfo>>.broadcast();
  final StreamController<List<RecentAlert>> _alertsController = StreamController<List<RecentAlert>>.broadcast();
  
  // Getters for streams
  Stream<DashboardStats> get statsStream => _statsController.stream;
  Stream<List<DeviceInfo>> get devicesStream => _devicesController.stream;
  Stream<List<RecentAlert>> get alertsStream => _alertsController.stream;
  
  // Subscriptions
  StreamSubscription? _statusSubscription;
  StreamSubscription? _alertSubscription;
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      if (kDebugMode) {
        print('🏠 DashboardService: Initializing...');
      }
      
      // Listen to device status changes
      _statusSubscription = _database
          .ref('/air_monitor/status')
          .onValue
          .listen(_handleStatusUpdate);
      
      // Listen to alerts
      _alertSubscription = _database
          .ref('/air_monitor/alert')
          .onValue
          .listen(_handleAlertUpdate);
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ DashboardService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ DashboardService: Error initializing: $e');
      }
    }
  }

  void _handleStatusUpdate(DatabaseEvent event) {
    try {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        // Calculate stats
        final stats = _calculateStats(data);
        _statsController.add(stats);
        
        // Create device info
        final deviceInfo = _createDeviceInfo(data);
        _devicesController.add([deviceInfo]);
        
        if (kDebugMode) {
          print('🏠 Dashboard stats updated: $stats');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling status update: $e');
      }
    }
  }

  void _handleAlertUpdate(DatabaseEvent event) {
    try {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        final isActive = data['active'] as bool? ?? false;
        final reason = data['reason'] as String? ?? '';
        final timestamp = data['timestamp'] as int? ?? 0;
        
        if (isActive && reason.isNotEmpty) {
          final alert = RecentAlert(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            message: reason,
            timestamp: timestamp,
            severity: _getSeverityFromReason(reason),
          );
          
          _alertsController.add([alert]);
          
          if (kDebugMode) {
            print('🚨 Dashboard alert updated: ${alert.message}');
          }
        } else {
          _alertsController.add([]);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling alert update: $e');
      }
    }
  }

  DashboardStats _calculateStats(Map<String, dynamic> statusData) {
    final isOnline = statusData['is_online'] as bool? ?? false;
    
    // For now, we have 1 device (ESP32)
    // In the future, this can be extended for multiple devices
    return DashboardStats(
      totalDevices: 1,
      onlineDevices: isOnline ? 1 : 0,
      offlineDevices: isOnline ? 0 : 1,
      activeAlerts: 0, // Will be updated by alert handler
    );
  }

  DeviceInfo _createDeviceInfo(Map<String, dynamic> statusData) {
    final isOnline = statusData['is_online'] as bool? ?? false;
    final lastSeen = statusData['last_seen'] as int? ?? 0;
    final deviceId = statusData['device_id'] as String? ?? 'ESP32-Unknown';
    final freeHeap = statusData['free_heap'] as int? ?? 0;
    
    return DeviceInfo(
      id: deviceId,
      name: 'ESP32 Air Monitor',
      type: 'Air Quality Sensor',
      isOnline: isOnline,
      lastSeen: lastSeen,
      batteryLevel: null, // ESP32 typically uses wall power
      signalStrength: null, // Can be added later
      freeHeap: freeHeap,
    );
  }

  AlertSeverity _getSeverityFromReason(String reason) {
    if (reason.toLowerCase().contains('temperature')) {
      return AlertSeverity.warning;
    } else if (reason.toLowerCase().contains('humidity')) {
      return AlertSeverity.info;
    } else if (reason.toLowerCase().contains('pm2.5')) {
      return AlertSeverity.critical;
    }
    return AlertSeverity.warning;
  }

  void dispose() {
    _statusSubscription?.cancel();
    _alertSubscription?.cancel();
    _statsController.close();
    _devicesController.close();
    _alertsController.close();
    _isInitialized = false;
  }
}

// Data models
class DashboardStats {
  final int totalDevices;
  final int onlineDevices;
  final int offlineDevices;
  final int activeAlerts;

  const DashboardStats({
    required this.totalDevices,
    required this.onlineDevices,
    required this.offlineDevices,
    required this.activeAlerts,
  });

  @override
  String toString() {
    return 'DashboardStats(total: $totalDevices, online: $onlineDevices, offline: $offlineDevices, alerts: $activeAlerts)';
  }
}

class DeviceInfo {
  final String id;
  final String name;
  final String type;
  final bool isOnline;
  final int lastSeen;
  final int? batteryLevel;
  final int? signalStrength;
  final int? freeHeap;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.isOnline,
    required this.lastSeen,
    this.batteryLevel,
    this.signalStrength,
    this.freeHeap,
  });

  DateTime get lastSeenDateTime => DateTime.fromMillisecondsSinceEpoch(
    lastSeen < 2000000000 ? lastSeen * 1000 : lastSeen
  );

  String get statusText {
    if (!isOnline) return 'Ngoại tuyến';
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastSeenMs = lastSeen < 2000000000 ? lastSeen * 1000 : lastSeen;
    final diff = now - lastSeenMs;
    
    if (diff < 60000) return 'Đang hoạt động';
    if (diff < 300000) return 'Trực tuyến';
    return 'Kết nối chậm';
  }

  @override
  String toString() {
    return 'DeviceInfo(id: $id, name: $name, isOnline: $isOnline)';
  }
}

class RecentAlert {
  final String id;
  final String message;
  final int timestamp;
  final AlertSeverity severity;

  const RecentAlert({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.severity,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(
    timestamp < 2000000000 ? timestamp * 1000 : timestamp
  );

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }

  @override
  String toString() {
    return 'RecentAlert(message: $message, severity: $severity)';
  }
}

enum AlertSeverity {
  info,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case AlertSeverity.info:
        return 'Thông tin';
      case AlertSeverity.warning:
        return 'Cảnh báo';
      case AlertSeverity.critical:
        return 'Nghiêm trọng';
    }
  }

  Color get color {
    switch (this) {
      case AlertSeverity.info:
        return const Color(0xFF2196F3);
      case AlertSeverity.warning:
        return const Color(0xFFFF9800);
      case AlertSeverity.critical:
        return const Color(0xFFF44336);
    }
  }
}
