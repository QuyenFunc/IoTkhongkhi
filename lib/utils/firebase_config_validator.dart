import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Utility class to validate Firebase configuration
class FirebaseConfigValidator {
  static bool validateConfiguration() {
    if (kDebugMode) {
      print('🔥 Validating Firebase Configuration...');
    }

    bool isValid = true;
    List<String> issues = [];

    // Get current platform options
    final options = DefaultFirebaseOptions.currentPlatform;

    // Validate API Key
    if (options.apiKey.contains('YOUR_') ||
        options.apiKey.contains('demo-') ||
        options.apiKey.contains('WEB_API_KEY_FROM_FIREBASE_CONSOLE')) {
      issues.add('❌ API Key is still using demo/placeholder value');
      isValid = false;
    } else if (options.apiKey.length < 30) {
      issues.add('❌ API Key seems too short');
      isValid = false;
    } else if (!options.apiKey.startsWith('AIza')) {
      issues.add('❌ API Key format seems incorrect (should start with "AIza")');
      isValid = false;
    } else {
      if (kDebugMode) print('✅ API Key looks valid: ${options.apiKey.substring(0, 10)}...');
    }

    // Validate Project ID
    if (options.projectId.contains('your-project') || options.projectId.contains('demo')) {
      issues.add('❌ Project ID is still using demo/placeholder value');
      isValid = false;
    } else {
      if (kDebugMode) print('✅ Project ID looks valid: ${options.projectId}');
    }

    // Validate App ID
    if (options.appId.contains('YOUR_') || options.appId.contains('demo')) {
      issues.add('❌ App ID is still using demo/placeholder value');
      isValid = false;
    } else if (!options.appId.startsWith('1:')) {
      issues.add('❌ App ID format seems incorrect (should start with "1:")');
      isValid = false;
    } else {
      if (kDebugMode) print('✅ App ID looks valid');
    }

    // Validate Sender ID
    if (options.messagingSenderId.contains('YOUR_') || options.messagingSenderId.length < 10) {
      issues.add('❌ Messaging Sender ID is invalid');
      isValid = false;
    } else {
      if (kDebugMode) print('✅ Messaging Sender ID looks valid');
    }

    // Validate Auth Domain
    if (options.authDomain?.contains('your-project') == true ||
        options.authDomain?.contains('demo') == true) {
      issues.add('❌ Auth Domain is still using demo/placeholder value');
      isValid = false;
    } else if (options.authDomain?.endsWith('.firebaseapp.com') != true) {
      issues.add('❌ Auth Domain format seems incorrect');
      isValid = false;
    } else {
      if (kDebugMode) print('✅ Auth Domain looks valid');
    }

    // Validate Database URL
    if (options.databaseURL?.contains('your-project') == true || 
        options.databaseURL?.contains('demo') == true) {
      issues.add('❌ Database URL is still using demo/placeholder value');
      isValid = false;
    } else if (options.databaseURL?.contains('-default-rtdb.') != true) {
      issues.add('❌ Database URL format seems incorrect');
      isValid = false;
    } else {
      if (kDebugMode) print('✅ Database URL looks valid');
    }

    // Validate Storage Bucket
    if (options.storageBucket?.contains('your-project') == true ||
        options.storageBucket?.contains('demo') == true) {
      issues.add('❌ Storage Bucket is still using demo/placeholder value');
      isValid = false;
    } else if (options.storageBucket?.endsWith('.appspot.com') != true &&
               options.storageBucket?.endsWith('.firebasestorage.app') != true) {
      issues.add('❌ Storage Bucket format seems incorrect');
      isValid = false;
    } else {
      if (kDebugMode) print('✅ Storage Bucket looks valid');
    }

    // Platform-specific validation
    if (kIsWeb) {
      _validateWebConfig(options, issues);
    } else {
      _validateAndroidConfig(options, issues);
    }

    // Print results
    if (kDebugMode) {
      print('\n🔥 Firebase Configuration Validation Results:');
      print('Platform: ${kIsWeb ? 'Web' : 'Android'}');
      print('Status: ${isValid ? '✅ VALID' : '❌ INVALID'}');
      
      if (issues.isNotEmpty) {
        print('\n⚠️ Issues found:');
        for (String issue in issues) {
          print('  $issue');
        }
        print('\n📋 Please check firebase_config_helper.md for setup instructions');
      } else {
        print('🎉 All configuration looks good!');
      }
    }

    return isValid;
  }

  static void _validateWebConfig(FirebaseOptions options, List<String> issues) {
    // Web-specific validations
    if (kDebugMode) print('🌐 Validating Web-specific configuration...');
    
    // Check measurement ID if present
    if (options.measurementId != null && options.measurementId!.contains('YOUR_')) {
      issues.add('❌ Measurement ID is using placeholder value');
    }
  }

  static void _validateAndroidConfig(FirebaseOptions options, List<String> issues) {
    // Android-specific validations
    if (kDebugMode) print('📱 Validating Android-specific configuration...');
    
    // Check Android Client ID
    if (options.androidClientId?.contains('YOUR_') == true) {
      issues.add('❌ Android Client ID is using placeholder value');
    } else if (options.androidClientId?.endsWith('.apps.googleusercontent.com') != true) {
      issues.add('❌ Android Client ID format seems incorrect');
    }
  }

  /// Quick check method for use in main app
  static void quickCheck() {
    if (kDebugMode) {
      final isValid = validateConfiguration();
      if (!isValid) {
        print('\n🚨 WARNING: Firebase configuration has issues!');
        print('📋 Check firebase_config_helper.md for setup instructions');
      }
    }
  }

  /// Get configuration summary
  static Map<String, String> getConfigSummary() {
    final options = DefaultFirebaseOptions.currentPlatform;
    
    return {
      'Platform': kIsWeb ? 'Web' : 'Android',
      'Project ID': options.projectId,
      'Auth Domain': options.authDomain ?? 'Not set',
      'API Key': '${options.apiKey.substring(0, 10)}...',
      'App ID': options.appId,
      'Database URL': options.databaseURL ?? 'Not set',
      'Storage Bucket': options.storageBucket ?? 'Not set',
    };
  }
}
