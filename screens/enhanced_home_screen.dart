import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../data/services/auth_service.dart';
import '../data/services/comic_service.dart';
import '../data/services/comic_cache_service.dart';
import '../data/services/notification_service.dart';
import '../data/models/crawl_notification.dart'; // ✅ SignalR model
import '../data/models/comic.dart';
import '../data/models/genre.dart';
import 'book_details_screen.dart';
import 'explore_screen.dart';
import 'booklist_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'notification_list_screen.dart';

// Mock Data Classes
class Book {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final String genre;
  final double progress;
  final double rating;
  final int pages;
  final String description;
  final bool isCompleted;
  final DateTime lastRead;
  final String type; // Novel, Light Novel, Manga, Comic

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.genre,
    required this.progress,
    required this.rating,
    required this.pages,
    required this.description,
    required this.isCompleted,
    required this.lastRead,
    required this.type,
  });
}

class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int points;
  final int booksRead;
  final int currentStreak;
  final List<String> favoriteGenres;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.points,
    required this.booksRead,
    required this.currentStreak,
    required this.favoriteGenres,
  });
}

class MockData {
  static final List<Book> recommendedBooks = [
    Book(
      id: '1',
      title: 'Eighty-six vol 9: Valkyrie Has Landed',
      author: 'Asato Asato',
      coverUrl: 'https://via.placeholder.com/150x200/2563EB/FFFFFF?text=86',
      genre: 'Action Drama Mecha',
      progress: 0.0,
      rating: 4.8,
      pages: 320,
      description: 'In a world where the Eighty-Sixth Sector has been abandoned by the Republic, Shin and his fellow Eighty-Six fight against the Legion.',
      isCompleted: false,
      lastRead: DateTime.now().subtract(const Duration(days: 1)),
      type: 'Light Novel',
    ),
    Book(
      id: '2',
      title: 'Maze Runner: The Scorch Trials',
      author: 'James Dashner',
      coverUrl: 'https://via.placeholder.com/150x200/7C3AED/FFFFFF?text=MR',
      genre: 'Sci-fi Thriller',
      progress: 0.0,
      rating: 4.2,
      pages: 360,
      description: 'Thomas and his friends must face the Scorch, a burned-out wasteland filled with dangerous obstacles.',
      isCompleted: false,
      lastRead: DateTime.now().subtract(const Duration(days: 3)),
      type: 'Novel',
    ),
    Book(
      id: '3',
      title: 'The Fragrant Blooms With',
      author: 'Unknown',
      coverUrl: 'https://via.placeholder.com/150x200/059669/FFFFFF?text=FB',
      genre: 'Romance Slice of Life',
      progress: 0.0,
      rating: 4.5,
      pages: 200,
      description: 'A heartwarming story about personal growth and relationships.',
      isCompleted: false,
      lastRead: DateTime.now().subtract(const Duration(days: 5)),
      type: 'Light Novel',
    ),
  ];

  static final List<Book> ourPickBooks = [
    Book(
      id: '4',
      title: 'The Alchemist',
      author: 'Paulo Coelho',
      coverUrl: 'https://via.placeholder.com/150x200/EA580C/FFFFFF?text=AL',
      genre: 'Philosophy Fiction',
      progress: 0.0,
      rating: 4.7,
      pages: 180,
      description: 'A philosophical novel about a young shepherd\'s journey to find his personal legend.',
      isCompleted: false,
      lastRead: DateTime.now().subtract(const Duration(days: 2)),
      type: 'Novel',
    ),
    Book(
      id: '5',
      title: 'Eragon',
      author: 'Christopher Paolini',
      coverUrl: 'https://via.placeholder.com/150x200/F97316/FFFFFF?text=ER',
      genre: 'Fantasy Adventure',
      progress: 0.0,
      rating: 4.6,
      pages: 500,
      description: 'A young farm boy discovers a dragon egg and becomes a Dragon Rider.',
      isCompleted: false,
      lastRead: DateTime.now().subtract(const Duration(days: 4)),
      type: 'Novel',
    ),
    Book(
      id: '6',
      title: 'Deception Point',
      author: 'Dan Brown',
      coverUrl: 'https://via.placeholder.com/150x200/8B5CF6/FFFFFF?text=DP',
      genre: 'Thriller Mystery',
      progress: 0.0,
      rating: 4.3,
      pages: 400,
      description: 'A NASA discovery threatens to change the world forever.',
      isCompleted: false,
      lastRead: DateTime.now().subtract(const Duration(days: 6)),
      type: 'Novel',
    ),
  ];

