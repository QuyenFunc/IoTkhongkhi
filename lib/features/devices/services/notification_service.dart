import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../shared/models/device_model.dart' as device_models;
// QR Setup temporarily disabled - using placeholder models
import '../models/qr_setup_models_disabled.dart';
import 'device_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final DeviceService _deviceService = DeviceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  StreamSubscription<List<device_models.DeviceModel>>? _devicesSubscription;
  final Map<String, StreamSubscription<CurrentSensorData?>> _sensorSubscriptions = {};

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      
      // Start monitoring devices
      await _startDeviceMonitoring();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Notification service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing notification service: $e');
      }
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestNotificationPermissions();
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('✅ Firebase messaging permission granted');
      }

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    }
  }

  /// Start monitoring devices for alerts
  Future<void> _startDeviceMonitoring() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Listen to user's devices
    _devicesSubscription = _deviceService.getUserDevices().listen((devices) {
      _updateDeviceMonitoring(devices);
    });
  }

  /// Update device monitoring when device list changes
  void _updateDeviceMonitoring(List<device_models.DeviceModel> devices) {
    // Cancel existing subscriptions
    for (final subscription in _sensorSubscriptions.values) {
      subscription.cancel();
    }
    _sensorSubscriptions.clear();

    // Start monitoring each device
    for (final device in devices) {
      final subscription = _deviceService.getDeviceSensorData(device.id).listen(
        (sensorData) => _checkForAlerts(device, sensorData?.toSensorData()),
      );
      _sensorSubscriptions[device.id] = subscription;
    }

    if (kDebugMode) {
      print('📱 Monitoring ${devices.length} devices for alerts');
    }
  }

  /// Check sensor data for alert conditions
  void _checkForAlerts(device_models.DeviceModel device, SensorData? sensorData) {
    if (sensorData == null) return;

    // Check each alert condition
    _checkTemperatureAlerts(device, sensorData);
    _checkHumidityAlerts(device, sensorData);
    _checkAirQualityAlerts(device, sensorData);
    _checkCO2Alerts(device, sensorData);
    _checkVOCAlerts(device, sensorData);
  }

  /// Check temperature alerts
  void _checkTemperatureAlerts(device_models.DeviceModel device, SensorData sensorData) {
    final config = device.configuration;

    if (sensorData.temperature > config.thresholds.maxTemperature) {
      _sendAlert(
        device,
        AlertType.highTemperature,
        'High Temperature Alert',
        'Temperature is ${sensorData.temperature.toStringAsFixed(1)}°C in ${device.location}',
        AlertSeverity.warning,
      );
    } else if (sensorData.temperature < config.thresholds.minTemperature) {
      _sendAlert(
        device,
        AlertType.lowTemperature,
        'Low Temperature Alert',
        'Temperature is ${sensorData.temperature.toStringAsFixed(1)}°C in ${device.location}',
        AlertSeverity.warning,
      );
    }
  }

  /// Check humidity alerts
  void _checkHumidityAlerts(device_models.DeviceModel device, SensorData sensorData) {
    final config = device.configuration;

    if (sensorData.humidity > config.thresholds.maxHumidity) {
      _sendAlert(
        device,
        AlertType.highHumidity,
        'High Humidity Alert',
        'Humidity is ${sensorData.humidity.toStringAsFixed(1)}% in ${device.location}',
        AlertSeverity.warning,
      );
    } else if (sensorData.humidity < config.thresholds.minHumidity) {
      _sendAlert(
        device,
        AlertType.lowHumidity,
        'Low Humidity Alert',
        'Humidity is ${sensorData.humidity.toStringAsFixed(1)}% in ${device.location}',
        AlertSeverity.warning,
      );
    }
  }

  /// Check air quality alerts
  void _checkAirQualityAlerts(device_models.DeviceModel device, SensorData sensorData) {
    // Use default thresholds for PM2.5 and PM10
    const maxPM25 = 35.0; // WHO guideline
    const maxPM10 = 50.0; // WHO guideline

    if (sensorData.pm25 > maxPM25) {
      _sendAlert(
        device,
        AlertType.highPM25,
        'Poor Air Quality Alert',
        'PM2.5 is ${sensorData.pm25.toStringAsFixed(1)} μg/m³ in ${device.location}',
        AlertSeverity.critical,
      );
    }

    if (sensorData.pm10 > maxPM10) {
      _sendAlert(
        device,
        AlertType.highPM10,
        'Poor Air Quality Alert',
        'PM10 is ${sensorData.pm10.toStringAsFixed(1)} μg/m³ in ${device.location}',
        AlertSeverity.critical,
      );
    }
  }

  /// Check CO2 alerts
  void _checkCO2Alerts(device_models.DeviceModel device, SensorData sensorData) {
    // Use default threshold for CO2
    const maxCO2 = 1000.0; // ppm

    if (sensorData.co2 > maxCO2) {
      _sendAlert(
        device,
        AlertType.highCO2,
        'High CO2 Alert',
        'CO2 level is ${sensorData.co2.toStringAsFixed(0)} ppm in ${device.location}',
        AlertSeverity.warning,
      );
    }
  }

  /// Check VOC alerts
  void _checkVOCAlerts(device_models.DeviceModel device, SensorData sensorData) {
    // Use default threshold for VOC
    const maxVOC = 500.0; // ppb

    if (sensorData.voc > maxVOC) {
      _sendAlert(
        device,
        AlertType.highVOC,
        'High VOC Alert',
        'VOC level is ${sensorData.voc.toStringAsFixed(0)} ppb in ${device.location}',
        AlertSeverity.warning,
      );
    }
  }

  /// Send alert notification
  Future<void> _sendAlert(
    device_models.DeviceModel device,
    AlertType type,
    String title,
    String message,
    AlertSeverity severity,
  ) async {
    try {
      // Check if alert was recently sent to avoid spam
      if (await _wasRecentlySent(device.id, type)) {
        return;
      }

      // Create alert record
      final alert = DeviceAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: device.id,
        type: type,
        message: message,
        severity: severity,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Save alert to database
      await _saveAlert(alert);

      // Send local notification
      await _sendLocalNotification(title, message, device.id);

      // Mark as sent to prevent spam
      await _markAlertAsSent(device.id, type);

      if (kDebugMode) {
        print('🔔 Alert sent: $title - $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending alert: $e');
      }
    }
  }

  /// Send local notification
  Future<void> _sendLocalNotification(String title, String body, String deviceId) async {
    const androidDetails = AndroidNotificationDetails(
      'device_alerts',
      'Device Alerts',
      channelDescription: 'Notifications for device alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: deviceId,
    );
  }

  /// Save alert to database
  Future<void> _saveAlert(DeviceAlert alert) async {
    await _database
        .child('devices')
        .child(alert.deviceId)
        .child('alerts')
        .child(alert.id)
        .set(alert.toJson());
  }

  /// Check if alert was recently sent
  Future<bool> _wasRecentlySent(String deviceId, AlertType type) async {
    try {
      final snapshot = await _database
          .child('alertCooldowns')
          .child(deviceId)
          .child(type.name)
          .get();

      if (snapshot.exists) {
        final lastSent = DateTime.parse(snapshot.value as String);
        final cooldownPeriod = Duration(minutes: _getAlertCooldownMinutes(type));
        return DateTime.now().difference(lastSent) < cooldownPeriod;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Mark alert as sent
  Future<void> _markAlertAsSent(String deviceId, AlertType type) async {
    await _database
        .child('alertCooldowns')
        .child(deviceId)
        .child(type.name)
        .set(DateTime.now().toIso8601String());
  }

  /// Get alert cooldown period in minutes
  int _getAlertCooldownMinutes(AlertType type) {
    switch (type) {
      case AlertType.highPM25:
      case AlertType.highPM10:
        return 30; // 30 minutes for air quality
      case AlertType.highCO2:
        return 60; // 1 hour for CO2
      case AlertType.deviceOffline:
        return 120; // 2 hours for offline
      default:
        return 15; // 15 minutes for others
    }
  }

  /// Save FCM token
  Future<void> _saveFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _database
          .child('users')
          .child(user.uid)
          .child('fcmToken')
          .set(token);
    }
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // Navigate to device detail screen
      // This would need to be implemented with a navigation service
      if (kDebugMode) {
        print('📱 Notification tapped for device: ${response.payload}');
      }
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📨 Foreground message: ${message.notification?.title}');
    }
  }

  /// Dispose resources
  void dispose() {
    _devicesSubscription?.cancel();
    for (final subscription in _sensorSubscriptions.values) {
      subscription.cancel();
    }
    _sensorSubscriptions.clear();
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  if (kDebugMode) {
    print('📨 Background message: ${message.notification?.title}');
  }
}
