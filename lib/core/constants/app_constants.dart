class AppConstants {
  // App Information
  static const String appName = 'IoT Air Quality Monitor';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // API Configuration
  static const String baseUrl = 'https://api.iotkhongkhi.com';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Firebase Configuration
  static const String firebaseProjectId = 'iot-air-quality-monitor';
  static const String firebaseDatabaseUrl = 'https://iot-air-quality-monitor-default-rtdb.firebaseio.com/';
  
  // MQTT Configuration
  static const String defaultMqttBroker = 'broker.hivemq.com';
  static const int defaultMqttPort = 1883;
  static const String mqttClientId = 'iot_air_quality_client';
  
  // Device Configuration
  static const Duration deviceOfflineThreshold = Duration(minutes: 5);
  static const Duration dataRefreshInterval = Duration(seconds: 30);
  static const int maxDevicesPerUser = 50;
  
  // Data Thresholds
  static const double defaultMinTemperature = 15.0;
  static const double defaultMaxTemperature = 35.0;
  static const double defaultMinHumidity = 30.0;
  static const double defaultMaxHumidity = 70.0;
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashScreenDuration = Duration(seconds: 3);
  static const int maxRetryAttempts = 3;
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String onboardingKey = 'onboarding_completed';
  
  // Chart Configuration
  static const int maxDataPointsPerChart = 1000;
  static const Duration chartUpdateInterval = Duration(seconds: 5);
  
  // Export Configuration
  static const int maxExportRecords = 10000;
  static const List<String> supportedExportFormats = ['csv', 'pdf'];
  
  // Notification Configuration
  static const String notificationChannelId = 'iot_air_quality_alerts';
  static const String notificationChannelName = 'Air Quality Alerts';
  static const String notificationChannelDescription = 'Notifications for air quality threshold violations';
  
  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxDeviceNameLength = 50;
  static const int maxLocationNameLength = 100;
  
  // Error Messages
  static const String genericErrorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
  static const String networkErrorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.';
  static const String authErrorMessage = 'Lỗi xác thực. Vui lòng đăng nhập lại.';
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm:ss';
  
  // File Paths
  static const String documentsPath = '/storage/emulated/0/Documents/IoTAirQuality';
  static const String exportPath = '/storage/emulated/0/Documents/IoTAirQuality/exports';
  static const String cachePath = '/cache/iot_air_quality';
}

class ApiEndpoints {
  static const String auth = '/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String refreshToken = '$auth/refresh';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  
  static const String devices = '/devices';
  static const String addDevice = '$devices/add';
  static const String updateDevice = '$devices/update';
  static const String deleteDevice = '$devices/delete';
  static const String deviceData = '$devices/data';
  
  static const String users = '/users';
  static const String profile = '$users/profile';
  static const String updateProfile = '$users/update';
  
  static const String groups = '/groups';
  static const String createGroup = '$groups/create';
  static const String joinGroup = '$groups/join';
  static const String leaveGroup = '$groups/leave';
  
  static const String notifications = '/notifications';
  static const String sendNotification = '$notifications/send';
  static const String markAsRead = '$notifications/read';
}

class DatabaseTables {
  static const String users = 'users';
  static const String devices = 'devices';
  static const String sensorData = 'sensor_data';
  static const String alerts = 'alerts';
  static const String groups = 'groups';
  static const String groupMembers = 'group_members';
  static const String settings = 'settings';
  static const String exportHistory = 'export_history';
}

class HiveBoxes {
  static const String userBox = 'user_box';
  static const String deviceBox = 'device_box';
  static const String sensorDataBox = 'sensor_data_box';
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';
}
