import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart'; // Not needed
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/voice_command.dart' show VoiceCommandPattern, VoiceIntent;
import '../models/air_quality_response.dart';

class VoiceAssistantService {
  static final VoiceAssistantService _instance = VoiceAssistantService._internal();
  factory VoiceAssistantService() => _instance;
  VoiceAssistantService._internal();

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastWords = '';
  
  // Stream controllers
  final StreamController<String> _speechController = StreamController<String>.broadcast();
  final StreamController<VoiceAssistantState> _stateController = StreamController<VoiceAssistantState>.broadcast();

  // Getters for streams
  Stream<String> get speechStream => _speechController.stream;
  Stream<VoiceAssistantState> get stateStream => _stateController.stream;

  // Voice commands patterns
  final List<VoiceCommandPattern> _commandPatterns = [
    VoiceCommandPattern(
      patterns: [
        'chất lượng không khí',
        'quality air',
        'air quality',
        'không khí thế nào',
        'không khí như nào',
        'chất lượng kk',
      ],
      intent: VoiceIntent.getAirQuality,
    ),
    VoiceCommandPattern(
      patterns: [
        'nhiệt độ',
        'temperature',
        'bao nhiêu độ',
        'độ c',
        'celsius',
      ],
      intent: VoiceIntent.getTemperature,
    ),
    VoiceCommandPattern(
      patterns: [
        'độ ẩm',
        'humidity',
        'ẩm độ',
        'humid',
      ],
      intent: VoiceIntent.getHumidity,
    ),
    VoiceCommandPattern(
      patterns: [
        'pm2.5',
        'pm 2.5',
        'bụi mịn',
        'particulate matter',
        'dust',
      ],
      intent: VoiceIntent.getPM25,
    ),
    VoiceCommandPattern(
      patterns: [
        'trạng thái thiết bị',
        'device status',
        'esp32',
        'thiết bị',
        'kết nối',
      ],
      intent: VoiceIntent.getDeviceStatus,
    ),
    VoiceCommandPattern(
      patterns: [
        'cảnh báo',
        'alerts',
        'warning',
        'nguy hiểm',
        'báo động',
      ],
      intent: VoiceIntent.getAlerts,
    ),
    VoiceCommandPattern(
      patterns: [
        'tất cả',
        'all data',
        'toàn bộ',
        'everything',
        'báo cáo',
        'report',
      ],
      intent: VoiceIntent.getFullReport,
    ),
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        print('🎤 VoiceAssistantService: Initializing...');
      }

      // Request permissions
      await _requestPermissions();

      // Initialize Speech-to-Text
      await _initializeSpeechToText();

      // Initialize Text-to-Speech
      await _initializeTextToSpeech();

      _isInitialized = true;
      _stateController.add(VoiceAssistantState.ready);

