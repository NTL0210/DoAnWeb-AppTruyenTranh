/// Retry configuration cho exponential backoff
///
/// Chuỗi delay: 5s → 10s → 20s → 40s → 60s (capped)
library;

class RetryConfig {
  /// Delay đầu tiên khi retry
  final Duration initialDelay;

  /// Delay tối đa (cap)
  final Duration maxDelay;

  /// Hệ số nhân delay (2.0 = double mỗi lần)
  final double multiplier;

  /// Số lần retry tối đa (0 = không retry)
  final int maxAttempts;

  const RetryConfig({
    this.initialDelay = const Duration(seconds: 5),
    this.maxDelay = const Duration(seconds: 60),
    this.multiplier = 2.0,
    this.maxAttempts = 6,
  });

  /// Config mặc định: 5s → 10s → 20s → 40s → 60s → 60s
  static const RetryConfig defaultConfig = RetryConfig();

  /// Config aggresssive cho debug (nhanh hơn)
  static const RetryConfig fastConfig = RetryConfig(
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 15),
    multiplier: 2.0,
    maxAttempts: 4,
  );

  /// Tính delay cho lần retry thứ [attempt] (bắt đầu từ 0)
  Duration delayForAttempt(int attempt) {
    if (attempt <= 0) return initialDelay;
    final ms = initialDelay.inMilliseconds * (multiplier * attempt);
    final capped = ms.clamp(0, maxDelay.inMilliseconds.toDouble());
    return Duration(milliseconds: capped.toInt());
  }

  /// Danh sách tất cả delay theo thứ tự (dùng để log / debug)
  List<Duration> get allDelays {
    return List.generate(
      maxAttempts,
      (i) => delayForAttempt(i),
    );
  }
}
