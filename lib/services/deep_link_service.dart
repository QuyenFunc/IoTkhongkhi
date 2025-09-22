import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import '../features/voice_assistant/services/voice_assistant_service.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  
  final StreamController<DeepLinkAction> _actionController = StreamController<DeepLinkAction>.broadcast();
  
  Stream<DeepLinkAction> get actionStream => _actionController.stream;
  
  bool _isInitialized = false;
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        print('🔗 DeepLinkService: Initializing...');
      }

      // Listen for incoming deep links
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) async {
          if (kDebugMode) {
            print('🔗 Received deep link: $uri');
          }
          await _processDeepLink(uri.toString());
        },
        onError: (err) {
          if (kDebugMode) {
            print('❌ Deep link stream error: $err');
          }
        },
      );
      
      // Check for initial deep link (when app is launched via Google Assistant)
      await _checkInitialLink();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ DeepLinkService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ DeepLinkService: Error initializing: $e');
      }
    }
  }

  Future<void> _checkInitialLink() async {
    try {
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        if (kDebugMode) {
          print('🔗 Initial deep link: $initialLink');
        }
        await _processDeepLink(initialLink.toString());
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking initial link: $e');
      }
    }
  }

  Future<void> _processDeepLink(String link) async {
    try {
      final uri = Uri.parse(link);
      
      if (kDebugMode) {
        print('🔗 Processing deep link: $link');
        print('🔗 Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
        print('🔗 Query parameters: ${uri.queryParameters}');
      }

            if (uri.scheme != 'airquality' && uri.scheme != 'https') {
              if (kDebugMode) {
                print('⚠️ Invalid scheme: ${uri.scheme}');
              }
              return;
            }

      final action = _parseDeepLinkAction(uri);
      if (action != null) {
        _actionController.add(action);
        
        // Execute voice response if voice service is available
        await _executeVoiceResponse(action);
        
        if (kDebugMode) {
          print('✅ Deep link action processed: ${action.type}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing deep link: $e');
      }
    }
  }

  DeepLinkAction? _parseDeepLinkAction(Uri uri) {
    final pathSegments = uri.pathSegments;
    
    if (kDebugMode) {
      print('🔍 Parsing URI: $uri');
      print('📂 Path segments: $pathSegments');
      print('🏠 Host: ${uri.host}');
      print('📁 Path: ${uri.path}');
    }
    
    if (pathSegments.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Empty path segments');
      }
      return null;
    }

    // For airquality://main/air_quality, pathSegments = ["air_quality"]
    // The host is already parsed as "main" by Uri.host
    String action = pathSegments[0]; // Take first path segment as action
    
    if (kDebugMode) {
      print('✅ Extracted action: $action');
    }

    switch (action) {
      case 'air_quality':
        return DeepLinkAction(
          type: DeepLinkActionType.getAirQuality,
          parameters: uri.queryParameters,
        );
      case 'temperature':
        return DeepLinkAction(
          type: DeepLinkActionType.getTemperature,
          parameters: uri.queryParameters,
        );
      case 'humidity':
        return DeepLinkAction(
          type: DeepLinkActionType.getHumidity,
          parameters: uri.queryParameters,
        );
      case 'pm25':
        return DeepLinkAction(
          type: DeepLinkActionType.getPM25,
          parameters: uri.queryParameters,
        );
      case 'device_status':
        return DeepLinkAction(
          type: DeepLinkActionType.getDeviceStatus,
          parameters: uri.queryParameters,
        );
      case 'alerts':
        return DeepLinkAction(
          type: DeepLinkActionType.getAlerts,
          parameters: uri.queryParameters,
        );
      case 'dashboard':
        return DeepLinkAction(
          type: DeepLinkActionType.showDashboard,
          parameters: uri.queryParameters,
        );
      case 'check_air_quality':
        return DeepLinkAction(
          type: DeepLinkActionType.checkAirQuality,
          parameters: uri.queryParameters,
        );
      case 'full_report':
        return DeepLinkAction(
          type: DeepLinkActionType.getFullReport,
          parameters: uri.queryParameters,
        );
      default:
        if (kDebugMode) {
          print('⚠️ Unknown action: $action');
        }
        return null;
    }
  }

  Future<void> _executeVoiceResponse(DeepLinkAction action) async {
    try {
      // Initialize voice service if not already done
      if (!_voiceService.isInitialized) {
        await _voiceService.initialize();
      }

      // Execute corresponding voice command
      switch (action.type) {
        case DeepLinkActionType.getAirQuality:
        case DeepLinkActionType.checkAirQuality:
          await _voiceService.quickAirQualityCheck();
          break;
        case DeepLinkActionType.getTemperature:
          await _voiceService.quickTemperatureCheck();
          break;
        case DeepLinkActionType.getHumidity:
          await _voiceService.quickHumidityCheck();
          break;
        case DeepLinkActionType.getPM25:
          await _voiceService.quickPM25Check();
          break;
        case DeepLinkActionType.getDeviceStatus:
          await _voiceService.quickDeviceStatus();
          break;
        case DeepLinkActionType.getAlerts:
          await _voiceService.quickAlertsCheck();
          break;
        case DeepLinkActionType.getFullReport:
          await _voiceService.quickFullReport();
          break;
        case DeepLinkActionType.showDashboard:
          // Just navigate to dashboard, no voice needed
          break;
      }

      if (kDebugMode) {
        print('✅ Voice response executed for action: ${action.type}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error executing voice response: $e');
      }
    }
  }

  // Test method for development
  Future<void> testDeepLink(String link) async {
    await _processDeepLink(link);
  }

  void dispose() {
    _linkSubscription?.cancel();
    _actionController.close();
    _isInitialized = false;
  }
}

