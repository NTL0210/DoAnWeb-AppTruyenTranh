import 'dart:async';
import 'dart:convert';
import 'package:signalr_core/signalr_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/crawl_notification.dart';

/// Service quản lý SignalR notifications từ backend crawler
class NotificationService {
  static const String _baseUrl =
      'https://cytostomal-nonsubtractive-bryanna.ngrok-free.dev';
  static const String _hubPath = '/hubs/notifications';

  HubConnection? _connection;
  final _notificationController =
      StreamController<CrawlNotification>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  final List<CrawlNotification> _notifications = [];
  int _unreadCount = 0;

  // Getters
  Stream<CrawlNotification> get notifications =>
      _notificationController.stream;
  Stream<bool> get connectionState => _connectionStateController.stream;
  List<CrawlNotification> get allNotifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;

  bool get isConnected =>
      _connection?.state == HubConnectionState.connected;

  /// Khởi tạo và kết nối SignalR
  Future<void> connect() async {
    try {
      print('🔔 Connecting to SignalR hub...');

      // Lấy token từ SharedPreferences
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ No auth token found. Cannot connect to SignalR.');
        return;
      }

      // Tạo connection
      _connection = HubConnectionBuilder()
          .withUrl(
            '$_baseUrl$_hubPath',
            HttpConnectionOptions(
              accessTokenFactory: () => Future.value(token),
              logging: (level, message) => print('SignalR [$level]: $message'),
            ),
          )
          .withAutomaticReconnect()
          .build();

      // Lắng nghe sự kiện
      _setupEventHandlers();

      // Kết nối
      await _connection!.start();
      print('✅ SignalR connected successfully');
      _connectionStateController.add(true);
    } catch (e) {
      print('❌ SignalR connection error: $e');
      _connectionStateController.add(false);
    }
  }

  /// Thiết lập event handlers
  void _setupEventHandlers() {
    if (_connection == null) return;

    // Nhận thông báo crawler
    _connection!.on('ReceiveCrawlNotification', _handleNotification);

    // Sự kiện kết nối
    _connection!.onreconnecting((error) {
      print('🔄 SignalR reconnecting... Error: $error');
      _connectionStateController.add(false);
    });

    _connection!.onreconnected((connectionId) {
      print('✅ SignalR reconnected. ConnectionId: $connectionId');
      _connectionStateController.add(true);
    });

    _connection!.onclose((error) {
      print('❌ SignalR connection closed. Error: $error');
      _connectionStateController.add(false);
    });
  }

  // Batch notifications buffer
  final List<CrawlNotification> _batchBuffer = [];
  Timer? _batchTimer;

  /// Xử lý thông báo nhận được
  void _handleNotification(List<Object?>? arguments) {
    try {
      if (arguments == null || arguments.isEmpty) {
        print('⚠️ Received empty notification');
        return;
      }

      final data = arguments[0] as Map<String, dynamic>;
      
      // 🔍 DEBUG: In ra toàn bộ dữ liệu nhận được
      print('🔍 DEBUG - Raw notification data: $data');
      
      final notification = CrawlNotification.fromJson(data);

      print('📬 New notification: ${notification.comicName}');
      print('🔍 Comic Slug: ${notification.comicSlug}');
      print('🔍 Comic ID: ${notification.comicId}');

      // Thêm vào danh sách
      _notifications.insert(0, notification);
      _unreadCount++;

      // Lưu vào local storage
      _saveNotificationLocally(notification);

      // ✅ BATCH NOTIFICATIONS: Gộp nhiều thông báo trong 5 giây
      _batchBuffer.add(notification);
      
      // Hủy timer cũ nếu có
      _batchTimer?.cancel();
      
      // Đợi 5 giây, nếu không có notification mới thì gửi batch
      _batchTimer = Timer(const Duration(seconds: 5), () {
        if (_batchBuffer.isNotEmpty) {
          _sendBatchNotification();
        }
      });
    } catch (e) {
      print('❌ Error handling notification: $e');
    }
  }

  /// Gửi notification gộp
  void _sendBatchNotification() {
    if (_batchBuffer.isEmpty) return;

    if (_batchBuffer.length == 1) {
      // Chỉ có 1 notification → Gửi bình thường
      _notificationController.add(_batchBuffer.first);
    } else {
      // Nhiều notifications → Gửi notification đầu tiên (đại diện cho batch)
      _notificationController.add(_batchBuffer.first);
    }

    // Clear buffer
    _batchBuffer.clear();
  }

  /// Lấy auth token
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');

      if (userDataJson != null) {
        // Token thường được lưu trong user_data sau khi login
        // Bạn cần adjust theo cách lưu token của mình
        return prefs.getString('auth_token');
      }
      return null;
    } catch (e) {
      print('❌ Error getting auth token: $e');
      return null;
    }
  }

  /// Lưu unread count vào local storage
  Future<void> _saveUnreadCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('unread_notification_count', count);
    } catch (e) {
      print('❌ Error saving unread count: $e');
    }
  }

  /// Load unread count từ local storage
  Future<void> _loadUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _unreadCount = prefs.getInt('unread_notification_count') ?? 0;
    } catch (e) {
      print('❌ Error loading unread count: $e');
    }
  }

  /// Lưu notification vào local storage
  Future<void> _saveNotificationLocally(
      CrawlNotification notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('notifications') ?? [];

      // Lưu tối đa 100 notifications
      if (notifications.length >= 100) {
        notifications.removeLast();
      }

      notifications.insert(0, json.encode(notification.toJson()));
      await prefs.setStringList('notifications', notifications);
      
      // Lưu unread count
      await _saveUnreadCount(_unreadCount);
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  /// Load notifications từ local storage
  Future<void> loadLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('notifications') ?? [];

      _notifications.clear();
      for (final jsonStr in notifications) {
        try {
          final data = json.decode(jsonStr) as Map<String, dynamic>;
          _notifications.add(CrawlNotification.fromJson(data));
        } catch (e) {
          print('⚠️ Error parsing notification: $e');
        }
      }

      // Load unread count
      await _loadUnreadCount();

      print('📱 Loaded ${_notifications.length} local notifications, $_unreadCount unread');
    } catch (e) {
      print('❌ Error loading local notifications: $e');
    }
  }

  /// Đánh dấu đã đọc
  void markAsRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
    }
  }

  /// Đánh dấu tất cả đã đọc
  void markAllAsRead() {
    _unreadCount = 0;
  }

  /// Reset unread count
  void resetUnreadCount() {
    _unreadCount = 0;
    _saveUnreadCount(0);
  }

  /// Xóa notification
  void removeNotification(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications.removeAt(index);
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
    }
  }

  /// Xóa tất cả notifications
  Future<void> clearAll() async {
    _notifications.clear();
    _unreadCount = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
  }

  /// Ngắt kết nối
  Future<void> disconnect() async {
    try {
      await _connection?.stop();
      print('🔌 SignalR disconnected');
      _connectionStateController.add(false);
    } catch (e) {
      print('❌ Error disconnecting SignalR: $e');
    }
  }

  /// Dispose
  void dispose() {
    _batchTimer?.cancel(); // ✅ Cancel batch timer
    disconnect();
    _notificationController.close();
    _connectionStateController.close();
  }
}

