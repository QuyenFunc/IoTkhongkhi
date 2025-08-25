import 'package:flutter_test/flutter_test.dart';
import 'package:air_quality/shared/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('should create UserModel with all required fields', () {
      final now = DateTime.now();
      final userModel = UserModel(
        id: 'test-uid-123',
        email: 'test@example.com',
        name: 'Test User',
        phoneNumber: '+84123456789',
        profileImageUrl: 'https://example.com/avatar.jpg',
        createdAt: now,
        updatedAt: now,
        isEmailVerified: true,
        preferences: UserPreferences.defaultPreferences(),
      );

      expect(userModel.id, equals('test-uid-123'));
      expect(userModel.email, equals('test@example.com'));
      expect(userModel.name, equals('Test User'));
      expect(userModel.phoneNumber, equals('+84123456789'));
      expect(userModel.profileImageUrl, equals('https://example.com/avatar.jpg'));
      expect(userModel.isEmailVerified, isTrue);
      expect(userModel.preferences, isNotNull);
      
      print('✅ UserModel creation test passed');
    });

    test('should create UserModel with optional fields as null', () {
      final now = DateTime.now();
      final userModel = UserModel(
        id: 'test-uid-456',
        email: 'test2@example.com',
        name: 'Test User 2',
        createdAt: now,
        updatedAt: now,
        isEmailVerified: false,
        preferences: UserPreferences.defaultPreferences(),
      );

      expect(userModel.phoneNumber, isNull);
      expect(userModel.profileImageUrl, isNull);
      expect(userModel.isEmailVerified, isFalse);
      
      print('✅ UserModel optional fields test passed');
    });

    test('should convert UserModel to JSON correctly', () {
      final now = DateTime.now();
      final userModel = UserModel(
        id: 'test-uid-789',
        email: 'test3@example.com',
        name: 'Test User 3',
        phoneNumber: '+84987654321',
        createdAt: now,
        updatedAt: now,
        isEmailVerified: true,
        preferences: UserPreferences.defaultPreferences(),
      );

      final json = userModel.toJson();

      expect(json['id'], equals('test-uid-789'));
      expect(json['email'], equals('test3@example.com'));
      expect(json['name'], equals('Test User 3'));
      expect(json['phoneNumber'], equals('+84987654321'));
      expect(json['isEmailVerified'], isTrue);
      expect(json['preferences'], isNotNull);
      
      print('✅ UserModel toJson test passed');
    });

    test('should create UserModel from JSON correctly', () {
      final now = DateTime.now();
      final json = {
        'id': 'test-uid-101',
        'email': 'test4@example.com',
        'name': 'Test User 4',
        'phoneNumber': '+84111222333',
        'profileImageUrl': 'https://example.com/profile.jpg',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isEmailVerified': false,
        'preferences': {
          'language': 'vi',
          'theme': 'dark',
          'notificationsEnabled': true,
          'pushNotificationsEnabled': false,
          'emailNotificationsEnabled': true,
          'dataRefreshInterval': 60,
          'temperatureUnit': 'celsius',
          'soundEnabled': true,
          'vibrationEnabled': false,
        },
      };

      final userModel = UserModel.fromJson(json);

      expect(userModel.id, equals('test-uid-101'));
      expect(userModel.email, equals('test4@example.com'));
      expect(userModel.name, equals('Test User 4'));
      expect(userModel.phoneNumber, equals('+84111222333'));
      expect(userModel.profileImageUrl, equals('https://example.com/profile.jpg'));
      expect(userModel.isEmailVerified, isFalse);
      expect(userModel.preferences.theme, equals('dark'));
      expect(userModel.preferences.dataRefreshInterval, equals(60));
      
      print('✅ UserModel fromJson test passed');
    });

    test('should copy UserModel with updated fields', () {
      final now = DateTime.now();
      final originalUser = UserModel(
        id: 'test-uid-202',
        email: 'original@example.com',
        name: 'Original User',
        createdAt: now,
        updatedAt: now,
        isEmailVerified: false,
        preferences: UserPreferences.defaultPreferences(),
      );

      final updatedUser = originalUser.copyWith(
        name: 'Updated User',
        phoneNumber: '+84555666777',
        isEmailVerified: true,
      );

      expect(updatedUser.id, equals(originalUser.id)); // Should remain same
      expect(updatedUser.email, equals(originalUser.email)); // Should remain same
      expect(updatedUser.name, equals('Updated User')); // Should be updated
      expect(updatedUser.phoneNumber, equals('+84555666777')); // Should be updated
      expect(updatedUser.isEmailVerified, isTrue); // Should be updated
      expect(updatedUser.createdAt, equals(originalUser.createdAt)); // Should remain same
      
      print('✅ UserModel copyWith test passed');
    });
  });

  group('UserPreferences Tests', () {
    test('should create default preferences correctly', () {
      final defaultPrefs = UserPreferences.defaultPreferences();

      expect(defaultPrefs.language, equals('vi'));
      expect(defaultPrefs.theme, equals('system'));
      expect(defaultPrefs.notificationsEnabled, isTrue);
      expect(defaultPrefs.pushNotificationsEnabled, isTrue);
      expect(defaultPrefs.emailNotificationsEnabled, isFalse);
      expect(defaultPrefs.dataRefreshInterval, equals(30));
      expect(defaultPrefs.temperatureUnit, equals(TemperatureUnit.celsius));
      expect(defaultPrefs.soundEnabled, isTrue);
      expect(defaultPrefs.vibrationEnabled, isTrue);
      
      print('✅ UserPreferences defaults test passed');
    });

    test('should convert UserPreferences to JSON correctly', () {
      final prefs = UserPreferences.defaultPreferences();
      final json = prefs.toJson();

      expect(json['language'], equals('vi'));
      expect(json['theme'], equals('system'));
      expect(json['notificationsEnabled'], isTrue);
      expect(json['temperatureUnit'], equals('celsius'));
      
      print('✅ UserPreferences toJson test passed');
    });

    test('should create UserPreferences from JSON correctly', () {
      final json = {
        'language': 'en',
        'theme': 'dark',
        'notificationsEnabled': false,
        'pushNotificationsEnabled': true,
        'emailNotificationsEnabled': true,
        'dataRefreshInterval': 120,
        'temperatureUnit': 'fahrenheit',
        'soundEnabled': false,
        'vibrationEnabled': true,
      };

      final prefs = UserPreferences.fromJson(json);

      expect(prefs.language, equals('en'));
      expect(prefs.theme, equals('dark'));
      expect(prefs.notificationsEnabled, isFalse);
      expect(prefs.dataRefreshInterval, equals(120));
      expect(prefs.temperatureUnit, equals(TemperatureUnit.fahrenheit));
      expect(prefs.soundEnabled, isFalse);
      
      print('✅ UserPreferences fromJson test passed');
    });

    test('should copy UserPreferences with updated fields', () {
      final originalPrefs = UserPreferences.defaultPreferences();
      final updatedPrefs = originalPrefs.copyWith(
        theme: 'dark',
        dataRefreshInterval: 60,
        temperatureUnit: TemperatureUnit.fahrenheit,
      );

      expect(updatedPrefs.language, equals(originalPrefs.language)); // Should remain same
      expect(updatedPrefs.theme, equals('dark')); // Should be updated
      expect(updatedPrefs.dataRefreshInterval, equals(60)); // Should be updated
      expect(updatedPrefs.temperatureUnit, equals(TemperatureUnit.fahrenheit)); // Should be updated
      expect(updatedPrefs.notificationsEnabled, equals(originalPrefs.notificationsEnabled)); // Should remain same
      
      print('✅ UserPreferences copyWith test passed');
    });
  });

  group('TemperatureUnit Tests', () {
    test('should have correct symbols', () {
      expect(TemperatureUnit.celsius.symbol, equals('°C'));
      expect(TemperatureUnit.fahrenheit.symbol, equals('°F'));
      
      print('✅ TemperatureUnit symbols test passed');
    });

    test('should have correct names', () {
      expect(TemperatureUnit.celsius.name, equals('Celsius'));
      expect(TemperatureUnit.fahrenheit.name, equals('Fahrenheit'));
      
      print('✅ TemperatureUnit names test passed');
    });

    test('should convert temperatures correctly', () {
      // Test Celsius to Fahrenheit
      final fahrenheitValue = TemperatureUnit.fahrenheit.convertFromCelsius(25.0);
      expect(fahrenheitValue, equals(77.0));

      // Test Fahrenheit to Celsius
      final celsiusValue = TemperatureUnit.fahrenheit.convertToCelsius(77.0);
      expect(celsiusValue, equals(25.0));

      // Test Celsius to Celsius (should remain same)
      final celsiusTocelsius = TemperatureUnit.celsius.convertFromCelsius(25.0);
      expect(celsiusTocelsius, equals(25.0));
      
      print('✅ TemperatureUnit conversion test passed');
    });
  });
}
