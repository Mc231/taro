/// Named non-UI durations and limits of the Worker client (02 §6.3, RC31,
/// RC90). Nothing in `data/api/` uses a raw `Duration` literal elsewhere.
abstract final class ApiTimeouts {
  /// TCP/TLS connect timeout of every request.
  static const Duration connect = Duration(seconds: 10);

  /// Short calls: challenge, config, balance, get reading, ack, rewards.
  static const Duration short = Duration(seconds: 10);

  /// Registration, token, timezone, deletion, holds and reports.
  static const Duration medium = Duration(seconds: 15);

  /// `POST /v1/purchases/verify`.
  static const Duration verify = Duration(seconds: 20);

  /// `POST /v1/readings` (RC31): the Worker's own deadline is 55 s.
  static const Duration reading = Duration(seconds: 60);

  /// When S08 shows "taking longer than usual" (RC31).
  static const Duration readingSlowAfter = Duration(seconds: 20);

  /// Poll delays of `GET /v1/readings/{clientReadingId}` after a timed-out
  /// `POST /v1/readings` (02 §6.3).
  static const List<Duration> readingPollDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
  ];

  /// The total budget of that polling (02 §6.3).
  static const Duration readingPollBudget = Duration(seconds: 30);

  /// The wait before poll number [poll] (0-based) after [elapsed] time
  /// since the timeout, or `null` when polling is over: the schedule is
  /// used up or the wait would pass [readingPollBudget].
  static Duration? readingPollDelay(int poll, Duration elapsed) {
    if (poll < 0 || poll >= readingPollDelays.length) return null;
    final delay = readingPollDelays[poll];
    return elapsed + delay > readingPollBudget ? null : delay;
  }

  /// At most this many attempts per request, the first included.
  static const int maxAttempts = 3;

  /// The first retry delay; doubled per attempt (0.5 s × 2ⁿ).
  static const Duration backoffBase = Duration(milliseconds: 500);

  /// The backoff cap.
  static const Duration backoffCap = Duration(seconds: 8);

  /// ±30 % jitter, in per mille.
  static const int jitterPerMille = 300;

  /// A `Retry-After` above this is not waited for: the failure surfaces.
  static const Duration maxRetryAfter = Duration(seconds: 30);
}
