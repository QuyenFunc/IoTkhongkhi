import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String userKey; // Unique key for device pairing
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEmailVerified;
  @JsonKey(toJson: _preferencesToJson, fromJson: _preferencesFromJson)
  final UserPreferences preferences;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.profileImageUrl,
    required this.userKey,
    required this.createdAt,
    required this.updatedAt,
    required this.isEmailVerified,
    required this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    String? userKey,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    UserPreferences? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      userKey: userKey ?? this.userKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        phoneNumber,
        profileImageUrl,
        userKey,
        createdAt,
        updatedAt,
        isEmailVerified,
        preferences,
      ];
}

// Helper methods for UserPreferences serialization
Map<String, dynamic> _preferencesToJson(UserPreferences preferences) => preferences.toJson();
UserPreferences _preferencesFromJson(Map<String, dynamic> json) => UserPreferences.fromJson(json);

@JsonSerializable()
class UserPreferences extends Equatable {
  final String language;
  final String theme; // 'light', 'dark', 'system'
  final bool notificationsEnabled;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final int dataRefreshInterval; // in seconds
  final TemperatureUnit temperatureUnit;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const UserPreferences({
    required this.language,
    required this.theme,
    required this.notificationsEnabled,
    required this.pushNotificationsEnabled,
    required this.emailNotificationsEnabled,
    required this.dataRefreshInterval,
    required this.temperatureUnit,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  factory UserPreferences.defaultPreferences() {
    return const UserPreferences(
      language: 'vi',
      theme: 'system',
      notificationsEnabled: true,
      pushNotificationsEnabled: true,
      emailNotificationsEnabled: false,
      dataRefreshInterval: 30,
      temperatureUnit: TemperatureUnit.celsius,
      soundEnabled: true,
      vibrationEnabled: true,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);

  UserPreferences copyWith({
    String? language,
    String? theme,
    bool? notificationsEnabled,
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    int? dataRefreshInterval,
    TemperatureUnit? temperatureUnit,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return UserPreferences(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      dataRefreshInterval: dataRefreshInterval ?? this.dataRefreshInterval,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  @override
  List<Object?> get props => [
        language,
        theme,
        notificationsEnabled,
        pushNotificationsEnabled,
        emailNotificationsEnabled,
        dataRefreshInterval,
        temperatureUnit,
        soundEnabled,
        vibrationEnabled,
      ];
}

enum TemperatureUnit {
  @JsonValue('celsius')
  celsius,
  @JsonValue('fahrenheit')
  fahrenheit,
}

extension TemperatureUnitExtension on TemperatureUnit {
  String get symbol {
    switch (this) {
      case TemperatureUnit.celsius:
        return '°C';
      case TemperatureUnit.fahrenheit:
        return '°F';
    }
  }

  String get name {
    switch (this) {
      case TemperatureUnit.celsius:
        return 'Celsius';
      case TemperatureUnit.fahrenheit:
        return 'Fahrenheit';
    }
  }

  double convertFromCelsius(double celsius) {
    switch (this) {
      case TemperatureUnit.celsius:
        return celsius;
      case TemperatureUnit.fahrenheit:
        return (celsius * 9 / 5) + 32;
    }
  }

  double convertToCelsius(double value) {
    switch (this) {
      case TemperatureUnit.celsius:
        return value;
      case TemperatureUnit.fahrenheit:
        return (value - 32) * 5 / 9;
    }
  }
}
