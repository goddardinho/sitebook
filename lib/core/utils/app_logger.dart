import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Centralized logging service for SiteBook
/// Provides structured logging with appropriate levels and filtering
class AppLogger {
  static final Logger _logger = Logger(
    level: kDebugMode ? Level.debug : Level.info,
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: false,
    ),
    output: ConsoleOutput(),
  );

  /// Log debug information (development only)
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log general information
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warnings
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log errors
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal errors
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log authentication events with security considerations
  static void auth(String event, {String? userId, bool isSuccess = true}) {
    final level = isSuccess ? Level.info : Level.warning;
    final message =
        'AUTH: $event${userId != null ? ' (User: ${userId.substring(0, 8)}...)' : ''}';
    _logger.log(level, message);
  }

  /// Log API requests/responses (without sensitive data)
  static void api(
    String method,
    String endpoint, {
    int? statusCode,
    String? error,
  }) {
    if (error != null) {
      _logger.e('API $method $endpoint failed: $error');
    } else {
      _logger.i(
        'API $method $endpoint${statusCode != null ? ' -> $statusCode' : ''}',
      );
    }
  }

  /// Log storage operations
  static void storage(String operation, {String? key, bool isSuccess = true}) {
    final safeKey = key?.length != null && key!.length > 10
        ? '${key.substring(0, 10)}...'
        : key;
    if (isSuccess) {
      _logger.d('STORAGE: $operation${safeKey != null ? ' ($safeKey)' : ''}');
    } else {
      _logger.w(
        'STORAGE: $operation failed${safeKey != null ? ' ($safeKey)' : ''}',
      );
    }
  }
}
