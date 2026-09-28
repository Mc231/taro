import 'package:taro/data/api/api_timeouts.dart';

/// Retry backoff built from ApiTimeouts, not flagged (data/ is not UI code).
Duration backoffFor(int attempt) => ApiTimeouts.retryBackoff * (attempt + 1);
