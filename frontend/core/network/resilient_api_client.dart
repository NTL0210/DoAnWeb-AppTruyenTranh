import 'dart:async';
import 'api_rate_limiter.dart';
import 'retry_config.dart';

/// Kết quả từ một API call có resilience
class ApiResult<T> {
  /// Dữ liệu trả về (thật hoặc mock)
  final T data;

  /// [true] nếu data từ mock (API đang lỗi)
  final bool isMock;

  /// [true] nếu đang retry ngầm trong background
  final bool isRetrying;

  const ApiResult({
    required this.data,
    this.isMock = false,
    this.isRetrying = false,
  });
}

/// ResilientApiClient – trái tim của hệ thống resilient loading
///
/// Cho mỗi API call:
/// 1. Kiểm tra rate limit + deduplication (qua ApiRateLimiter)
/// 2. Gọi API với timeout [callTimeout] (mặc định 2.5s)
/// 3. Nếu thành công → push data thật vào stream
/// 4. Nếu lỗi/timeout → push mock data ngay, rồi retry ngầm
/// 5. Retry theo exponential backoff (RetryConfig), push real data khi thành công
class ResilientApiClient {
  // Singleton
  static final ResilientApiClient _instance = ResilientApiClient._internal();
  factory ResilientApiClient() => _instance;
  ResilientApiClient._internal();

  final ApiRateLimiter _rateLimiter = ApiRateLimiter();

  /// Timeout cho mỗi API call trước khi fallback sang mock
  static const Duration callTimeout = Duration(milliseconds: 2500);

  /// Map stream controllers theo key – dùng lại giữa các caller
  ///
  /// Lưu raw type để giữ đúng generic của controller được tạo theo từng key.
  final Map<String, StreamController> _streamControllers = {};

  /// Map timer retry theo key – để cancel khi cần
  final Map<String, Timer?> _retryTimers = {};

  /// Map số lần retry hiện tại theo key
  final Map<String, int> _retryAttempts = {};

  // ──────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────

  /// Gọi API với đầy đủ resilience: rate-limit, timeout, mock fallback,
  /// background retry, stream update.
  ///
  /// [key] – unique key cho endpoint (vd: 'comics_page_1')
  /// [apiCall] – hàm gọi API thực sự
  /// [mockData] – dữ liệu fallback khi API lỗi
  /// [config] – cấu hình retry (mặc định RetryConfig.defaultConfig)
  ///
  /// Returns: Stream<ApiResult<T>> – widget lắng nghe stream này để update UI
  Stream<ApiResult<T>> call<T>({
    required String key,
    required Future<T> Function() apiCall,
    required T mockData,
    RetryConfig config = RetryConfig.defaultConfig,
  }) {
    // Tạo hoặc lấy lại StreamController cho key này
    final controller = _getOrCreateController<T>(key);

    // Thực hiện call không đồng bộ
    _executeCall<T>(
      key: key,
      apiCall: apiCall,
      mockData: mockData,
      config: config,
      controller: controller,
    );

    return controller.stream;
  }

  /// Lấy stream hiện tại của key (không trigger call mới)
  Stream<ApiResult<T>>? getStream<T>(String key) {
    final controller = _streamControllers[key];
    if (controller == null) return null;
    return controller.stream as Stream<ApiResult<T>>;
  }

  /// Hủy sạch retry và stream của một key
  void cancel(String key) {
    _retryTimers[key]?.cancel();
    _retryTimers.remove(key);
    _retryAttempts.remove(key);
    _streamControllers[key]?.close();
    _streamControllers.remove(key);
    _rateLimiter.reset(key);
    print('🛑 [ResilientClient] Cancelled key: $key');
  }

  /// Hủy tất cả (dùng khi dispose)
  void cancelAll() {
    for (final key in _streamControllers.keys.toList()) {
      cancel(key);
    }
    print('🛑 [ResilientClient] Cancelled all');
  }

  // ──────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────

  /// Lấy hoặc tạo StreamController broadcast cho một key
  StreamController<ApiResult<T>> _getOrCreateController<T>(String key) {
    if (!_streamControllers.containsKey(key)) {
      _streamControllers[key] =
          StreamController<ApiResult<T>>.broadcast();
    }
    return _streamControllers[key]! as StreamController<ApiResult<T>>;
  }

