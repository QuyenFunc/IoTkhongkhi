// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isEmailVerified: json['isEmailVerified'] as bool,
      preferences:
          _preferencesFromJson(json['preferences'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'phoneNumber': instance.phoneNumber,
      'profileImageUrl': instance.profileImageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isEmailVerified': instance.isEmailVerified,
      'preferences': _preferencesToJson(instance.preferences),
    };

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
      language: json['language'] as String,
      theme: json['theme'] as String,
      notificationsEnabled: json['notificationsEnabled'] as bool,
      pushNotificationsEnabled: json['pushNotificationsEnabled'] as bool,
      emailNotificationsEnabled: json['emailNotificationsEnabled'] as bool,
      dataRefreshInterval: (json['dataRefreshInterval'] as num).toInt(),
      temperatureUnit:
          $enumDecode(_$TemperatureUnitEnumMap, json['temperatureUnit']),
      soundEnabled: json['soundEnabled'] as bool,
      vibrationEnabled: json['vibrationEnabled'] as bool,
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
      'language': instance.language,
      'theme': instance.theme,
      'notificationsEnabled': instance.notificationsEnabled,
      'pushNotificationsEnabled': instance.pushNotificationsEnabled,
      'emailNotificationsEnabled': instance.emailNotificationsEnabled,
      'dataRefreshInterval': instance.dataRefreshInterval,
      'temperatureUnit': _$TemperatureUnitEnumMap[instance.temperatureUnit]!,
      'soundEnabled': instance.soundEnabled,
      'vibrationEnabled': instance.vibrationEnabled,
    };

const _$TemperatureUnitEnumMap = {
  TemperatureUnit.celsius: 'celsius',
  TemperatureUnit.fahrenheit: 'fahrenheit',
};
