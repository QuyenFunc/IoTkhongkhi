import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firebase Type Conversion Tests', () {
    test('should convert Map<Object?, Object?> to Map<String, dynamic>', () {
      // Simulate Firebase data structure
      final firebaseData = <Object?, Object?>{
        'id': 'test-123',
        'email': 'test@example.com',
        'name': 'Test User',
        'phoneNumber': '+84123456789',
        'isEmailVerified': true,
        'preferences': <Object?, Object?>{
          'language': 'vi',
          'theme': 'system',
          'notificationsEnabled': true,
          'dataRefreshInterval': 30,
        },
      };

      // Convert using our helper method
      final converted = _convertFirebaseData(firebaseData);

      expect(converted, isA<Map<String, dynamic>>());
      expect(converted['id'], equals('test-123'));
      expect(converted['email'], equals('test@example.com'));
      expect(converted['name'], equals('Test User'));
      expect(converted['phoneNumber'], equals('+84123456789'));
      expect(converted['isEmailVerified'], isTrue);
      
      final preferences = converted['preferences'] as Map<String, dynamic>;
      expect(preferences['language'], equals('vi'));
      expect(preferences['theme'], equals('system'));
      expect(preferences['notificationsEnabled'], isTrue);
      expect(preferences['dataRefreshInterval'], equals(30));
      
      print('✅ Firebase data conversion works');
    });

    test('should handle null values correctly', () {
      final firebaseData = <Object?, Object?>{
        'id': 'test-456',
        'email': 'test2@example.com',
        'name': 'Test User 2',
        'phoneNumber': null,
        'profileImageUrl': null,
      };

      final converted = _convertFirebaseData(firebaseData);

      expect(converted['id'], equals('test-456'));
      expect(converted['phoneNumber'], isNull);
      expect(converted['profileImageUrl'], isNull);
      
      print('✅ Null values handling works');
    });

    test('should handle nested objects correctly', () {
      final firebaseData = <Object?, Object?>{
        'user': <Object?, Object?>{
          'profile': <Object?, Object?>{
            'name': 'Nested User',
            'settings': <Object?, Object?>{
              'theme': 'dark',
              'notifications': true,
            },
          },
        },
      };

      final converted = _convertFirebaseData(firebaseData);

      expect(converted['user'], isA<Map<String, dynamic>>());
      final user = converted['user'] as Map<String, dynamic>;
      expect(user['profile'], isA<Map<String, dynamic>>());
      
      final profile = user['profile'] as Map<String, dynamic>;
      expect(profile['name'], equals('Nested User'));
      expect(profile['settings'], isA<Map<String, dynamic>>());
      
      final settings = profile['settings'] as Map<String, dynamic>;
      expect(settings['theme'], equals('dark'));
      expect(settings['notifications'], isTrue);
      
      print('✅ Nested objects conversion works');
    });

    test('should handle arrays correctly', () {
      final firebaseData = <Object?, Object?>{
        'tags': ['tag1', 'tag2', 'tag3'],
        'numbers': [1, 2, 3, 4, 5],
        'mixed': ['string', 123, true, null],
      };

      final converted = _convertFirebaseData(firebaseData);

      expect(converted['tags'], isA<List>());
      expect(converted['tags'], equals(['tag1', 'tag2', 'tag3']));
      
      expect(converted['numbers'], isA<List>());
      expect(converted['numbers'], equals([1, 2, 3, 4, 5]));
      
      expect(converted['mixed'], isA<List>());
      expect(converted['mixed'], equals(['string', 123, true, null]));
      
      print('✅ Arrays conversion works');
    });

    test('should handle empty and edge cases', () {
      // Test empty map
      final emptyData = <Object?, Object?>{};
      final convertedEmpty = _convertFirebaseData(emptyData);
      expect(convertedEmpty, isEmpty);

      // Test null data
      final convertedNull = _convertFirebaseData(null);
      expect(convertedNull, isEmpty);

      // Test already correct type
      final correctData = <String, dynamic>{'key': 'value'};
      final convertedCorrect = _convertFirebaseData(correctData);
      expect(convertedCorrect, equals(correctData));
      
      print('✅ Edge cases handling works');
    });

    test('should handle different primitive types', () {
      final firebaseData = <Object?, Object?>{
        'stringValue': 'hello',
        'intValue': 42,
        'doubleValue': 3.14,
        'boolValue': true,
        'nullValue': null,
      };

      final converted = _convertFirebaseData(firebaseData);

      expect(converted['stringValue'], isA<String>());
      expect(converted['stringValue'], equals('hello'));
      
      expect(converted['intValue'], isA<int>());
      expect(converted['intValue'], equals(42));
      
      expect(converted['doubleValue'], isA<double>());
      expect(converted['doubleValue'], equals(3.14));
      
      expect(converted['boolValue'], isA<bool>());
      expect(converted['boolValue'], isTrue);
      
      expect(converted['nullValue'], isNull);
      
      print('✅ Primitive types conversion works');
    });
  });
}

/// Helper method for testing (copy of the actual implementation)
Map<String, dynamic> _convertFirebaseData(dynamic data) {
  if (data == null) {
    return {};
  }

  if (data is Map<String, dynamic>) {
    return data;
  }

  if (data is Map) {
    // Convert Map<Object?, Object?> to Map<String, dynamic>
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (key != null) {
        result[key.toString()] = _convertFirebaseValue(value);
      }
    });
    return result;
  }

  throw Exception('Unexpected data type from Firebase: ${data.runtimeType}');
}

/// Helper method for testing (copy of the actual implementation)
dynamic _convertFirebaseValue(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is String || value is num || value is bool) {
    return value;
  }

  if (value is Map) {
    final result = <String, dynamic>{};
    value.forEach((key, val) {
      if (key != null) {
        result[key.toString()] = _convertFirebaseValue(val);
      }
    });
    return result;
  }

  if (value is List) {
    return value.map((item) => _convertFirebaseValue(item)).toList();
  }

  // For other types, convert to string
  return value.toString();
}
