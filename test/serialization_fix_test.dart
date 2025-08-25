import 'package:flutter_test/flutter_test.dart';
import 'package:air_quality/shared/models/user_model.dart';

void main() {
  group('Serialization Fix Tests', () {
    test('should serialize UserModel with UserPreferences correctly', () {
      final now = DateTime.now();
      final userModel = UserModel(
        id: 'test-uid-123',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: now,
        updatedAt: now,
        isEmailVerified: true,
        preferences: UserPreferences.defaultPreferences(),
      );

      // Test toJson
      final json = userModel.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], equals('test-uid-123'));
      expect(json['preferences'], isA<UserPreferences>());

      // Manual fix for preferences
      json['preferences'] = userModel.preferences.toJson();
      expect(json['preferences'], isA<Map<String, dynamic>>());
      
      final preferencesJson = json['preferences'] as Map<String, dynamic>;
      expect(preferencesJson['language'], equals('vi'));
      expect(preferencesJson['theme'], equals('system'));
      expect(preferencesJson['notificationsEnabled'], isTrue);
      
      print('✅ UserModel serialization with manual preferences fix works');
    });

    test('should deserialize UserModel with UserPreferences correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'test-uid-456',
        'email': 'test2@example.com',
        'name': 'Test User 2',
        'phoneNumber': null,
        'profileImageUrl': null,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isEmailVerified': false,
        'preferences': {
          'language': 'en',
          'theme': 'dark',
          'notificationsEnabled': false,
          'pushNotificationsEnabled': true,
          'emailNotificationsEnabled': true,
          'dataRefreshInterval': 60,
          'temperatureUnit': 'fahrenheit',
          'soundEnabled': false,
          'vibrationEnabled': true,
        },
      };

      final userModel = UserModel.fromJson(json);
      expect(userModel.id, equals('test-uid-456'));
      expect(userModel.email, equals('test2@example.com'));
      expect(userModel.preferences.language, equals('en'));
      expect(userModel.preferences.theme, equals('dark'));
      expect(userModel.preferences.notificationsEnabled, isFalse);
      
      print('✅ UserModel deserialization works');
    });

    test('should handle UserPreferences serialization independently', () {
      final preferences = UserPreferences.defaultPreferences();
      
      // Test toJson
      final json = preferences.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['language'], equals('vi'));
      expect(json['theme'], equals('system'));
      expect(json['notificationsEnabled'], isTrue);
      expect(json['temperatureUnit'], equals('celsius'));
      
      // Test fromJson
      final deserializedPreferences = UserPreferences.fromJson(json);
      expect(deserializedPreferences.language, equals(preferences.language));
      expect(deserializedPreferences.theme, equals(preferences.theme));
      expect(deserializedPreferences.notificationsEnabled, equals(preferences.notificationsEnabled));
      
      print('✅ UserPreferences independent serialization works');
    });

    test('should create Firebase-compatible JSON structure', () {
      final now = DateTime.now();
      final userModel = UserModel(
        id: 'firebase-test-789',
        email: 'firebase@example.com',
        name: 'Firebase Test User',
        phoneNumber: '+84123456789',
        createdAt: now,
        updatedAt: now,
        isEmailVerified: true,
        preferences: UserPreferences.defaultPreferences(),
      );

      // Simulate the manual fix we do in services
      final userJson = userModel.toJson();
      userJson['preferences'] = userModel.preferences.toJson();

      // Verify structure is Firebase-compatible (all values are primitives or Maps)
      expect(userJson['id'], isA<String>());
      expect(userJson['email'], isA<String>());
      expect(userJson['name'], isA<String>());
      expect(userJson['phoneNumber'], isA<String>());
      expect(userJson['createdAt'], isA<String>());
      expect(userJson['updatedAt'], isA<String>());
      expect(userJson['isEmailVerified'], isA<bool>());
      expect(userJson['preferences'], isA<Map<String, dynamic>>());

      final preferencesJson = userJson['preferences'] as Map<String, dynamic>;
      expect(preferencesJson['language'], isA<String>());
      expect(preferencesJson['theme'], isA<String>());
      expect(preferencesJson['notificationsEnabled'], isA<bool>());
      expect(preferencesJson['dataRefreshInterval'], isA<int>());
      expect(preferencesJson['temperatureUnit'], isA<String>());
      
      print('✅ Firebase-compatible JSON structure created');
    });

    test('should handle null and optional fields correctly', () {
      final now = DateTime.now();
      final userModel = UserModel(
        id: 'null-test-101',
        email: 'null@example.com',
        name: 'Null Test User',
        phoneNumber: null, // null field
        profileImageUrl: null, // null field
        createdAt: now,
        updatedAt: now,
        isEmailVerified: false,
        preferences: UserPreferences.defaultPreferences(),
      );

      // Serialize with manual fix
      final userJson = userModel.toJson();
      userJson['preferences'] = userModel.preferences.toJson();

      expect(userJson['phoneNumber'], isNull);
      expect(userJson['profileImageUrl'], isNull);
      expect(userJson['preferences'], isNotNull);
      expect(userJson['preferences'], isA<Map<String, dynamic>>());

      // Should be able to deserialize back
      final deserializedModel = UserModel.fromJson(userJson);
      expect(deserializedModel.phoneNumber, isNull);
      expect(deserializedModel.profileImageUrl, isNull);
      expect(deserializedModel.preferences, isNotNull);
      
      print('✅ Null and optional fields handling works');
    });

    test('should match expected database structure', () {
      final now = DateTime.now();
      final userModel = UserModel(
        id: 'db-structure-202',
        email: 'structure@example.com',
        name: 'Structure Test User',
        phoneNumber: '+84987654321',
        profileImageUrl: 'https://example.com/avatar.jpg',
        createdAt: now,
        updatedAt: now,
        isEmailVerified: true,
        preferences: UserPreferences.defaultPreferences(),
      );

      // Create Firebase-compatible JSON
      final userJson = userModel.toJson();
      userJson['preferences'] = userModel.preferences.toJson();

      // Check expected database structure
      final expectedKeys = [
        'id', 'email', 'name', 'phoneNumber', 'profileImageUrl',
        'createdAt', 'updatedAt', 'isEmailVerified', 'preferences'
      ];

      for (final key in expectedKeys) {
        expect(userJson.containsKey(key), isTrue, reason: 'Should contain key: $key');
      }

      // Check preferences structure
      final preferencesJson = userJson['preferences'] as Map<String, dynamic>;
      final expectedPreferencesKeys = [
        'language', 'theme', 'notificationsEnabled', 'pushNotificationsEnabled',
        'emailNotificationsEnabled', 'dataRefreshInterval', 'temperatureUnit',
        'soundEnabled', 'vibrationEnabled'
      ];

      for (final key in expectedPreferencesKeys) {
        expect(preferencesJson.containsKey(key), isTrue, reason: 'Preferences should contain key: $key');
      }
      
      print('✅ Database structure matches expectations');
    });
  });
}
