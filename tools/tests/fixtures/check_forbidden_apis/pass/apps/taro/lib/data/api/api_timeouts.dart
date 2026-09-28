import 'package:dio/dio.dart';

/// Named non-UI durations (RC90): not flagged outside UI code.
abstract final class ApiTimeouts {
  static const Duration connect = Duration(milliseconds: 8000);
  static const Duration retryBackoff = Duration(milliseconds: 250);
}

BaseOptions workerOptions() =>
    BaseOptions(connectTimeout: ApiTimeouts.connect);
