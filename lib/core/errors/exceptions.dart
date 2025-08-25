class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({
    required this.message,
  });

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({
    required this.message,
  });

  @override
  String toString() => 'CacheException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required this.message,
    this.fieldErrors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

class AuthenticationException implements Exception {
  final String message;
  final String? code;

  const AuthenticationException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AuthenticationException: $message (Code: $code)';
}

class AuthorizationException implements Exception {
  final String message;

  const AuthorizationException({
    required this.message,
  });

  @override
  String toString() => 'AuthorizationException: $message';
}

class DeviceException implements Exception {
  final String message;
  final String? deviceId;

  const DeviceException({
    required this.message,
    this.deviceId,
  });

  @override
  String toString() => 'DeviceException: $message (Device: $deviceId)';
}

class DeviceConnectionException implements Exception {
  final String message;
  final String? deviceId;

  const DeviceConnectionException({
    required this.message,
    this.deviceId,
  });

  @override
  String toString() => 'DeviceConnectionException: $message (Device: $deviceId)';
}

class DeviceNotFoundException implements Exception {
  final String message;
  final String? deviceId;

  const DeviceNotFoundException({
    required this.message,
    this.deviceId,
  });

  @override
  String toString() => 'DeviceNotFoundException: $message (Device: $deviceId)';
}

class DataParsingException implements Exception {
  final String message;
  final dynamic data;

  const DataParsingException({
    required this.message,
    this.data,
  });

  @override
  String toString() => 'DataParsingException: $message';
}

class DataNotFoundException implements Exception {
  final String message;

  const DataNotFoundException({
    required this.message,
  });

  @override
  String toString() => 'DataNotFoundException: $message';
}

class PermissionException implements Exception {
  final String message;
  final String? permission;

  const PermissionException({
    required this.message,
    this.permission,
  });

  @override
  String toString() => 'PermissionException: $message (Permission: $permission)';
}

class FileOperationException implements Exception {
  final String message;
  final String? filePath;

  const FileOperationException({
    required this.message,
    this.filePath,
  });

  @override
  String toString() => 'FileOperationException: $message (File: $filePath)';
}

class ExportException implements Exception {
  final String message;
  final String? format;

  const ExportException({
    required this.message,
    this.format,
  });

  @override
  String toString() => 'ExportException: $message (Format: $format)';
}

class NotificationException implements Exception {
  final String message;

  const NotificationException({
    required this.message,
  });

  @override
  String toString() => 'NotificationException: $message';
}
