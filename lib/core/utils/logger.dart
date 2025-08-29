import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Kelas utilitas untuk logging pada aplikasi
class AppLogger {
  static bool _enableVerbose = false;

  /// Mengaktifkan log verbose (detail)
  static void enableVerboseLogging(bool enable) {
    _enableVerbose = enable;
  }

  /// Log informasi umum
  static void info(String message, {String? tag}) {
    final logTag = tag != null ? '[$tag]' : '[INFO]';
    print('$logTag $message');
  }

  /// Log untuk debugging
  static void debug(String message, {String? tag}) {
    if (kDebugMode || _enableVerbose) {
      final logTag = tag != null ? '[$tag]' : '[DEBUG]';
      print('$logTag $message');
    }
  }

  /// Log untuk error
  static void error(String message,
      {Object? error, StackTrace? stackTrace, String? tag}) {
    final logTag = tag != null ? '[$tag]' : '[ERROR]';
    print('$logTag $message');

    if (error != null) {
      print('$logTag Error details: $error');
    }

    if (stackTrace != null && (_enableVerbose || kDebugMode)) {
      print('$logTag StackTrace: $stackTrace');
    }
  }

  /// Log untuk catatan penting
  static void warning(String message, {String? tag}) {
    final logTag = tag != null ? '[$tag]' : '[WARNING]';
    print('$logTag $message');
  }

  /// Log untuk API request dan response
  static void api(String message, {Object? data, String? tag}) {
    if (kDebugMode || _enableVerbose) {
      final logTag = tag != null ? '[$tag]' : '[API]';
      print('$logTag $message');

      if (data != null) {
        final String dataString = data.toString();
        // Batasi output jika terlalu panjang
        if (dataString.length > 500 && !_enableVerbose) {
          print(
              '$logTag Data: ${dataString.substring(0, 500)}... (${dataString.length} karakter)');
        } else {
          print('$logTag Data: $data');
        }
      }
    }
  }

  /// Log khusus untuk UI events
  static void ui(String message, {String? tag}) {
    if (kDebugMode || _enableVerbose) {
      final logTag = tag != null ? '[$tag]' : '[UI]';
      print('$logTag $message');
    }
  }

  /// Log khusus untuk form dan validasi
  static void form(String message,
      {Map<String, dynamic>? fields, String? tag}) {
    if (kDebugMode || _enableVerbose) {
      final logTag = tag != null ? '[$tag]' : '[FORM]';
      print('$logTag $message');

      if (fields != null && fields.isNotEmpty) {
        print('$logTag Form fields:');
        fields.forEach((key, value) {
          final valueString = value is String ? '"$value"' : value;
          final isValid =
              value != null && (value is String ? value.isNotEmpty : true);
          print('$logTag   - $key: $valueString (valid: $isValid)');
        });
      }
    }
  }

  /// Buat FocusNode yang melakukan logging saat fokus berubah
  static FocusNode createLoggingFocusNode(String fieldName, {String? tag}) {
    final node = FocusNode();
    node.addListener(() {
      final status = node.hasFocus ? 'menerima fokus' : 'kehilangan fokus';
      AppLogger.ui('Field "$fieldName" $status', tag: tag ?? 'Focus');
    });
    return node;
  }
}