  static final User currentUser = User(
    id: '1',
    name: 'Cheyenne Curtis',
    email: 'cheyenne@example.com',
    avatarUrl: 'https://via.placeholder.com/100x100/2563EB/FFFFFF?text=CC',
    points: 1200,
    booksRead: 22,
    currentStreak: 7,
    favoriteGenres: ['Light Novel', 'Fantasy', 'Romance'],
  );
}

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> 
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final User _currentUser = MockData.currentUser;
  bool _isLoggedIn = false; // Mặc định là guest
  
  // ✅ Animation controller cho hiệu ứng lắc chuông
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isLoadingHome = true;
  String? _homeError;
  List<ComicItem> _homeComics = [];
  // Danh sách thông báo chưa đọc; nếu không rỗng sẽ hiển thị chấm đỏ trên icon chuông
  List<String> _notifications = const [];
  // Pagination state for "Cập nhật gần đây"
  int _currentPage = 1;
  int _perPage = 30; // 30 bộ truyện mỗi trang
  int? _totalPages; // lấy từ API nếu có
  int? _totalItems; // tổng số kết quả nếu API trả về
  // Đệm trang để chuyển trang mượt hơn
  final Map<int, List<ComicItem>> _pageCache = {};
  // Gợi ý hôm nay
  List<ComicItem> _suggestions = [];
  bool _loadingSuggestions = false;
  final PageController _bannerController = PageController(viewportFraction: 0.92);
  int _bannerIndex = 0;
  Timer? _autoBannerTimer;
  Timer? _autoBannerRestartDelay;

  // ✅ SignalR Notification Service
  late NotificationService _notificationService;
  int _unreadNotifications = 0;

  // Removed old API constants, now using ApiService

  @override
  void initState() {
    super.initState();
    
    // ✅ Khởi tạo animation lắc chuông
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          if (_unreadNotifications > 0) {
            // Tiếp tục lắc nếu vẫn còn thông báo
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _unreadNotifications > 0) {
                _shakeController.forward();
              }
            });
          }
        }
      });
    
    _fetchHomeComics(page: _currentPage);
    _initNotificationService(); // ✅ Khởi tạo SignalR
  }

  // ✅ Khởi tạo SignalR notification service
  Future<void> _initNotificationService() async {
    _notificationService = NotificationService();
    
    // Load thông báo cũ từ local
    await _notificationService.loadLocalNotifications();
    
    // Lắng nghe thông báo mới
    _notificationService.notifications.listen((notification) {
      if (mounted) {
        setState(() {
          _unreadNotifications = _notificationService.unreadCount;
        });
        
        // ✅ Bắt đầu lắc chuông khi có thông báo mới
        if (_unreadNotifications > 0) {
          _shakeController.forward();
        }
        
        // ✅ Hiển thị snackbar gộp
        final batchCount = _notificationService.unreadCount;
        final message = batchCount > 1
            ? '🔔 Có $batchCount truyện mới cập nhật!'
            : (notification.isSuggestion
                ? '📢 Gợi ý: ${notification.comicName}'
                : '🔔 ${notification.comicName} - ${notification.chapterName}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: notification.isSuggestion
                ? Colors.orange
                : (notification.isFollowed ? Colors.green : Colors.blue),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Xem',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to notification list
                _notificationService.resetUnreadCount();
                setState(() {
                  _unreadNotifications = 0;
                });
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationListScreen(
                      notificationService: _notificationService,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    });
    
    // Kết nối SignalR nếu đã login
    final isLoggedIn = await AuthService().isLoggedIn();
    if (isLoggedIn) {
      await _notificationService.connect();
      if (mounted) {
        setState(() {
          _unreadNotifications = _notificationService.unreadCount;
        });
        
        // ✅ Bắt đầu lắc nếu đã có thông báo chưa đọc
        if (_unreadNotifications > 0) {
          _shakeController.forward();
        }
      }
    }
  }
  
  // Thêm method để check cache và load nếu cần
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kiểm tra xem có data trong cache không
    _checkAndLoadFromCache();
  }
  
  void _checkAndLoadFromCache() {
    // Nếu đã có data trong cache và không đang loading
    if (_homeComics.isNotEmpty && !_isLoadingHome) {
      print('💾 Home data already loaded from cache');
      return;
    }
    
    // Kiểm tra xem có data trong global cache không
    if (ComicCacheService().hasCachedData()) {
      print('💾 Found cached data: ${ComicCacheService().getCachedPagesCount()} pages, ${ComicCacheService().getTotalCachedComics()} comics');
      // Load từ cache thay vì gọi API
      _loadFromGlobalCache();
    } else {
      // Nếu chưa có data, load từ API
      if (_homeComics.isEmpty) {
        _fetchHomeComics(page: _currentPage);
      }
    }
  }
  
  // Load data từ global cache
  void _loadFromGlobalCache() {
    // Lấy data từ global cache
    final cachedComics = ComicCacheService().getCachedComics(1);
    if (cachedComics != null && cachedComics.isNotEmpty) {
      print('💾 Loading ${cachedComics.length} comics from global cache');
      
      // Convert Comic to ComicItem
      final List<ComicItem> parsed = cachedComics.map((comic) {
        final comicItem = comic.toComicItem();
        return ComicItem(
          id: comicItem['id'] as String,
          name: comicItem['name'] as String,
          slug: comicItem['slug'] as String,
          thumbUrl: comicItem['thumbUrl'] as String?,
          categories: (comicItem['categories'] as List<dynamic>).map((cat) => ComicItemCategory(
            id: cat['id'] as String,
            name: cat['name'] as String,
            slug: cat['slug'] as String,
          )).toList(),
          chapterName: comicItem['chapterName'] as String?,
        );
      }).toList();
      
      if (mounted) {
        setState(() {
          _homeComics = parsed;
          _isLoadingHome = false;
          _currentPage = 1;
          _totalPages = 20;
          _homeError = null;
        });
        print('✅ Loaded ${parsed.length} comics from global cache');
      }
    }
  }
  
  // Thêm method để refresh cache khi cần
  void _refreshCache() {
    ComicCacheService().forceRefresh();
    _fetchHomeComics(page: _currentPage, forceRefresh: true);
  }

  Future<void> _fetchHomeComics({int page = 1, bool forceRefresh = false}) async {
    // Nếu trang đã có trong cache thì hiển thị ngay để tránh giật lag
    final List<ComicItem>? cached = _pageCache[page];
    if (cached != null && mounted) {
      setState(() {
        _homeComics = cached;
        _currentPage = page;
        _isLoadingHome = true; // vẫn đặt loading để cập nhật dữ liệu mới trong nền
        _homeError = null;
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoadingHome = true;
          _homeError = null;
        });
      }
    }

    try {
      print('=== Fetching home comics from API, page: $page ===');
      
      List<Comic> comics;
      if (page == 1 && _pageCache.isEmpty) {
        // Lần đầu tiên, lấy tất cả comics từ tất cả 20 trang
        print('First load: fetching all comics from all 20 pages...');
        comics = await ComicService().fetchAllComics();
        print('✅ Fetched ${comics.length} comics from all pages');
        
        // Chia thành các trang và cache
        for (int i = 0; i < 20; i++) {
          final startIndex = i * _perPage;
          final endIndex = (startIndex + _perPage).clamp(0, comics.length);
          if (startIndex < comics.length) {
            final pageComics = comics.sublist(startIndex, endIndex);
            final pageItems = pageComics.map((comic) {
              final comicItem = comic.toComicItem();
              return ComicItem(
                id: comicItem['id'] as String,
                name: comicItem['name'] as String,
                slug: comicItem['slug'] as String,
                thumbUrl: comicItem['thumbUrl'] as String?,
                categories: (comicItem['categories'] as List<dynamic>).map((cat) => ComicItemCategory(
                  id: cat['id'] as String,
                  name: cat['name'] as String,
                  slug: cat['slug'] as String,
                )).toList(),
                chapterName: comicItem['chapterName'] as String?,
              );
            }).toList();
            _pageCache[i + 1] = pageItems;
          }
        }
      } else {
        // Sử dụng cache hoặc lấy trang cụ thể
        comics = await ComicService().fetchComics(page: page, forceRefresh: forceRefresh);
      }
      
      // Convert Comic to ComicItem
      final List<ComicItem> parsed = comics.map((comic) {
        print('Converting comic: ${comic.name}');
        final comicItem = comic.toComicItem();
        print('Comic item data: $comicItem');
        
        return ComicItem(
          id: comicItem['id'] as String,
          name: comicItem['name'] as String,
          slug: comicItem['slug'] as String,
          thumbUrl: comicItem['thumbUrl'] as String?,
          categories: (comicItem['categories'] as List<dynamic>).map((cat) => ComicItemCategory(
            id: cat['id'] as String,
            name: cat['name'] as String,
            slug: cat['slug'] as String,
          )).toList(),
          chapterName: comicItem['chapterName'] as String?,
        );
      }).toList();
      
      print('✅ Converted ${parsed.length} comics to ComicItem');

      if (!mounted) return;
      setState(() {
        // Đảm bảo đúng 20 item mỗi trang nếu API trả nhiều hơn
        _homeComics = parsed.take(_perPage).toList();
        _isLoadingHome = false;
        _currentPage = page;
        _totalPages = 20; // New API has 20 pages
        _totalItems = _pageCache.values.fold(0, (sum, list) => (sum ?? 0) + (list?.length ?? 0)); // Total from cache
        _homeError = null; // Clear any previous errors
        // Lưu cache trang
        _pageCache[page] = _homeComics;
      });

      print('✅ Successfully loaded ${_homeComics.length} comics for page $page');
      print('✅ Home comics list: ${_homeComics.map((c) => c.name).toList()}');

      // Chuẩn bị gợi ý
      _prepareSuggestions();

      // Prefetch trang kế tiếp để chuyển trang mượt hơn
      final int nextPage = page + 1;
      if (_pageCache[nextPage] == null) {
        _prefetchPage(nextPage);
      }
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      if (!mounted) return;
      setState(() {
        _homeError = 'Kết nối quá thời gian (timeout). Vui lòng thử lại.';
        _isLoadingHome = false;
      });
    } on SocketException catch (e) {
      print('❌ Socket error: $e');
      if (!mounted) return;
      setState(() {
        _homeError = 'Không có Internet hoặc bị chặn (SocketException).';
        _isLoadingHome = false;
      });
    } catch (e) {
      print('❌ General error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error details: ${e.toString()}');
      if (!mounted) return;
      setState(() {
        _homeError = 'Lỗi: $e';
        _isLoadingHome = false;
      });
    }
  }
  Future<List<ComicItem>> _fetchRecentPage(int page) async {
    try {
      // Sử dụng API mới
      final List<Comic> comics = await ComicService().fetchComics(page: page);
      
      // Convert Comic to ComicItem
      return comics.map((comic) {
        final comicItem = comic.toComicItem();
        return ComicItem(
          id: comicItem['id'] as String,
          name: comicItem['name'] as String,
          slug: comicItem['slug'] as String,
          thumbUrl: comicItem['thumbUrl'] as String?,
          categories: (comicItem['categories'] as List<dynamic>).map((cat) => ComicItemCategory(
            id: cat['id'] as String,
            name: cat['name'] as String,
            slug: cat['slug'] as String,
          )).toList(),
          chapterName: comicItem['chapterName'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Error fetching recent page $page: $e');
      return [];
    }
  }

  Future<void> _prepareSuggestions() async {
    if (!mounted) return;
    setState(() {
      _loadingSuggestions = true;
    });

    List<ComicItem> pool = _homeComics
        .where((c) => (c.chapterName != null && c.chapterName!.isNotEmpty))
        .toList();

    // Nếu chưa đủ, thử lấy thêm từ vài trang kế tiếp để đảm bảo luôn có gợi ý
    int tryPage = _currentPage + 1;
    int attempts = 0;
    final int maxAttempts = 3;
    while (pool.length < 5 && attempts < maxAttempts) {
      final extra = await _fetchRecentPage(tryPage);
      if (extra.isEmpty) break;
      pool.addAll(extra.where((c) => (c.chapterName != null && c.chapterName!.isNotEmpty)));
      tryPage++;
      attempts++;
    }

    if (pool.isNotEmpty) {
      pool.shuffle(Random());
      if (!mounted) return;
      setState(() {
        _suggestions = pool.take(5).toList();
        _loadingSuggestions = false;
      });
      // Bắt đầu auto-scroll khi đã có gợi ý
      _scheduleNextBannerAutoScroll();
    } else {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _loadingSuggestions = false;
      });
    }
  }


  Future<void> _prefetchPage(int page) async {
    try {
      // Sử dụng API mới
      final List<Comic> comics = await ComicService().fetchComics(page: page);
      
      // Convert Comic to ComicItem
      final List<ComicItem> parsed = comics.map((comic) {
        final comicItem = comic.toComicItem();
        return ComicItem(
          id: comicItem['id'] as String,
          name: comicItem['name'] as String,
          slug: comicItem['slug'] as String,
          thumbUrl: comicItem['thumbUrl'] as String?,
          categories: (comicItem['categories'] as List<dynamic>).map((cat) => ComicItemCategory(
            id: cat['id'] as String,
            name: cat['name'] as String,
            slug: cat['slug'] as String,
          )).toList(),
          chapterName: comicItem['chapterName'] as String?,
        );
      }).toList();
      
      _pageCache[page] = parsed.take(_perPage).toList();
    } catch (e) {
      print('Prefetch error for page $page: $e');
      // ignore prefetch errors silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchHomeComics,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildTopBar(),
                _buildRandomSuggestions(),
                const SizedBox(height: 12),
                _buildQuickStats(),
                const SizedBox(height: 12),
                _buildRecentUpdatesSection(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildTopBar() {
    final languageProvider = LanguageProvider.of(context);
    if (languageProvider == null) {
      return const SizedBox.shrink();
    }
    
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // App logo and title
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.menu_book,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StoryVerse',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Khám phá thế giới truyện tranh',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // ✅ Notification (bell) icon with SignalR badge
          GestureDetector(
            onTap: () {
              // Reset unread count
              _notificationService.resetUnreadCount();
              setState(() {
                _unreadNotifications = 0;
              });
              
              // ✅ Dừng animation lắc chuông
              _shakeController.stop();
              _shakeController.reset();
              
              // Navigate to notification list
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationListScreen(
                    notificationService: _notificationService,
                  ),
                ),
              );
            },
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _shakeAnimation.value * 0.1, // Lắc theo góc
                  child: child,
                );
              },
              child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.notifications_none,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                // ✅ SignalR notification badge
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRandomSuggestions() {
    if (_isLoadingHome || _homeError != null || _homeComics.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Hiển thị banner với truyện từ API
    final List<ComicItem> top = _homeComics.take(5).toList();
    if (top.isEmpty) {
      return const SizedBox.shrink();
    }

    // Banner theo mẫu: PageView ngang, mỗi item là card lớn với ảnh + title overlay + dot indicator
    return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Truyện nổi bật',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: GestureDetector(
            onTapDown: (_) => _onUserBannerInteraction(),
            onHorizontalDragStart: (_) => _onUserBannerInteraction(),
            onHorizontalDragUpdate: (_) {},
            onHorizontalDragEnd: (_) => _onUserBannerInteractionEnded(),
            child: PageView.builder(
              controller: _bannerController,
              itemCount: top.length,
              onPageChanged: (i) {
                setState(() => _bannerIndex = i);
              },
              itemBuilder: (context, index) {
                final item = top[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () {
                      _onUserBannerInteraction();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailsScreen(slug: item.slug),
                        ),
                      );
                      _onUserBannerInteractionEnded();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (item.thumbUrl != null)
                              Image.network(item.thumbUrl!, fit: BoxFit.cover)
                            else
                              Container(color: Theme.of(context).primaryColor.withOpacity(0.1)),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black54,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(top.length, (i) {
            final bool active = i == _bannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 10 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? Theme.of(context).primaryColor : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Tổng truyện',
              '${_totalItems ?? 0} Truyện',
              Icons.library_books,
              Theme.of(context).primaryColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.dividerColor,
          ),
          Expanded(
            child: _buildStatItem(
              'Trang hiện tại',
              'Trang $_currentPage',
              Icons.pages,
              AppTheme.primaryOrange,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.dividerColor,
          ),
          Expanded(
            child: _buildStatItem(
              'Tổng trang',
              '20 Trang',
              Icons.bookmark,
              AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentUpdatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cập nhật gần đây',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingHome)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (_homeError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lỗi tải dữ liệu: $_homeError', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: () => _fetchHomeComics(page: _currentPage), child: const Text('Thử lại')),
              ],
            ),
          )
        else ...[
          // Grid 2 cột, hiển thị truyện từ API
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: _homeComics.length,
              itemBuilder: (context, index) {
                return _buildCompactComicCard(_homeComics[index]);
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildPaginationBar(),
        ],
      ],
    );
  }

  Widget _buildPaginationBar() {
    // Tính tổng số trang (ưu tiên totalPages, fallback từ totalItems/_perPage)
    final int? lastPage = _totalPages ?? (_totalItems != null
        ? ((_totalItems! + _perPage - 1) ~/ _perPage)
        : null);
    final bool canGoPrev = _currentPage > 1 && !_isLoadingHome;
    final bool canGoNext = !_isLoadingHome && (lastPage == null
        ? _homeComics.length >= _perPage
        : _currentPage < lastPage);

    // Hiển thị tối đa 4 ô: current, next, ellipsis, last
    final int current = _currentPage;
    final int? next = (lastPage == null) ? current + 1 : (current < lastPage ? current + 1 : null);
    final bool showTrailing = lastPage != null && next != null && next < lastPage;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
          child: Row(
          mainAxisSize: MainAxisSize.min,
            children: [
            _buildPageChip(label: '<<', enabled: canGoPrev, onTap: () {
              if (canGoPrev) _fetchHomeComics(page: current - 1);
            }),
            const SizedBox(width: 8),
            _buildPageNumber(current),
            if (next != null) ...[
              const SizedBox(width: 8),
              _buildPageNumber(next),
            ],
            if (showTrailing) ...[
              const SizedBox(width: 8),
              _buildEllipsisButton(),
              const SizedBox(width: 8),
              _buildPageNumber(lastPage!),
            ],
            const SizedBox(width: 8),
            _buildPageChip(label: '>>', enabled: canGoNext, onTap: () {
              if (canGoNext) _fetchHomeComics(page: current + 1);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPageNumber(int pageNumber) {
    final bool isActive = pageNumber == _currentPage;
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          _fetchHomeComics(page: pageNumber);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.red.shade600 : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: AppTheme.cardShadow,
        ),
                child: Text(
          '$pageNumber',
          style: TextStyle(
            color: isActive ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPageChip({required String label, required bool enabled, required VoidCallback onTap}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsisButton() {
    return GestureDetector(
      onTap: () {
        _showGoToPageDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Text(
          '...',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _showGoToPageDialog() async {
    final TextEditingController controller = TextEditingController(text: '$_currentPage');
    final int maxPage = _totalPages ?? 9999;
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Go to Page...'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Page (1 - $maxPage)',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final int? page = int.tryParse(controller.text);
                if (page != null && page >= 1 && page <= maxPage) {
                  Navigator.pop(context, page);
                }
              },
              child: const Text('Go'),
          ),
      ],
    );
      },
    );
    if (result != null) {
      _fetchHomeComics(page: result);
    }
  }

  Widget _buildHorizontalComicCard(ComicItem comic) {
    final String? firstCategory = comic.categories.isNotEmpty ? comic.categories.first.name : null;
    final String typeLabel = comic.typeLabel;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsScreen(slug: comic.slug),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: comic.thumbUrl != null
                      ? DecorationImage(image: NetworkImage(comic.thumbUrl!), fit: BoxFit.cover)
                      : null,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: Stack(
                  children: [
                    if (comic.thumbUrl == null)
                      Center(
                        child: Icon(
                          Icons.menu_book,
                          color: Theme.of(context).primaryColor,
                          size: 30,
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comic.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comic.latestChapterLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        firstCategory ?? 'Comic',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactComicCard(ComicItem comic) {
    final String? firstCategory = comic.categories.isNotEmpty ? comic.categories.first.name : null;
    final String typeLabel = comic.typeLabel;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsScreen(slug: comic.slug),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: comic.thumbUrl != null
                      ? DecorationImage(image: NetworkImage(comic.thumbUrl!), fit: BoxFit.cover)
                      : null,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: Stack(
                  children: [
                    if (comic.thumbUrl == null)
                      const Center(
                        child: Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comic.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comic.latestChapterLabel,
                      style: Theme.of(context).textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              firstCategory ?? 'Comic',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBookCard(Book book) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsScreen(book: book),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.8),
                      Theme.of(context).primaryColor.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.book,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    // Rating badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              book.rating.toString(),
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Type badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book.type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Book info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: Theme.of(context).textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              book.genre,
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        
        // Navigate to different screens based on selected index
        switch (index) {
          case 0:
            // Already on Home screen - do nothing
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExploreScreen()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BookListScreen()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
      selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
      unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books),
          label: 'Book list',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  void _onUserBannerInteraction() {
    // Dừng auto-scroll ngay khi người dùng tương tác
    _autoBannerTimer?.cancel();
    _autoBannerRestartDelay?.cancel();
  }

  void _onUserBannerInteractionEnded() {
    // Sau khi tương tác xong, chờ 1s rồi mới bắt đầu đếm lại 5s
    _autoBannerRestartDelay?.cancel();
    _autoBannerRestartDelay = Timer(const Duration(seconds: 1), () {
      _scheduleNextBannerAutoScroll();
    });
  }

  void _scheduleNextBannerAutoScroll() {
    _autoBannerTimer?.cancel();
    // Nếu chưa có dữ liệu hoặc ít hơn 2 item thì không cần auto-scroll
    if (!mounted || _suggestions.length < 2) return;
    _autoBannerTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      final int total = _suggestions.length;
      final int nextIndex = (_bannerIndex + 1) % total;
      _bannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      // Lên lịch lần kế tiếp
      _scheduleNextBannerAutoScroll();
    });
  }

  @override
  void dispose() {
    _autoBannerTimer?.cancel();
    _autoBannerRestartDelay?.cancel();
    _bannerController.dispose();
    _shakeController.dispose(); // ✅ Dispose shake animation
    _notificationService.dispose(); // ✅ Đóng SignalR connection
    super.dispose();
  }
}

class ComicItemCategory {
  final String id;
  final String name;
  final String slug;

  ComicItemCategory({required this.id, required this.name, required this.slug});

  factory ComicItemCategory.fromJson(Map<String, dynamic> json) {
    return ComicItemCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }
}

class ComicItem {
  final String id;
  final String name;
  final String slug;
  final String? thumbUrl; // full CDN url
  final List<ComicItemCategory> categories;
  final String? chapterName; // latest

  ComicItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.thumbUrl,
    required this.categories,
    required this.chapterName,
  });

  factory ComicItem.fromJson(Map<String, dynamic> json, String cdnBase) {
    final String thumbFile = (json['thumb_url'] ?? '').toString();
    final String? fullThumb = thumbFile.isNotEmpty ? '$cdnBase/uploads/comics/$thumbFile' : null;
    final List<dynamic> catRaw = (json['category'] as List<dynamic>?) ?? [];
    String? latestChapter;
    final List<dynamic> latest = (json['chaptersLatest'] as List<dynamic>?) ?? [];
    if (latest.isNotEmpty) {
      final Map<String, dynamic> c = latest.first as Map<String, dynamic>;
      latestChapter = (c['chapter_name'] ?? '').toString();
    }
    return ComicItem(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      thumbUrl: fullThumb,
      categories: catRaw.map((e) => ComicItemCategory.fromJson(e as Map<String, dynamic>)).toList(),
      chapterName: latestChapter,
    );
  }

  String get latestChapterLabel => chapterName == null || chapterName!.isEmpty ? '—' : 'Chap $chapterName';

  String get typeLabel {
    final lowerCats = categories.map((c) => c.slug.toLowerCase()).toList();
    if (lowerCats.contains('manhwa')) return 'Manhwa';
    if (lowerCats.contains('manhua')) return 'Manhua';
    if (lowerCats.contains('manga')) return 'Manga';
    return 'Comic';
  }
}