      if (kDebugMode) {
        print('✅ VoiceAssistantService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ VoiceAssistantService: Error initializing: $e');
      }
      _stateController.add(VoiceAssistantState.error);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        throw Exception('Microphone permission not granted');
      }

      if (kDebugMode) {
        print('🎤 Microphone permission granted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error requesting permissions: $e');
      }
      rethrow;
    }
  }

  Future<void> _initializeSpeechToText() async {
    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          if (kDebugMode) {
            print('🎤 Speech status: $status');
          }
          _updateStateFromSpeechStatus(status);
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ Speech error: $error');
          }
          _stateController.add(VoiceAssistantState.error);
        },
      );

      if (!available) {
        throw Exception('Speech recognition not available');
      }

      if (kDebugMode) {
        print('🎤 Speech-to-Text initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Speech-to-Text: $e');
      }
      rethrow;
    }
  }

  Future<void> _initializeTextToSpeech() async {
    try {
      // Configure TTS settings
      await _flutterTts.setLanguage('vi-VN'); // Vietnamese
      await _flutterTts.setSpeechRate(0.8);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Set TTS handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _stateController.add(VoiceAssistantState.speaking);
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _stateController.add(VoiceAssistantState.ready);
      });

      _flutterTts.setErrorHandler((message) {
        if (kDebugMode) {
          print('❌ TTS Error: $message');
        }
        _isSpeaking = false;
        _stateController.add(VoiceAssistantState.error);
      });

      if (kDebugMode) {
        print('🔊 Text-to-Speech initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Text-to-Speech: $e');
      }
      rethrow;
    }
  }

  void _updateStateFromSpeechStatus(String status) {
    switch (status) {
      case 'listening':
        _stateController.add(VoiceAssistantState.listening);
        break;
      case 'notListening':
        _stateController.add(VoiceAssistantState.ready);
        break;
      case 'done':
        _stateController.add(VoiceAssistantState.processing);
        break;
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized || _isListening || _isSpeaking) return;

    try {
      _isListening = true;
      _lastWords = '';
      _stateController.add(VoiceAssistantState.listening);

      await _speechToText.listen(
        onResult: (result) async {
          _lastWords = result.recognizedWords.toLowerCase();
          _speechController.add(_lastWords);

          if (result.finalResult) {
            _isListening = false;
            await _processVoiceCommand(_lastWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: Platform.isIOS ? 'vi_VN' : 'vi-VN',
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );

      if (kDebugMode) {
        print('🎤 Started listening...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting listening: $e');
      }
      _isListening = false;
      _stateController.add(VoiceAssistantState.error);
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      _stateController.add(VoiceAssistantState.ready);

      if (kDebugMode) {
        print('🎤 Stopped listening');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping listening: $e');
      }
    }
  }

  Future<void> _processVoiceCommand(String command) async {
    try {
      _stateController.add(VoiceAssistantState.processing);

      if (kDebugMode) {
        print('🤖 Processing command: $command');
      }

      // Find matching command pattern
      final intent = _findIntent(command);
      if (intent == null) {
        await _speak('Xin lỗi, tôi không hiểu câu hỏi của bạn. Hãy thử hỏi về chất lượng không khí, nhiệt độ, độ ẩm, hoặc trạng thái thiết bị.');
        return;
      }

      // Get air quality data from Firebase
      final airQualityData = await _getAirQualityData();
      if (airQualityData == null) {
        await _speak('Không thể lấy dữ liệu từ thiết bị. Vui lòng kiểm tra kết nối ESP32.');
        return;
      }

      // Generate response based on intent
      final response = _generateResponse(intent, airQualityData);
      await _speak(response);

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing voice command: $e');
      }
      await _speak('Đã xảy ra lỗi khi xử lý yêu cầu của bạn.');
      _stateController.add(VoiceAssistantState.error);
    }
  }

  VoiceIntent? _findIntent(String command) {
    final normalizedCommand = command.toLowerCase().trim();
    
    for (final pattern in _commandPatterns) {
      for (final patternText in pattern.patterns) {
        if (normalizedCommand.contains(patternText.toLowerCase())) {
          return pattern.intent;
        }
      }
    }
    
    return null;
  }

  Future<AirQualityResponse?> _getAirQualityData() async {
    try {
      // Ensure anonymous auth for Firebase access
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        if (kDebugMode) {
          print('✅ Signed in anonymously for Firebase access');
        }
      }

      if (kDebugMode) {
        print('🔄 Fetching air quality data from Firebase...');
      }

      // Get current sensor data  
      final sensorSnapshot = await _database.ref('/air_monitor/latest_data').get();
      
      // Get device status
      final statusSnapshot = await _database.ref('/air_monitor/status').get();
      
      // Get alerts
      final alertSnapshot = await _database.ref('/air_monitor/alert').get();

      if (!sensorSnapshot.exists || !statusSnapshot.exists) {
        return null;
      }

      final sensorData = Map<String, dynamic>.from(sensorSnapshot.value as Map);
      final statusData = Map<String, dynamic>.from(statusSnapshot.value as Map);
      
      Map<String, dynamic>? alertData;
      if (alertSnapshot.exists) {
        alertData = Map<String, dynamic>.from(alertSnapshot.value as Map);
      }

      return AirQualityResponse(
        temperature: (sensorData['temperature'] as num?)?.toDouble() ?? 0.0,
        humidity: (sensorData['humidity'] as num?)?.toDouble() ?? 0.0,
        pm25: (sensorData['pm25'] as num?)?.toDouble() ?? 0.0,
        isOnline: statusData['is_online'] as bool? ?? false,
        lastSeen: statusData['last_seen'] as int? ?? 0,
        deviceId: statusData['device_id'] as String? ?? 'Unknown',
        hasAlert: alertData?['active'] as bool? ?? false,
        alertReason: alertData?['reason'] as String?,
        timestamp: sensorData['timestamp'] as int? ?? 0,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting air quality data: $e');
      }
      return null;
    }
  }

  String _generateResponse(VoiceIntent intent, AirQualityResponse data) {
    switch (intent) {
      case VoiceIntent.getAirQuality:
        return _generateAirQualityResponse(data);
      case VoiceIntent.getTemperature:
        return 'Nhiệt độ hiện tại là ${data.temperature.toStringAsFixed(1)} độ C.';
      case VoiceIntent.getHumidity:
        return 'Độ ẩm hiện tại là ${data.humidity.toStringAsFixed(1)} phần trăm.';
      case VoiceIntent.getPM25:
        return _generatePM25Response(data);
      case VoiceIntent.getDeviceStatus:
        return _generateDeviceStatusResponse(data);
      case VoiceIntent.getAlerts:
        return _generateAlertsResponse(data);
      case VoiceIntent.getFullReport:
        return _generateFullReport(data);
      case VoiceIntent.unknown:
        return 'Xin lỗi, tôi không hiểu yêu cầu của bạn. Hãy thử hỏi về chất lượng không khí, nhiệt độ, độ ẩm hoặc trạng thái thiết bị.';
    }
  }

  String _generateAirQualityResponse(AirQualityResponse data) {
    String quality;
    if (data.pm25 <= 12) {
      quality = 'tốt';
    } else if (data.pm25 <= 35) {
      quality = 'trung bình';
    } else if (data.pm25 <= 55) {
      quality = 'kém';
    } else {
      quality = 'rất kém';
    }

    return 'Chất lượng không khí hiện tại $quality. '
           'Nhiệt độ ${data.temperature.toStringAsFixed(1)} độ C, '
           'độ ẩm ${data.humidity.toStringAsFixed(1)} phần trăm, '
           'và chỉ số PM2.5 là ${data.pm25.toStringAsFixed(1)} microgram trên mét khối.';
  }

  String _generatePM25Response(AirQualityResponse data) {
    String level;
    String advice;
    
    if (data.pm25 <= 12) {
      level = 'rất tốt';
      advice = 'An toàn cho mọi hoạt động ngoài trời.';
    } else if (data.pm25 <= 35) {
      level = 'tốt';
      advice = 'Có thể hoạt động bình thường.';
    } else if (data.pm25 <= 55) {
      level = 'trung bình';
      advice = 'Những người nhạy cảm nên hạn chế hoạt động ngoài trời.';
    } else if (data.pm25 <= 150) {
      level = 'kém';
      advice = 'Nên đeo khẩu trang khi ra ngoài.';
    } else {
      level = 'rất kém';
      advice = 'Không nên ra ngoài trừ khi cần thiết.';
    }

    return 'Chỉ số PM2.5 hiện tại là ${data.pm25.toStringAsFixed(1)} microgram trên mét khối, mức độ $level. $advice';
  }

  String _generateDeviceStatusResponse(AirQualityResponse data) {
    if (!data.isOnline) {
      return 'Thiết bị ESP32 hiện đang ngoại tuyến. Vui lòng kiểm tra kết nối mạng.';
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastSeenMs = data.lastSeen < 2000000000 ? data.lastSeen * 1000 : data.lastSeen;
    final timeDiff = now - lastSeenMs;

    if (timeDiff < 60000) {
      return 'Thiết bị ESP32 đang hoạt động bình thường và vừa gửi dữ liệu.';
    } else if (timeDiff < 300000) {
      return 'Thiết bị ESP32 đang trực tuyến, lần gửi dữ liệu cuối cách đây ${(timeDiff / 60000).round()} phút.';
    } else {
      return 'Thiết bị ESP32 có vấn đề về kết nối, đã lâu không gửi dữ liệu.';
    }
  }

  String _generateAlertsResponse(AirQualityResponse data) {
    if (!data.hasAlert) {
      return 'Hiện tại không có cảnh báo nào. Tất cả các chỉ số đều ở mức bình thường.';
    }

    return 'Có cảnh báo: ${data.alertReason ?? "Chỉ số vượt ngưỡng cho phép"}. Vui lòng kiểm tra và thực hiện biện pháp cần thiết.';
  }

  String _generateFullReport(AirQualityResponse data) {
    final statusText = data.isOnline ? 'trực tuyến' : 'ngoại tuyến';
    final alertText = data.hasAlert ? 'Có cảnh báo: ${data.alertReason}' : 'Không có cảnh báo';
    
    return 'Báo cáo tổng quan: Nhiệt độ ${data.temperature.toStringAsFixed(1)} độ C, '
           'độ ẩm ${data.humidity.toStringAsFixed(1)} phần trăm, '
           'PM2.5 ${data.pm25.toStringAsFixed(1)} microgram trên mét khối. '
           'Thiết bị đang $statusText. $alertText.';
  }

  Future<void> _speak(String text) async {
    try {
      if (_isSpeaking) {
        await _flutterTts.stop();
      }

      await _flutterTts.speak(text);

      if (kDebugMode) {
        print('🔊 Speaking: $text');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error speaking: $e');
      }
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _stateController.add(VoiceAssistantState.ready);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping speech: $e');
      }
    }
  }

  // Quick commands for common queries
  Future<void> quickAirQualityCheck() async {
    await _processVoiceCommand('chất lượng không khí');
  }

  Future<void> quickTemperatureCheck() async {
    await _processVoiceCommand('nhiệt độ');
  }

  Future<void> quickHumidityCheck() async {
    await _processVoiceCommand('độ ẩm');
  }

  Future<void> quickPM25Check() async {
    await _processVoiceCommand('pm2.5');
  }

  Future<void> quickDeviceStatus() async {
    await _processVoiceCommand('trạng thái thiết bị');
  }

  Future<void> quickAlertsCheck() async {
    await _processVoiceCommand('cảnh báo');
  }

  Future<void> quickFullReport() async {
    await _processVoiceCommand('báo cáo tổng quan');
  }

  // Public method to process any voice command
  Future<void> processCommand(String command) async {
    await _processVoiceCommand(command);
  }

  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;

  void dispose() {
    _speechController.close();
    _stateController.close();
    _flutterTts.stop();
    _speechToText.stop();
    _isInitialized = false;
  }
}

// VoiceCommandPattern is now imported from voice_command.dart

// Voice assistant states
enum VoiceAssistantState {
  ready,
  listening,
  processing,
  speaking,
  error,
}