  /// Thực hiện API call với đầy đủ logic resilience
  Future<void> _executeCall<T>({
    required String key,
    required Future<T> Function() apiCall,
    required T mockData,
    required RetryConfig config,
    required StreamController<ApiResult<T>> controller,
  }) async {
    try {
      // Dùng rate limiter để dedup + rate-limit
      final result = await _rateLimiter.execute<T>(
        key,
        () => apiCall().timeout(callTimeout),
      );

      // ✅ API thành công – hủy retry nếu đang có
      _cancelRetry(key);
      _retryAttempts[key] = 0;

      print('✅ [ResilientClient] API success for key: $key');

      if (!controller.isClosed) {
        controller.add(ApiResult<T>(data: result, isMock: false));
      }
    } on TimeoutException {
      print('⏱️ [ResilientClient] Timeout for key: $key – showing mock');
      _pushMockAndScheduleRetry<T>(
        key: key,
        apiCall: apiCall,
        mockData: mockData,
        config: config,
        controller: controller,
      );
    } catch (e) {
      print('❌ [ResilientClient] Error for key: $key – $e – showing mock');
      _pushMockAndScheduleRetry<T>(
        key: key,
        apiCall: apiCall,
        mockData: mockData,
        config: config,
        controller: controller,
      );
    }
  }

  /// Push mock data lên stream và bắt đầu lịch retry ngầm
  void _pushMockAndScheduleRetry<T>({
    required String key,
    required Future<T> Function() apiCall,
    required T mockData,
    required RetryConfig config,
    required StreamController<ApiResult<T>> controller,
  }) {
    // Đẩy mock data ra ngay để UI hiện nội dung
    if (!controller.isClosed) {
      controller.add(ApiResult<T>(
        data: mockData,
        isMock: true,
        isRetrying: true,
      ));
    }

    // Bắt đầu schedule retry ngầm
    _scheduleRetry<T>(
      key: key,
      apiCall: apiCall,
      mockData: mockData,
      config: config,
      controller: controller,
      attempt: _retryAttempts[key] ?? 0,
    );
  }

  /// Lên lịch một lần retry với delay theo exponential backoff
  void _scheduleRetry<T>({
    required String key,
    required Future<T> Function() apiCall,
    required T mockData,
    required RetryConfig config,
    required StreamController<ApiResult<T>> controller,
    required int attempt,
  }) {
    if (attempt >= config.maxAttempts) {
      print(
          '🔴 [ResilientClient] Max retry attempts ($attempt) reached for key: $key');
      return;
    }

    final delay = config.delayForAttempt(attempt);
    print(
        '🔁 [ResilientClient] Retry #${attempt + 1} for key: $key in ${delay.inSeconds}s');

    _cancelRetry(key); // Hủy timer cũ nếu có

    _retryTimers[key] = Timer(delay, () async {
      _retryAttempts[key] = attempt + 1;

      try {
        print(
            '🔁 [ResilientClient] Executing retry #${_retryAttempts[key]} for: $key');

        // Reset rate limiter để cho phép gọi lại
        _rateLimiter.reset(key);

        final result = await apiCall().timeout(callTimeout);

        // ✅ Retry thành công
        _cancelRetry(key);
        _retryAttempts[key] = 0;
        print('✅ [ResilientClient] Retry success for key: $key');

        if (!controller.isClosed) {
          controller.add(ApiResult<T>(
            data: result,
            isMock: false,
            isRetrying: false,
          ));
        }
      } catch (e) {
        print(
            '❌ [ResilientClient] Retry #${_retryAttempts[key]} failed for key: $key – $e');

        // Tiếp tục retry với delay lớn hơn
        _scheduleRetry<T>(
          key: key,
          apiCall: apiCall,
          mockData: mockData,
          config: config,
          controller: controller,
          attempt: _retryAttempts[key]!,
        );
      }
    });
  }

  /// Hủy timer retry của một key
  void _cancelRetry(String key) {
    _retryTimers[key]?.cancel();
    _retryTimers[key] = null;
  }
}
