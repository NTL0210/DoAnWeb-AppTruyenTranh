import 'package:flutter/material.dart';
import '../data/services/notification_service.dart';
import '../data/models/crawl_notification.dart';
import '../data/services/auth_service.dart';
import '../data/services/comic_service.dart';
import 'book_details_screen.dart';

/// Màn hình hiển thị danh sách thông báo
class NotificationListScreen extends StatefulWidget {
  final NotificationService notificationService;

  const NotificationListScreen({
    super.key,
    required this.notificationService,
  });

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final List<CrawlNotification> _notifications = [];
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    
    // Load notifications cũ
    _notifications.addAll(widget.notificationService.allNotifications);
    
    // Kiểm tra login status
    _checkLoginStatus();
    
    // Reset unread count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.notificationService.resetUnreadCount();
    });
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await AuthService().isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1a1a2e) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Thông báo',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF16213e) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () {
                _showClearDialog();
              },
              tooltip: 'Xóa tất cả',
            ),
        ],
      ),
      body: StreamBuilder<CrawlNotification>(
        stream: widget.notificationService.notifications,
        builder: (context, snapshot) {
          // Thêm notification mới vào đầu danh sách
          if (snapshot.hasData && !_notifications.contains(snapshot.data!)) {
            _notifications.insert(0, snapshot.data!);
          }

          if (_notifications.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _notifications.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return _buildNotificationCard(notification, isDark, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔔 GIF Animation - Full Width
            SizedBox(
              width: double.infinity,
              child: Image.asset(
                'lib/Loading/14-august-ahh.gif',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Chưa có thông báo',
              style: TextStyle(
                fontSize: 22,
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isLoggedIn 
                ? 'Bạn sẽ nhận được thông báo khi có truyện mới'
                : 'Bạn cần đăng nhập tài khoản để nhận thông báo',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(CrawlNotification notification, bool isDark, int index) {
    final isSuggestion = notification.isSuggestion;
    final isNewComic = notification.isNewComic;
    final isFollowed = notification.isFollowed;

    // Badge màu sắc
    Color badgeColor;
    IconData badgeIcon;
    String badgeLabel;

    if (isSuggestion) {
      badgeColor = Colors.orange;
      badgeIcon = Icons.recommend;
      badgeLabel = 'Gợi ý';
    } else if (isFollowed) {
      badgeColor = Colors.green;
      badgeIcon = Icons.favorite;
      badgeLabel = 'Theo dõi';
    } else if (isNewComic) {
      badgeColor = Colors.blue;
      badgeIcon = Icons.fiber_new;
      badgeLabel = 'Mới';
    } else {
      badgeColor = Colors.purple;
      badgeIcon = Icons.update;
      badgeLabel = 'Cập nhật';
    }

    return Dismissible(
      key: Key('notification_${notification.comicId}_${notification.timestampUtc.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return true;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        final removedNotification = notification;
        setState(() {
          _notifications.removeAt(index);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xóa thông báo'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Hoàn tác',
              onPressed: () {
                setState(() {
                  _notifications.insert(index, removedNotification);
                });
              },
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () async {
          print('📱 Tapped notification: ${notification.comicName}');
          print('📱 Comic ID: ${notification.comicId}');
          print('📱 Comic Slug: ${notification.comicSlug}');
          
          // ✅ ƯU TIÊN slug trước (vì slug luôn lấy được đầy đủ chapters)
          String? slugToUse = notification.comicSlug;
          
          // 🔍 Nếu không có slug, fetch comic từ comicId để lấy slug
          if (slugToUse == null || slugToUse.isEmpty) {
            print('⚠️ No slug in notification, fetching comic details...');
            
            // Show loading
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang tải thông tin truyện...'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
            
            try {
              final comic = await ComicService().fetchComicDetails(notification.comicId);
              if (comic != null && comic.slug.isNotEmpty) {
                slugToUse = comic.slug;
                print('✅ Fetched slug from API: $slugToUse');
              }
            } catch (e) {
              print('❌ Error fetching comic details: $e');
            }
          }
          
          // Navigate với slug (ưu tiên) hoặc comicId (fallback)
          if (!context.mounted) return;
          
          if (slugToUse != null && slugToUse.isNotEmpty) {
            print('🔹 Navigating with slug: $slugToUse');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookDetailsScreen(
                  slug: slugToUse,
                ),
              ),
            );
          } else if (notification.comicId.isNotEmpty) {
            print('🔹 Fallback: Navigating with comicId: ${notification.comicId}');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookDetailsScreen(
                  comicId: notification.comicId,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Không tìm thấy thông tin truyện'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📚 ICON ĐƠN GIẢN (không dùng ảnh để tránh lỗi)
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withOpacity(0.3), width: 1.5),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: badgeColor,
                  size: 35,
                ),
              ),
              const SizedBox(width: 12),
              
              // CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: badgeColor, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            badgeIcon,
                            size: 14,
                            color: badgeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badgeLabel,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Title
                    Text(
                      notification.comicName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Chapter info
                    if (notification.chapterName != null || notification.chapterIndex != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          notification.chapterName ?? 'Chap ${notification.chapterIndex}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Timestamp
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(notification.timestampUtc),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final local = timestamp.toLocal();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      final day = local.day.toString().padLeft(2, '0');
      final month = local.month.toString().padLeft(2, '0');
      final year = local.year;
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả thông báo'),
        content: const Text('Bạn có chắc muốn xóa tất cả thông báo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              widget.notificationService.clearAll();
              Navigator.pop(context);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
