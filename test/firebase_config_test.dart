import 'package:flutter_test/flutter_test.dart';
import 'package:air_quality/firebase_options.dart';

void main() {
  group('Firebase Configuration Tests', () {
    test('should have valid Firebase configuration for Android', () {
      final androidOptions = DefaultFirebaseOptions.android;
      
      expect(androidOptions.apiKey, isNotEmpty);
      expect(androidOptions.appId, isNotEmpty);
      expect(androidOptions.messagingSenderId, isNotEmpty);
      expect(androidOptions.projectId, equals('iotsmart-7a145'));
      expect(androidOptions.databaseURL, equals('https://iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app'));
      expect(androidOptions.authDomain, equals('iotsmart-7a145.firebaseapp.com'));
      
      print('✅ Android Firebase configuration is valid');
    });

    test('should have valid Firebase configuration for Web', () {
      final webOptions = DefaultFirebaseOptions.web;
      
      expect(webOptions.apiKey, isNotEmpty);
      expect(webOptions.appId, isNotEmpty);
      expect(webOptions.messagingSenderId, isNotEmpty);
      expect(webOptions.projectId, equals('iotsmart-7a145'));
      expect(webOptions.databaseURL, equals('https://iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app'));
      expect(webOptions.authDomain, equals('iotsmart-7a145.firebaseapp.com'));
      
      print('✅ Web Firebase configuration is valid');
    });

    test('should have consistent project configuration across platforms', () {
      final androidOptions = DefaultFirebaseOptions.android;
      final webOptions = DefaultFirebaseOptions.web;
      
      expect(androidOptions.projectId, equals(webOptions.projectId));
      expect(androidOptions.databaseURL, equals(webOptions.databaseURL));
      expect(androidOptions.authDomain, equals(webOptions.authDomain));
      expect(androidOptions.messagingSenderId, equals(webOptions.messagingSenderId));
      
      print('✅ Cross-platform configuration consistency verified');
    });

    test('should have valid API keys format', () {
      final androidOptions = DefaultFirebaseOptions.android;
      final webOptions = DefaultFirebaseOptions.web;
      
      // Android API key should start with AIza
      expect(androidOptions.apiKey.startsWith('AIza'), isTrue);
      
      // Web API key should start with AIza
      expect(webOptions.apiKey.startsWith('AIza'), isTrue);
      
      // API keys should be different for different platforms
      expect(androidOptions.apiKey, isNot(equals(webOptions.apiKey)));
      
      print('✅ API keys format validation passed');
    });

    test('should have valid App IDs format', () {
      final androidOptions = DefaultFirebaseOptions.android;
      final webOptions = DefaultFirebaseOptions.web;
      
      // Android App ID should contain android
      expect(androidOptions.appId.contains('android'), isTrue);
      
      // Web App ID should contain web
      expect(webOptions.appId.contains('web'), isTrue);
      
      // Both should start with project number
      expect(androidOptions.appId.startsWith('1:537162740770:'), isTrue);
      expect(webOptions.appId.startsWith('1:537162740770:'), isTrue);
      
      print('✅ App IDs format validation passed');
    });
  });
}
