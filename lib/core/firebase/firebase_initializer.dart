import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../firebase_options.dart';

class FirebaseInitializer {
  static bool _isInitialized = false;

  /// Initialize Firebase with proper configuration
  static Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('🔥 Firebase already initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔥 Initializing Firebase...');
      }

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Force set database URL for Android to ensure correct region
      if (kDebugMode) {
        print('🔥 Setting up Firebase Database with correct region...');
      }

      // Get the correct database URL
      final databaseURL = DefaultFirebaseOptions.currentPlatform.databaseURL;
      if (kDebugMode) {
        print('🔥 Database URL: $databaseURL');
      }

      // Verify the URL is correct
      if (databaseURL != null && databaseURL.contains('asia-southeast1')) {
        if (kDebugMode) {
          print('✅ Database URL is correctly configured for Asia Southeast region');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Database URL might not be correctly configured');
          print('Expected: asia-southeast1 region');
          print('Actual: $databaseURL');
        }
      }

      // Test database connection
      await _testDatabaseConnection();

      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Firebase initialization completed successfully');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Test database connection
  static Future<void> _testDatabaseConnection() async {
    try {
      if (kDebugMode) {
        print('🧪 Testing database connection...');
      }

      final database = FirebaseDatabase.instance;
      
      // Get database URL from instance
      final dbUrl = database.app.options.databaseURL;
      if (kDebugMode) {
        print('🔗 Database instance URL: $dbUrl');
      }

      // Try to connect to database
      final ref = database.ref('test_connection');
      await ref.set({
        'timestamp': DateTime.now().toIso8601String(),
        'test': true,
      });

      if (kDebugMode) {
        print('✅ Database connection test successful');
      }

      // Clean up test data
      await ref.remove();

    } catch (e) {
      if (kDebugMode) {
        print('❌ Database connection test failed: $e');
        
        // Check if it's a region error
        if (e.toString().contains('different region')) {
          print('🚨 REGION ERROR DETECTED!');
          print('The database is in a different region than configured.');
          print('Expected URL: https://iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app');
        }
      }
      // Don't rethrow here - let the app continue but log the error
    }
  }

  /// Get current Firebase configuration info
  static Map<String, dynamic> getConfigInfo() {
    try {
      final app = Firebase.app();
      final options = app.options;
      
      return {
        'appId': options.appId,
        'projectId': options.projectId,
        'databaseURL': options.databaseURL,
        'authDomain': options.authDomain,
        'storageBucket': options.storageBucket,
        'messagingSenderId': options.messagingSenderId,
        'apiKey': options.apiKey,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Print current configuration
  static void printConfigInfo() {
    if (kDebugMode) {
      print('🔍 Firebase Configuration:');
      final config = getConfigInfo();
      config.forEach((key, value) {
        print('  $key: $value');
      });
    }
  }

  /// Force reinitialize Firebase (for debugging)
  static Future<void> forceReinitialize() async {
    if (kDebugMode) {
      print('🔄 Force reinitializing Firebase...');
    }
    
    _isInitialized = false;
    await initialize();
  }

  /// Check if Firebase is properly initialized
  static bool get isInitialized => _isInitialized;

  /// Validate database URL
  static bool validateDatabaseURL() {
    try {
      final databaseURL = DefaultFirebaseOptions.currentPlatform.databaseURL;
      
      if (databaseURL == null) {
        if (kDebugMode) {
          print('❌ Database URL is null');
        }
        return false;
      }

      final expectedURL = 'https://iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app';
      final isValid = databaseURL == expectedURL;

      if (kDebugMode) {
        print('🔍 Database URL validation:');
        print('  Expected: $expectedURL');
        print('  Actual: $databaseURL');
        print('  Valid: $isValid');
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error validating database URL: $e');
      }
      return false;
    }
  }
}