class DeepLinkAction {
  final DeepLinkActionType type;
  final Map<String, String> parameters;
  final DateTime timestamp;

  DeepLinkAction({
    required this.type,
    this.parameters = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'DeepLinkAction(type: $type, parameters: $parameters)';
  }
}

enum DeepLinkActionType {
  getAirQuality,
  getTemperature,
  getHumidity,
  getPM25,
  getDeviceStatus,
  getAlerts,
  showDashboard,
  checkAirQuality,
  getFullReport;

  String get displayName {
    switch (this) {
      case DeepLinkActionType.getAirQuality:
        return 'Kiểm tra chất lượng không khí';
      case DeepLinkActionType.getTemperature:
        return 'Xem nhiệt độ';
      case DeepLinkActionType.getHumidity:
        return 'Xem độ ẩm';
      case DeepLinkActionType.getPM25:
        return 'Xem PM2.5';
      case DeepLinkActionType.getDeviceStatus:
        return 'Xem trạng thái thiết bị';
      case DeepLinkActionType.getAlerts:
        return 'Xem cảnh báo';
      case DeepLinkActionType.showDashboard:
        return 'Hiển thị trang chủ';
      case DeepLinkActionType.checkAirQuality:
        return 'Kiểm tra chất lượng không khí';
      case DeepLinkActionType.getFullReport:
        return 'Báo cáo đầy đủ';
    }
  }

  String get route {
    switch (this) {
      case DeepLinkActionType.getAirQuality:
      case DeepLinkActionType.checkAirQuality:
        return '/air_quality';
      case DeepLinkActionType.getTemperature:
      case DeepLinkActionType.getHumidity:
      case DeepLinkActionType.getPM25:
        return '/monitoring';
      case DeepLinkActionType.getDeviceStatus:
        return '/devices';
      case DeepLinkActionType.getAlerts:
        return '/alerts';
      case DeepLinkActionType.showDashboard:
        return '/dashboard';
      case DeepLinkActionType.getFullReport:
        return '/dashboard';
    }
  }
}
