import 'package:flutter_test/flutter_test.dart';
import 'package:air_quality/shared/models/user_model.dart';


void main() {
  group('Profile Creation Tests', () {
    test('should create UserModel with required fields', () {
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

      expect(userModel.id, equals('test-uid-123'));
      expect(userModel.email, equals('test@example.com'));
      expect(userModel.name, equals('Test User'));
      expect(userModel.isEmailVerified, isTrue);
      expect(userModel.preferences, isNotNull);
      
      print('✅ UserModel creation with required fields works');
    });

    test('should create UserModel from minimal auth data', () {
      // Simulate minimal auth data
      final now = DateTime.now();
      final userModel = UserModel(
        id: 'auth-uid-456',
        email: 'auth@example.com',
        name: 'Người dùng', // Default name
        phoneNumber: null,
        profileImageUrl: null,
        createdAt: now,
        updatedAt: now,
        isEmailVerified: false,
        preferences: UserPreferences.defaultPreferences(),
      );

      expect(userModel.id, equals('auth-uid-456'));
      expect(userModel.email, equals('auth@example.com'));
      expect(userModel.name, equals('Người dùng'));
      expect(userModel.phoneNumber, isNull);
      expect(userModel.profileImageUrl, isNull);
      expect(userModel.isEmailVerified, isFalse);
      
      print('✅ UserModel creation from minimal auth data works');
    });

    test('should serialize and deserialize UserModel correctly', () {
      final now = DateTime.now();
      final originalModel = UserModel(
        id: 'serialize-test-789',
        email: 'serialize@example.com',
        name: 'Serialize Test User',
        phoneNumber: '+84123456789',
        profileImageUrl: 'https://example.com/avatar.jpg',
        createdAt: now,
        updatedAt: now,
        isEmailVerified: true,
        preferences: UserPreferences.defaultPreferences(),
      );

      // Convert to JSON
      final json = originalModel.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], equals('serialize-test-789'));
      expect(json['email'], equals('serialize@example.com'));

      // Convert back from JSON
      final deserializedModel = UserModel.fromJson(json);
      expect(deserializedModel.id, equals(originalModel.id));
      expect(deserializedModel.email, equals(originalModel.email));
      expect(deserializedModel.name, equals(originalModel.name));
      expect(deserializedModel.phoneNumber, equals(originalModel.phoneNumber));
      expect(deserializedModel.isEmailVerified, equals(originalModel.isEmailVerified));
      
      print('✅ UserModel serialization/deserialization works');
    });

    test('should have valid default preferences', () {
      final preferences = UserPreferences.defaultPreferences();

      expect(preferences.language, equals('vi'));
      expect(preferences.theme, equals('system'));
      expect(preferences.notificationsEnabled, isTrue);
      expect(preferences.pushNotificationsEnabled, isTrue);
      expect(preferences.emailNotificationsEnabled, isFalse);
      expect(preferences.dataRefreshInterval, equals(30));
      expect(preferences.temperatureUnit, equals(TemperatureUnit.celsius));
      expect(preferences.soundEnabled, isTrue);
      expect(preferences.vibrationEnabled, isTrue);
      
      print('✅ Default preferences are valid');
    });

    test('should handle profile update correctly', () {
      final now = DateTime.now();
      final originalProfile = UserModel(
        id: 'update-test-101',
        email: 'update@example.com',
        name: 'Original Name',
        createdAt: now,
        updatedAt: now,
        isEmailVerified: false,
        preferences: UserPreferences.defaultPreferences(),
      );

      final updatedProfile = originalProfile.copyWith(
        name: 'Updated Name',
        phoneNumber: '+84987654321',
        isEmailVerified: true,
        updatedAt: DateTime.now(),
      );

      expect(updatedProfile.id, equals(originalProfile.id)); // Should remain same
      expect(updatedProfile.email, equals(originalProfile.email)); // Should remain same
      expect(updatedProfile.name, equals('Updated Name')); // Should be updated
      expect(updatedProfile.phoneNumber, equals('+84987654321')); // Should be updated
      expect(updatedProfile.isEmailVerified, isTrue); // Should be updated
      expect(updatedProfile.createdAt, equals(originalProfile.createdAt)); // Should remain same
      expect(updatedProfile.updatedAt.isAfter(originalProfile.updatedAt), isTrue); // Should be newer
      
      print('✅ Profile update with copyWith works');
    });

    test('should validate required fields', () {
      final now = DateTime.now();
      
      // Test with all required fields
      expect(() => UserModel(
        id: 'required-test-202',
        email: 'required@example.com',
        name: 'Required Test',
        createdAt: now,
        updatedAt: now,
        isEmailVerified: true,
        preferences: UserPreferences.defaultPreferences(),
      ), returnsNormally);

      print('✅ Required fields validation works');
    });

    test('should handle empty and null values gracefully', () {
      final now = DateTime.now();
      final userModel = UserModel(
        id: 'empty-test-303',
        email: '', // Empty email
        name: '', // Empty name
        phoneNumber: null,
        profileImageUrl: null,
        createdAt: now,
        updatedAt: now,
        isEmailVerified: false,
        preferences: UserPreferences.defaultPreferences(),
      );

      expect(userModel.email, equals(''));
      expect(userModel.name, equals(''));
      expect(userModel.phoneNumber, isNull);
      expect(userModel.profileImageUrl, isNull);
      
      // Should still be able to serialize/deserialize
      final json = userModel.toJson();
      final deserializedModel = UserModel.fromJson(json);
      expect(deserializedModel.email, equals(''));
      expect(deserializedModel.name, equals(''));
      
      print('✅ Empty and null values handling works');
    });

    test('should create profile data structure for database', () {
      final now = DateTime.now();
      final userModel = UserModel(
        id: 'database-test-404',
        email: 'database@example.com',
        name: 'Database Test User',
        phoneNumber: '+84111222333',
        createdAt: now,
        updatedAt: now,
        isEmailVerified: true,
        preferences: UserPreferences.defaultPreferences(),
      );

      final json = userModel.toJson();
      
      // Check database structure
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('email'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('phoneNumber'), isTrue);
      expect(json.containsKey('profileImageUrl'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('updatedAt'), isTrue);
      expect(json.containsKey('isEmailVerified'), isTrue);
      expect(json.containsKey('preferences'), isTrue);
      
      // Check preferences structure
      final preferences = json['preferences'] as Map<String, dynamic>;
      expect(preferences.containsKey('language'), isTrue);
      expect(preferences.containsKey('theme'), isTrue);
      expect(preferences.containsKey('notificationsEnabled'), isTrue);
      
      print('✅ Database structure is correct');
    });
  });
}
