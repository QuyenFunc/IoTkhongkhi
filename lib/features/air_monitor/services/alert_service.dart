import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../screens/fullscreen_alert_screen.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();
  
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  StreamSubscription? _alertSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlertActive = false;
  
  void startListening(BuildContext context) {
    _alertSubscription = _database.ref('/air_monitor/alert').onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final isActive = data['active'] as bool? ?? false;
        final reason = data['reason'] as String? ?? '';
        
        if (isActive && !_isAlertActive) {
          _showFullscreenAlert(context, reason);
        } else if (!isActive && _isAlertActive) {
          _dismissAlert();
        }
      }
    });
  }
  
  void _showFullscreenAlert(BuildContext context, String reason) {
    _isAlertActive = true;
    
    // Start vibration pattern
    _startVibration();
    
    // Play alarm sound
    _playAlarmSound();
    
    // Show fullscreen alert
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullscreenAlertScreen(
            reason: reason,
            onDismiss: () => _dismissAlert(),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }
  
  void _playAlarmSound() async {
    try {
      // Use a simple beep tone since we don't have alarm.mp3
      // You can replace this with a real alarm sound file later
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Try to play system notification sound (requires different approach)
      // For now, just a simple notification
      print('🔊 Playing alarm sound...');
      
      // Fallback: Extend vibration pattern
      _extendedVibration();
    } catch (e) {
      print('Error playing alarm sound: $e');
    }
  }
  
  void _extendedVibration() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Longer vibration pattern for alarm
        Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500, 200, 1000]);
      }
    } catch (e) {
      print('Error extended vibration: $e');
    }
  }
  
  void _startVibration() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [0, 1000, 500, 1000, 500, 1000]);
      }
    } catch (e) {
      print('Error starting vibration: $e');
    }
  }
  
  void _dismissAlert() {
    _isAlertActive = false;
    try {
      Vibration.cancel();
    } catch (e) {
      print('Error canceling vibration: $e');
    }
    _audioPlayer.stop();
  }
  
  void dispose() {
    _alertSubscription?.cancel();
    _audioPlayer.dispose();
  }
}
