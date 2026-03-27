/// API Rate Limiter
///
/// Hai chức năng chính:
/// 1. Rate limit: không cho gọi cùng endpoint quá 1 lần mỗi [minInterval].
/// 2. Deduplication: nếu đang có request cùng key, trả về Future đó luôn.
library;

class ApiRateLimiter {
  // Singleton
  static final ApiRateLimiter _instance = ApiRateLimiter._internal();
  factory ApiRateLimiter() => _instance;
  ApiRateLimiter._internal();

  /// Khoảng thời gian tối thiểu giữa 2 lần gọi cùng key (mặc định 3 giây)
  static const Duration defaultMinInterval = Duration(seconds: 3);

  /// Ghi nhận lần gọi cuối cùng theo từng key
  final Map<String, DateTime> _lastCallTime = {};

  /// Cache Future đang chạy để dedup – tự xóa khi Future hoàn thành
  final Map<String, Future<dynamic>> _pendingRequests = {};

  // ──────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────

  /// Kiểm tra xem key có thể được gọi chưa.
  ///
  /// Trả về `true` nếu đã qua [minInterval] kể từ lần gọi trước.
  bool canCall(String key, {Duration? minInterval}) {
    final interval = minInterval ?? defaultMinInterval;
    final last = _lastCallTime[key];
    if (last == null) return true;
    return DateTime.now().difference(last) >= interval;
  }

  /// Thực hiện [call] với deduplication và rate-limit ghi nhận.
  ///
  /// - Nếu đang có Future cùng [key] đang chạy → trả về Future đó (dedup).
  /// - Nếu chưa có → tạo Future mới, ghi timestamp, tự dọn khi xong.
  Future<T> execute<T>(
    String key,
    Future<T> Function() call, {
    Duration? minInterval,
  }) async {
    // Deduplication: trả về Future đang pending nếu có
    if (_pendingRequests.containsKey(key)) {
      print('🔄 [RateLimiter] Reusing pending request for key: $key');
      return _pendingRequests[key]! as Future<T>;
    }

    // Ghi nhận thời gian gọi
    _lastCallTime[key] = DateTime.now();

    // Tạo Future mới và lưu vào pending map
    final future = call().whenComplete(() {
      _pendingRequests.remove(key);
      print('✅ [RateLimiter] Completed & removed: $key');
    });

    _pendingRequests[key] = future;
    print('🚀 [RateLimiter] New request for key: $key');
    return future;
  }

  /// Xóa trạng thái pending và timestamp của một key (dùng khi force reset)
  void reset(String key) {
    _lastCallTime.remove(key);
    _pendingRequests.remove(key);
    print('🗑️ [RateLimiter] Reset key: $key');
  }

  /// Xóa toàn bộ trạng thái
  void resetAll() {
    _lastCallTime.clear();
    _pendingRequests.clear();
    print('🗑️ [RateLimiter] Reset all');
  }

  /// Thời gian còn phải chờ trước khi có thể gọi lại key này.
  /// Trả về Duration.zero nếu không cần chờ.
  Duration remainingCooldown(String key, {Duration? minInterval}) {
    final interval = minInterval ?? defaultMinInterval;
    final last = _lastCallTime[key];
    if (last == null) return Duration.zero;
    final elapsed = DateTime.now().difference(last);
    final remaining = interval - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
