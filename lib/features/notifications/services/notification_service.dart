import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;
  StreamSubscription<DatabaseEvent>? _alertSubscription;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      
      // Setup alert monitoring
      await _setupAlertMonitoring();
      
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
    await _requestPermissions();
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

  /// Setup alert monitoring for air quality thresholds
  Future<void> _setupAlertMonitoring() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Listen for new alerts
    _alertSubscription = _database
        .ref('alerts')
        .orderByChild('userId')
        .equalTo(user.uid)
        .onChildAdded
        .listen(_handleNewAlert);
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Save FCM token to database
  Future<void> _saveFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _database
          .ref('users')
          .child(user.uid)
          .child('fcmToken')
          .set(token);
      
      if (kDebugMode) {
        print('✅ FCM token saved: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving FCM token: $e');
      }
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📱 Foreground message: ${message.notification?.title}');
    }

    _showLocalNotification(
      title: message.notification?.title ?? 'Thông báo',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Handle new alerts from database
  void _handleNewAlert(DatabaseEvent event) {
    try {
      final alertData = event.snapshot.value as Map<dynamic, dynamic>?;
      if (alertData == null) return;

      final alert = AirQualityAlert.fromJson(Map<String, dynamic>.from(alertData));
      _showAirQualityAlert(alert);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling alert: $e');
      }
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'air_quality_alerts',
      'Air Quality Alerts',
      channelDescription: 'Notifications for air quality alerts',
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
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show air quality alert notification
  Future<void> _showAirQualityAlert(AirQualityAlert alert) async {
    String title;
    String body;
    
    switch (alert.severity) {
      case AlertSeverity.critical:
        title = '🚨 Cảnh báo nghiêm trọng!';
        break;
      case AlertSeverity.warning:
        title = '⚠️ Cảnh báo chất lượng không khí';
        break;
      case AlertSeverity.info:
        title = 'ℹ️ Thông tin chất lượng không khí';
        break;
    }

    body = '${alert.deviceName}: ${alert.message}';

    await _showLocalNotification(
      title: title,
      body: body,
      payload: alert.toJson().toString(),
      id: alert.hashCode,
    );
  }

  /// Create air quality alert
  Future<void> createAirQualityAlert({
    required String deviceId,
    required String deviceName,
    required AlertType type,
    required AlertSeverity severity,
    required String message,
    required double value,
    required double threshold,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final alert = AirQualityAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        deviceId: deviceId,
        deviceName: deviceName,
        type: type,
        severity: severity,
        message: message,
        value: value,
        threshold: threshold,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _database
          .ref('alerts')
          .child(alert.id)
          .set(alert.toJson());

      if (kDebugMode) {
        print('✅ Alert created: ${alert.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating alert: $e');
      }
    }
  }

  /// Mark alert as read
  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _database
          .ref('alerts')
          .child(alertId)
          .update({'isRead': true});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking alert as read: $e');
      }
    }
  }

  /// Get user alerts
  Stream<List<AirQualityAlert>> getUserAlerts() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _database
        .ref('alerts')
        .orderByChild('userId')
        .equalTo(user.uid)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <AirQualityAlert>[];

      final alerts = <AirQualityAlert>[];
      data.forEach((key, value) {
        try {
          final alertData = Map<String, dynamic>.from(value);
          alertData['id'] = key;
          alerts.add(AirQualityAlert.fromJson(alertData));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing alert: $e');
          }
        }
      });

      // Sort by timestamp descending
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return alerts;
    });
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('📱 Notification tapped: ${response.payload}');
    }
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Dispose resources
  void dispose() {
    _alertSubscription?.cancel();
  }
}

/// Handle background messages
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  if (kDebugMode) {
    print('📱 Background message: ${message.notification?.title}');
  }
}

/// Air Quality Alert Model
class AirQualityAlert {
  final String id;
  final String userId;
  final String deviceId;
  final String deviceName;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final double value;
  final double threshold;
  final DateTime timestamp;
  final bool isRead;

  const AirQualityAlert({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.type,
    required this.severity,
    required this.message,
    required this.value,
    required this.threshold,
    required this.timestamp,
    required this.isRead,
  });

  factory AirQualityAlert.fromJson(Map<String, dynamic> json) {
    return AirQualityAlert(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      deviceId: json['deviceId'] ?? '',
      deviceName: json['deviceName'] ?? '',
      type: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AlertType.other,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
        orElse: () => AlertSeverity.info,
      ),
      message: json['message'] ?? '',
      value: (json['value'] ?? 0.0).toDouble(),
      threshold: (json['threshold'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'message': message,
      'value': value,
      'threshold': threshold,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

enum AlertType {
  highTemperature,
  lowTemperature,
  highHumidity,
  lowHumidity,
  highPM25,
  highPM10,
  highCO2,
  highVOC,
  deviceOffline,
  deviceError,
  batteryLow,
  other,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}
