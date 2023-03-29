import 'package:equatable/equatable.dart';

abstract class AppException implements Exception {
  String get message;
}

class ApiException extends AppException {
  final String message;

  ApiException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException extends ApiException {
  TimeoutException({String message = 'Request timed out.'})
      : super(message: message);
}

class BadRequestException extends ApiException {
  BadRequestException({String message = 'Bad request.'})
      : super(message: message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({String message = 'Unauthorized.'})
      : super(message: message);
}

class NotFoundException extends AppException {
  final String message;

  NotFoundException({required this.message});

  @override
  String toString() => 'NotFoundException: $message';
}

/// Abstract class for representing failures in the application
/// It extends Equatable to enable comparison between instances.
/// The message property stores a description of the failure.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [];
}

/// ServerFailure class
/// Represents a failure caused by a server error
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}
