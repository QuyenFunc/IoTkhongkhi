import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

class BackgroundNotificationService {
  static final BackgroundNotificationService _instance = BackgroundNotificationService._internal();
  factory BackgroundNotificationService() => _instance;
  BackgroundNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _alertSubscription;
  
  bool _isInitialized = false;
  bool _hasNotificationPermission = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        print('📱 BackgroundNotificationService: Initializing...');
      }

      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Start listening to Firebase alerts
      _startListeningToAlerts();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ BackgroundNotificationService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ BackgroundNotificationService: Error initializing: $e');
      }
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Request notification permission
      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.request();
        _hasNotificationPermission = notificationStatus == PermissionStatus.granted;
        
        if (kDebugMode) {
          print('📱 Notification permission: $_hasNotificationPermission');
        }
        
        // Request exact alarm permission for Android 12+
        if (Platform.isAndroid) {
          final alarmStatus = await Permission.scheduleExactAlarm.request();
          if (kDebugMode) {
            print('📱 Exact alarm permission: ${alarmStatus == PermissionStatus.granted}');
          }
        }
      } else {
        _hasNotificationPermission = true;
      }
      
      // Request vibration permission is usually granted by default
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting permissions: $e');
      }
    }
  }

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

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'air_quality_alerts',
        'Air Quality Alerts',
        description: 'Cảnh báo chất lượng không khí từ ESP32',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color.fromARGB(255, 255, 0, 0),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  void _startListeningToAlerts() {
    final database = FirebaseDatabase.instance;
    
    _alertSubscription = database
        .ref('/air_monitor/alert')
        .onValue
        .listen(_handleAlertUpdate);

    if (kDebugMode) {
      print('📱 Started listening to Firebase alerts');
    }
  }

  void _handleAlertUpdate(DatabaseEvent event) async {
    try {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        final isActive = data['active'] as bool? ?? false;
        final reason = data['reason'] as String? ?? '';
        final timestamp = data['timestamp'] as int? ?? 0;
        
        if (isActive && reason.isNotEmpty) {
          if (kDebugMode) {
            print('🚨 Alert received: $reason');
          }
          
          // Show notification
          await _showNotification(reason, timestamp);
          
          // Play sound and vibrate
          await _playAlertSound();
          await _vibrateDevice();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling alert: $e');
      }
    }
  }

  Future<void> _showNotification(String message, int timestamp) async {
    if (!_hasNotificationPermission) {
      if (kDebugMode) {
        print('⚠️ No notification permission, skipping notification');
      }
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'air_quality_alerts',
        'Air Quality Alerts',
        channelDescription: 'Cảnh báo chất lượng không khí từ ESP32',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        // sound: const AndroidNotificationSound.defaultSound,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
        ongoing: true, // Makes notification sticky
        autoCancel: false, // User must manually dismiss
        fullScreenIntent: true, // Show even when screen is locked
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'alarm.wav',
        interruptionLevel: InterruptionLevel.critical,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        timestamp, // Use timestamp as unique ID
        '🚨 Cảnh báo chất lượng không khí',
        message,
        notificationDetails,
        payload: 'alert:$timestamp:$message',
      );

      if (kDebugMode) {
        print('📱 Notification shown: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing notification: $e');
      }
    }
  }

  Future<void> _playAlertSound() async {
    try {
      // Play alarm sound multiple times
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      
      // Wait and play again
      await Future.delayed(const Duration(seconds: 2));
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      
      if (kDebugMode) {
        print('🔊 Alert sound played');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error playing alert sound: $e');
      }
    }
  }

  Future<void> _vibrateDevice() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Strong vibration pattern for emergency alert
        await Vibration.vibrate(
          pattern: [0, 1000, 500, 1000, 500, 1000, 500, 2000],
        );
        
        // Wait and vibrate again
        await Future.delayed(const Duration(seconds: 3));
        await Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 500],
        );
        
        if (kDebugMode) {
          print('📳 Device vibrated');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error vibrating device: $e');
      }
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('📱 Notification tapped: ${response.payload}');
    }
    
    // Handle notification tap - could navigate to specific screen
    if (response.payload != null && response.payload!.startsWith('alert:')) {
      // Extract alert info and navigate to alerts screen
      // This could be implemented to show alert details
    }
  }

  Future<void> testNotification() async {
    await _showNotification(
      'Kiểm tra hệ thống thông báo - ESP32 đang hoạt động bình thường',
      DateTime.now().millisecondsSinceEpoch,
    );
    await _playAlertSound();
    await _vibrateDevice();
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    if (kDebugMode) {
      print('📱 All notifications cancelled');
    }
  }

  void dispose() {
    _alertSubscription?.cancel();
    _audioPlayer.dispose();
    _isInitialized = false;
  }
}
