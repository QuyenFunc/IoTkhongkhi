import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android Configuration Tests', () {
    test('should have correct google-services.json configuration', () async {
      // Read google-services.json file
      final file = File('android/app/google-services.json');
      expect(file.existsSync(), isTrue, reason: 'google-services.json should exist');

      final content = await file.readAsString();
      final config = jsonDecode(content) as Map<String, dynamic>;

      // Check project info
      final projectInfo = config['project_info'] as Map<String, dynamic>;
      expect(projectInfo['project_id'], equals('iotsmart-7a145'));
      expect(projectInfo['project_number'], equals('537162740770'));

      // Check if firebase_url is present and correct
      expect(projectInfo.containsKey('firebase_url'), isTrue, 
        reason: 'firebase_url should be present in project_info');
      
      final firebaseUrl = projectInfo['firebase_url'] as String;
      expect(firebaseUrl, contains('asia-southeast1'), 
        reason: 'firebase_url should contain asia-southeast1 region');
      expect(firebaseUrl, contains('iotsmart-7a145-default-rtdb'), 
        reason: 'firebase_url should contain correct database name');
      expect(firebaseUrl, endsWith('firebasedatabase.app'), 
        reason: 'firebase_url should use new firebasedatabase.app domain');

      print('✅ google-services.json configuration is correct');
      print('Firebase URL: $firebaseUrl');
    });

    test('should not use old firebaseio.com domain in google-services.json', () async {
      final file = File('android/app/google-services.json');
      final content = await file.readAsString();
      
      expect(content, isNot(contains('firebaseio.com')), 
        reason: 'google-services.json should not contain old firebaseio.com domain');
      
      print('✅ Old firebaseio.com domain is not used in google-services.json');
    });

    test('should have correct client configuration', () async {
      final file = File('android/app/google-services.json');
      final content = await file.readAsString();
      final config = jsonDecode(content) as Map<String, dynamic>;

      // Check client array
      final clients = config['client'] as List;
      expect(clients.isNotEmpty, isTrue, reason: 'Should have at least one client');

      final client = clients.first as Map<String, dynamic>;
      final clientInfo = client['client_info'] as Map<String, dynamic>;
      
      // Check app ID
      expect(clientInfo['mobilesdk_app_id'], contains('1:537162740770:android:'));
      
      // Check package name
      final androidClientInfo = clientInfo['android_client_info'] as Map<String, dynamic>;
      expect(androidClientInfo['package_name'], equals('iot.app.air'));

      // Check API key
      final apiKeys = client['api_key'] as List;
      expect(apiKeys.isNotEmpty, isTrue, reason: 'Should have at least one API key');
      
      final apiKey = apiKeys.first as Map<String, dynamic>;
      expect(apiKey['current_key'], startsWith('AIza'), 
        reason: 'API key should start with AIza');

      print('✅ Client configuration is correct');
    });

    test('should have valid JSON structure', () async {
      final file = File('android/app/google-services.json');
      final content = await file.readAsString();
      
      // Should be able to parse as JSON without errors
      expect(() => jsonDecode(content), returnsNormally, 
        reason: 'google-services.json should be valid JSON');
      
      final config = jsonDecode(content) as Map<String, dynamic>;
      
      // Check required top-level keys
      expect(config.containsKey('project_info'), isTrue);
      expect(config.containsKey('client'), isTrue);
      expect(config.containsKey('configuration_version'), isTrue);
      
      print('✅ JSON structure is valid');
    });

    test('should match expected database URL format', () async {
      final file = File('android/app/google-services.json');
      final content = await file.readAsString();
      final config = jsonDecode(content) as Map<String, dynamic>;

      final projectInfo = config['project_info'] as Map<String, dynamic>;
      final firebaseUrl = projectInfo['firebase_url'] as String;
      
      final expectedUrl = 'https://iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app';
      expect(firebaseUrl, equals(expectedUrl), 
        reason: 'firebase_url should match expected format');
      
      // Parse URL to validate structure
      final uri = Uri.parse(firebaseUrl);
      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app'));
      
      print('✅ Database URL format is correct');
      print('Expected: $expectedUrl');
      print('Actual: $firebaseUrl');
    });
  });
}
