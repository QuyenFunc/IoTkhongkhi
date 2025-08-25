import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

// Authentication failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    required super.message,
    super.code,
  });
}

class AuthorizationFailure extends Failure {
  const AuthorizationFailure({
    required super.message,
    super.code,
  });
}

// Device failures
class DeviceFailure extends Failure {
  const DeviceFailure({
    required super.message,
    super.code,
  });
}

class DeviceConnectionFailure extends Failure {
  const DeviceConnectionFailure({
    required super.message,
    super.code,
  });
}

class DeviceNotFoundFailure extends Failure {
  const DeviceNotFoundFailure({
    required super.message,
    super.code,
  });
}

// Data failures
class DataParsingFailure extends Failure {
  const DataParsingFailure({
    required super.message,
    super.code,
  });
}

class DataNotFoundFailure extends Failure {
  const DataNotFoundFailure({
    required super.message,
    super.code,
  });
}

// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
  });
}

// File operation failures
class FileOperationFailure extends Failure {
  const FileOperationFailure({
    required super.message,
    super.code,
  });
}

// Export failures
class ExportFailure extends Failure {
  const ExportFailure({
    required super.message,
    super.code,
  });
}

// Notification failures
class NotificationFailure extends Failure {
  const NotificationFailure({
    required super.message,
    super.code,
  });
}
