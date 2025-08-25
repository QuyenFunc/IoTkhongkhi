import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  group('Database Rules Tests', () {
    test('should have development rules file', () {
      final devRulesFile = File('firebase/database.rules.dev.json');
      expect(devRulesFile.existsSync(), isTrue, 
        reason: 'Development rules file should exist');

      final content = devRulesFile.readAsStringSync();
      expect(content, contains('"auth != null"'), 
        reason: 'Development rules should require authentication');
      
      print('✅ Development rules file exists and requires auth');
    });

    test('should have production rules file', () {
      final prodRulesFile = File('firebase/database.rules.json');
      expect(prodRulesFile.existsSync(), isTrue, 
        reason: 'Production rules file should exist');

      final content = prodRulesFile.readAsStringSync();
      expect(content, contains('users'), 
        reason: 'Production rules should have user-specific rules');
      expect(content, contains('\$uid'), 
        reason: 'Production rules should use user ID variables');
      
      print('✅ Production rules file exists with proper structure');
    });

    test('should have proper rules structure', () {
      final prodRulesFile = File('firebase/database.rules.json');
      final content = prodRulesFile.readAsStringSync();

      // Check for required sections
      expect(content, contains('users'), reason: 'Should have users section');
      expect(content, contains('devices'), reason: 'Should have devices section');
      expect(content, contains('sensorData'), reason: 'Should have sensorData section');

      // Check for security patterns
      expect(content, contains('auth.uid'), reason: 'Should check user authentication');
      expect(content, contains('.validate'), reason: 'Should have validation rules');

      print('✅ Production rules have proper security structure');
    });

    test('development rules should be simple and permissive', () {
      final devRulesFile = File('firebase/database.rules.dev.json');
      final content = devRulesFile.readAsStringSync();

      // Should be simple
      expect(content.split('\n').length, lessThan(10), 
        reason: 'Development rules should be simple');

      // Should require auth but be permissive
      expect(content, contains('".read": "auth != null"'), 
        reason: 'Should allow read for authenticated users');
      expect(content, contains('".write": "auth != null"'), 
        reason: 'Should allow write for authenticated users');

      print('✅ Development rules are simple and permissive');
    });

    test('production rules should have user isolation', () {
      final prodRulesFile = File('firebase/database.rules.json');
      final content = prodRulesFile.readAsStringSync();

      // Check user isolation
      expect(content, contains('auth.uid == \$uid'), 
        reason: 'Users should only access their own data');

      // Check validation
      expect(content, contains('newData.hasChildren'), 
        reason: 'Should validate required fields');

      print('✅ Production rules have proper user isolation');
    });
  });
}
