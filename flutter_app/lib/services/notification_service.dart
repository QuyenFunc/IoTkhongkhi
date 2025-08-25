import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/alert_model.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Current user ID
  String? get userId => _auth.currentUser?.uid;
  
  // Database references
  DatabaseReference get _alertsRef => _database.ref('alerts');
  DatabaseReference get _usersRef => _database.ref('users');
  
  // Current alerts
  List<AlertModel> _alerts = [];
  List<AlertModel> get alerts => _alerts;
  
  // Unread alerts count
  int get unreadAlertsCount => _alerts.where((alert) => !alert.acknowledged).length;
  
  // Critical alerts count
  int get criticalAlertsCount => _alerts.where((alert) => 
      alert.severity == AlertSeverity.critical && !alert.acknowledged).length;
  
  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  // Permissions
  bool _notificationsEnabled = false;
  bool get notificationsEnabled => _notificationsEnabled;
  
  // Subscription
  StreamSubscription? _alertsSubscription;
  
  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Initialize notification service
  Future<void> initialize() async {
    if (userId == null) return;
    
    _setLoading(true);
    _setError(null);
    
    try {
      // Request notification permissions
      await _requestPermissions();
      
      // Setup Firebase Messaging
      await _setupFirebaseMessaging();
      
      // Listen to alerts
      await _listenToAlerts();
      
      // Get FCM token and save to user profile
      await _updateFCMToken();
      
    } catch (e) {
      _setError('Khởi tạo dịch vụ thông báo thất bại: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
      
      _notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized ||
                             settings.authorizationStatus == AuthorizationStatus.provisional;
      
      print('Notification permission status: ${settings.authorizationStatus}');
      notifyListeners();
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }
  
  /// Setup Firebase Messaging handlers
  Future<void> _setupFirebaseMessaging() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });
    
    // Handle background messages (when app is opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageOpenedApp(message);
    });
    
    // Handle messages when app is launched from terminated state
    FirebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessageOpenedApp(message);
      }
    });
  }
  
  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    // You can show local notification here or update UI
    if (message.notification != null) {
      // Create local notification or update UI
      _showLocalNotification(message);
    }
    
    // Refresh alerts if it's an alert message
    if (message.data['type'] == 'alert') {
      _refreshAlerts();
    }
  }
  
  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened from notification: ${message.messageId}');
    
    // Navigate to appropriate screen based on message data
    if (message.data['type'] == 'alert') {
      // Navigate to alerts screen
      // This would require navigation context or a global navigator
    } else if (message.data['type'] == 'device_status') {
      // Navigate to device screen
      String? deviceId = message.data['deviceId'];
      if (deviceId != null) {
        // Navigate to device detail screen
      }
    }
  }
  
  /// Show local notification (you might want to use a local notifications package)
  void _showLocalNotification(RemoteMessage message) {
    // This is a placeholder - you would implement with flutter_local_notifications
    print('Should show local notification: ${message.notification?.title}');
  }
  
  /// Listen to user's alerts
  Future<void> _listenToAlerts() async {
    if (userId == null) return;
    
    _alertsSubscription?.cancel();
    _alertsSubscription = _alertsRef
        .child(userId!)
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue
        .listen((event) {
      _alerts.clear();
      
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> alertsData = event.snapshot.value as Map<dynamic, dynamic>;
        
        alertsData.forEach((key, value) {
          try {
            AlertModel alert = AlertModel.fromJson(Map<String, dynamic>.from(value));
            alert = alert.copyWith(id: key);
            _alerts.add(alert);
          } catch (e) {
            print('Error parsing alert data: $e');
          }
        });
        
        // Sort by timestamp descending (newest first)
        _alerts.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));
      }
      
      notifyListeners();
    });
  }
  
  /// Refresh alerts manually
  Future<void> _refreshAlerts() async {
    // This will automatically trigger through the stream listener
    // But you can force a refresh if needed
  }
  
  /// Update FCM token in user profile
  Future<void> _updateFCMToken() async {
    if (userId == null) return;
    
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _usersRef
            .child(userId!)
            .child('profile')
            .child('fcmToken')
            .set(token);
        
        print('FCM Token updated: $token');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
  
  /// Create and send alert
  Future<bool> createAlert({
    required String deviceId,
    required String type,
    required String message,
    double? value,
    double? threshold,
  }) async {
    if (userId == null) {
      _setError('Người dùng chưa đăng nhập');
      return false;
    }
    
    try {
      AlertModel alert = AlertModel(
        deviceId: deviceId,
        type: type,
        message: message,
        value: value,
        threshold: threshold,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        acknowledged: false,
      );
      
      await _alertsRef
          .child(userId!)
          .push()
          .set(alert.toJson());
      
      // Send push notification if enabled
      if (_notificationsEnabled) {
        await _sendPushNotification(alert);
      }
      
      return true;
    } catch (e) {
      _setError('Tạo cảnh báo thất bại: $e');
      return false;
    }
  }
  
  /// Send push notification for alert
  Future<void> _sendPushNotification(AlertModel alert) async {
    try {
      // This would typically be done from your backend/cloud functions
      // For demo purposes, we're just logging
      print('Would send push notification for alert: ${alert.message}');
      
      // In a real implementation, you would:
      // 1. Call your backend API
      // 2. Backend would use FCM Admin SDK to send notification
      // 3. Or use Firebase Cloud Functions triggered by database writes
      
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }
  
  /// Acknowledge alert
  Future<bool> acknowledgeAlert(String alertId) async {
    if (userId == null) {
      _setError('Người dùng chưa đăng nhập');
      return false;
    }
    
    try {
      await _alertsRef
          .child(userId!)
          .child(alertId)
          .update({
        'acknowledged': true,
        'acknowledgedAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
      
      return true;
    } catch (e) {
      _setError('Xác nhận cảnh báo thất bại: $e');
      return false;
    }
  }
  
  /// Acknowledge all alerts
  Future<bool> acknowledgeAllAlerts() async {
    if (userId == null) {
      _setError('Người dùng chưa đăng nhập');
      return false;
    }
    
    try {
      List<AlertModel> unacknowledgedAlerts = _alerts
          .where((alert) => !alert.acknowledged && alert.id != null)
          .toList();
      
      for (AlertModel alert in unacknowledgedAlerts) {
        await _alertsRef
            .child(userId!)
            .child(alert.id!)
            .update({
          'acknowledged': true,
          'acknowledgedAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }
      
      return true;
    } catch (e) {
      _setError('Xác nhận tất cả cảnh báo thất bại: $e');
      return false;
    }
  }
  
  /// Delete alert
  Future<bool> deleteAlert(String alertId) async {
    if (userId == null) {
      _setError('Người dùng chưa đăng nhập');
      return false;
    }
    
    try {
      await _alertsRef
          .child(userId!)
          .child(alertId)
          .remove();
      
      return true;
    } catch (e) {
      _setError('Xóa cảnh báo thất bại: $e');
      return false;
    }
  }
  
  /// Clear all alerts
  Future<bool> clearAllAlerts() async {
    if (userId == null) {
      _setError('Người dùng chưa đăng nhập');
      return false;
    }
    
    try {
      await _alertsRef
          .child(userId!)
          .remove();
      
      _alerts.clear();
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError('Xóa tất cả cảnh báo thất bại: $e');
      return false;
    }
  }
  
  /// Get alerts by severity
  List<AlertModel> getAlertsBySeverity(AlertSeverity severity) {
    return _alerts.where((alert) => alert.severity == severity).toList();
  }
  
  /// Get alerts by category
  List<AlertModel> getAlertsByCategory(AlertCategory category) {
    return _alerts.where((alert) => alert.category == category).toList();
  }
  
  /// Get alerts by device
  List<AlertModel> getAlertsByDevice(String deviceId) {
    return _alerts.where((alert) => alert.deviceId == deviceId).toList();
  }
  
  /// Get unacknowledged alerts
  List<AlertModel> get unacknowledgedAlerts {
    return _alerts.where((alert) => !alert.acknowledged).toList();
  }
  
  /// Get recent alerts (last 24 hours)
  List<AlertModel> get recentAlerts {
    int yesterday = DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch ~/ 1000;
    return _alerts.where((alert) => (alert.timestamp ?? 0) > yesterday).toList();
  }
  
  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    
    if (enabled) {
      await _requestPermissions();
    }
  }
  
  /// Subscribe to topic for general notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }
  
  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}
