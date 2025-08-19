import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// 统一的日志工具类
/// 遵循 Flutter Logger 最佳实践
class Log {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Debug 级别日志
  /// 仅在 debug 模式下输出
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Info 级别日志
  /// 记录重要的业务流程信息
  static void i(dynamic message) {
    _logger.i(message);
  }

  /// Warning 级别日志
  /// 记录警告信息
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error 级别日志
  /// 记录错误信息，必须包含 error 和 stackTrace
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 网络请求日志
  /// 专门用于记录网络请求的输入输出
  static void network(String type, String url, [dynamic data, dynamic response]) {
    if (kDebugMode) {
      if (data != null) {
        _logger.i('🌐 $type: $url\n📤 Body: $data');
      }
      if (response != null) {
        _logger.i('🌐 $type: $url\n📥 Response: $response');
      }
    }
  }

  /// 业务流程日志
  /// 记录关键业务流程节点
  static void business(String action, [Map<String, dynamic>? params]) {
    _logger.i('💼 $action${params != null ? ' | Params: $params' : ''}');
  }

  /// 函数进入/退出日志
  /// 用于调试函数调用流程
  static void enter(String functionName) {
    if (kDebugMode) {
      _logger.d('➡️  Entering: $functionName');
    }
  }

  static void exit(String functionName) {
    if (kDebugMode) {
      _logger.d('⬅️  Exiting: $functionName');
    }
  }
}
