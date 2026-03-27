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
import '../data/repositories/comic_repository.dart';
import '../data/states/comic_data_state.dart';
import '../data/models/crawl_notification.dart'; // ✅ SignalR model
import '../data/models/comic.dart';
import '../data/models/genre.dart';
import 'book_details_screen.dart';
import 'explore_screen.dart';
import 'booklist_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'notification_list_screen.dart';
import '../widgets/common_bottom_nav.dart';

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
  String? _homeStatusMessage;
  List<ComicItem> _homeComics = [];
  // Danh sách thông báo chưa đọc; nếu không rỗng sẽ hiển thị chấm đỏ trên icon chuông
  List<String> _notifications = const [];
  // Pagination state for "Cập nhật gần đây"
  int _currentPage = 1;
  int _perPage = 20; // 20 bộ truyện mỗi trang
  int? _totalPages; // lấy từ API nếu có
  int? _totalItems; // tổng số kết quả nếu API trả về
  bool _isEstimatingTotalPages = false;
  // Đệm trang để chuyển trang mượt hơn
  final Map<int, List<ComicItem>> _pageCache = {};
  // Gợi ý hôm nay
  List<ComicItem> _suggestions = [];
  bool _loadingSuggestions = false;
  final PageController _bannerController = PageController(viewportFraction: 0.92);
  int _bannerIndex = 0;
  Timer? _autoBannerTimer;
  Timer? _autoBannerRestartDelay;
  Timer? _homeFetchTimeout;

  String _t(String key) {
    final provider = LanguageProvider.of(context);
    return provider?.translate(key) ?? LanguageManager.translate(key);
  }

  // ✅ SignalR Notification Service
  late NotificationService _notificationService;
  int _unreadNotifications = 0;

  // Stream subscription cho phần lấy dữ liệu trang chủ
  StreamSubscription<ComicDataState>? _comicsSubscription;

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
          ? '🔔 ${_t('new_comics_updated')}: $batchCount'
          : (notification.isSuggestion
            ? '📢 ${_t('suggestion_prefix')}: ${notification.comicName}'
            : '🔔 ${notification.comicName} - ${notification.chapterName}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: notification.isSuggestion
                ? Colors.orange
                : (notification.isFollowed ? Colors.green : Colors.blue),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: _t('view'),
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
          final pagination = ComicService.lastPagination;
          if (pagination?.pageSize != null && pagination!.pageSize! > 0) {
            _perPage = pagination.pageSize!;
          }
          _totalPages = pagination?.totalPages ?? _totalPages;
          _totalItems = pagination?.totalItems ?? _totalItems;
          _homeError = null;
          _homeStatusMessage = null;
        });
        print('✅ Loaded ${parsed.length} comics from global cache');
        _maybeEstimateTotalPages();
      }
    }
  }

  // Thêm method để refresh cache khi cần
  void _refreshCache() {
    ComicCacheService().forceRefresh();
    _fetchHomeComics(page: _currentPage, forceRefresh: true);
  }

  Future<void> _fetchHomeComics({int page = 1, bool forceRefresh = false}) async {
    if (forceRefresh) {
      ComicRepository().cancelAllResilientStreams();
    }
    
    _comicsSubscription?.cancel();
    final bool shouldShowLoader = _homeComics.isEmpty;

    if (mounted) {
      setState(() {
        _isLoadingHome = shouldShowLoader;
        if (shouldShowLoader) {
          _homeError = null;
          _homeStatusMessage = null;
        }
      });
    }

    _homeFetchTimeout?.cancel();
    if (shouldShowLoader) {
      _homeFetchTimeout = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        if (_isLoadingHome) {
          _useMockHomeData(
            reason: 'Không thể kết nối máy chủ, đang hiển thị dữ liệu mẫu.',
          );
        }
      });
    }

    print('=== Listening to home comics from Resilient Stream, page: $page ===');
    
    _comicsSubscription = ComicRepository().watchComics(page: page).listen((state) {
      if (!mounted) return;
      _homeFetchTimeout?.cancel();

      if (state is ComicLoaded) {
        final List<ComicItem> parsed = state.comics.map((comic) {
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

        setState(() {
          _homeComics = parsed.take(_perPage).toList();
          _isLoadingHome = false;
          _currentPage = page;
          final pagination = ComicService.lastPagination;
          if (pagination?.pageSize != null && pagination!.pageSize! > 0) {
            _perPage = pagination.pageSize!;
          }
          _totalPages = pagination?.totalPages ?? _totalPages;
          _totalItems = pagination?.totalItems ?? _totalItems;
          _homeError = null;
          _homeStatusMessage = state.isMock
              ? (state.statusMessage ?? 'Đang hiển thị dữ liệu mẫu (mất kết nối)')
              : null;
        });

        _maybeEstimateTotalPages();

        if (_suggestions.isEmpty) {
          _prepareSuggestions();
        }
      } else if (state is ComicFailed) {
        _useMockHomeData(reason: state.message);
      }
    });

    // Vẫn gọi prefetch trang kế tiếp để mượt mà (chỉ prefetch data, ko bind UI)
    final int nextPage = page + 1;
    if (_pageCache[nextPage] == null) {
      _prefetchPage(nextPage);
    }
  }

  int? get _effectiveTotalPages {
    if (_totalPages != null && _totalPages! > 0) return _totalPages;
    if (_totalItems != null && _totalItems! > 0) {
      return ((_totalItems! + _perPage - 1) ~/ _perPage);
    }
    return null;
  }

  String get _totalItemsLabel {
    if (_totalItems != null && _totalItems! > 0) return '$_totalItems';
    return '--';
  }

  void _maybeEstimateTotalPages() {
    if (_effectiveTotalPages != null || _isEstimatingTotalPages) return;
    _isEstimatingTotalPages = true;

    ComicService().estimateTotalPages().then((totalPages) {
      if (!mounted || totalPages == null) return;
      if (totalPages > 0) {
        setState(() {
          _totalPages = totalPages;
        });
      }
    }).whenComplete(() {
      _isEstimatingTotalPages = false;
    });
  }

  void _useMockHomeData({String? reason}) {
    final List<ComicItem> fallback = _buildMockHomeComics();
    if (!mounted) return;
    _homeFetchTimeout?.cancel();

    if (reason != null) {
      print('⚠️ Falling back to mock data: $reason');
    }

    if (fallback.isEmpty) {
      setState(() {
        _isLoadingHome = false;
        _homeError = reason ?? 'Không thể tải dữ liệu.';
        _homeStatusMessage = null;
      });
      return;
    }

    setState(() {
      _homeComics = fallback;
      _suggestions = fallback.take(5).toList();
      _loadingSuggestions = false;
      _isLoadingHome = false;
      _homeError = null;
      _homeStatusMessage =
          'Mất kết nối tới máy chủ, đang hiển thị dữ liệu mẫu để bạn tiếp tục đọc.';
      _currentPage = 1;
      _totalPages ??= 1;
    });
  }

  List<ComicItem> _buildMockHomeComics() {
    final List<Book> mockBooks = [
      ...MockData.recommendedBooks,
      ...MockData.ourPickBooks,
    ];

    return mockBooks.map((book) {
      final String titleSlug = _slugify(book.title);
      final String genreSlug = _slugify(book.genre);
      return ComicItem(
        id: 'mock-${book.id}',
        name: book.title,
        slug: titleSlug.isEmpty ? 'mock-${book.id}' : titleSlug,
        thumbUrl: book.coverUrl,
        categories: [
          ComicItemCategory(
            id: 'mock-genre-${book.id}',
            name: book.genre,
            slug: genreSlug.isEmpty ? 'mock' : genreSlug,
          ),
        ],
        chapterName: null,
      );
    }).toList();
  }

  String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        // Gradient nền nhẹ — sáng hoặc tối
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Colors.white, Color(0xFFF0F7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppTheme.darkDivider.withOpacity(0.4)
                : AppTheme.dividerColor.withOpacity(0.7),
            width: 1,
          ),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // App logo với glow shadow
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.blueShadow,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.heroGradient.createShader(bounds),
                  child: Text(
                    'StoryVerse',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white, // bị ShaderMask override
                    ),
                  ),
                ),
                Text(
                  _t('explore_comic_world'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextTertiary
                        : AppTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
          // ✅ Notification icon với viền gradient khi có thông báo
          GestureDetector(
            onTap: () {
              _notificationService.resetUnreadCount();
              setState(() => _unreadNotifications = 0);
              _shakeController.stop();
              _shakeController.reset();
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
              builder: (context, child) => Transform.rotate(
                angle: _shakeAnimation.value * 0.1,
                child: child,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: _unreadNotifications > 0
                          ? AppTheme.heroGradient
                          : null,
                      color: _unreadNotifications > 0
                          ? null
                          : (isDark
                              ? AppTheme.darkSurface
                              : AppTheme.lightBlue.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.darkDivider.withOpacity(0.5)
                            : AppTheme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _unreadNotifications > 0
                          ? Icons.notifications_rounded
                          : Icons.notifications_none_rounded,
                      color: _unreadNotifications > 0
                          ? Colors.white
                          : AppTheme.getBrandPrimary(context),
                      size: 20,
                    ),
                  ),
                  // ✅ Badge số thông báo
                  if (_unreadNotifications > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: AppTheme.orangeGradient,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          _unreadNotifications > 9
                              ? '9+'
                              : '$_unreadNotifications',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
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
        // Tiêu đề section với đường gạch gradient
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _t('featured_comics'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 185,
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
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.getBrandPrimary(context).withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (item.thumbUrl != null)
                              Image.network(item.thumbUrl!, fit: BoxFit.cover)
                            else
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: AppTheme.heroGradient,
                                ),
                              ),
                            // Overlay gradient 3-stop đẹp hơn
                            Container(
                              decoration: const BoxDecoration(
                                gradient: AppTheme.bannerOverlayGradient,
                              ),
                            ),
                            // Chapter badge góc trên trái
                            if (item.chapterName != null)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.heroGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Chap ${item.chapterName}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            // Tên truyện
                            Positioned(
                              left: 14,
                              right: 14,
                              bottom: 14,
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
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
        const SizedBox(height: 10),
        // Dot indicator gradient
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(top.length, (i) {
            final bool active = i == _bannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                gradient: active ? AppTheme.heroGradient : null,
                color: active ? null : Colors.grey.shade300,
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
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF2D3748)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.statsGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppTheme.darkDivider.withOpacity(0.4)
              : AppTheme.lightBlue.withOpacity(0.8),
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              _t('total_comics'),
              _totalItemsLabel,
              _t('comics_unit'),
              Icons.library_books_rounded,
              AppTheme.primaryGradient,
            ),
          ),
          Container(
            width: 1,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark
                      ? AppTheme.darkDivider
                      : AppTheme.dividerColor,
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Expanded(
            child: _buildStatItem(
              _t('current_page'),
              '$_currentPage',
              _t('pages_unit'),
              Icons.auto_stories_rounded,
              AppTheme.orangeGradient,
            ),
          ),
          Container(
            width: 1,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark
                      ? AppTheme.darkDivider
                      : AppTheme.dividerColor,
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Expanded(
            child: _buildStatItem(
              _t('total_pages'),
              '${_effectiveTotalPages ?? '--'}',
              _t('pages_unit'),
              Icons.bookmark_rounded,
              AppTheme.greenGradient,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    IconData icon,
    LinearGradient gradient,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Icon với gradient circle
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.30),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
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
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: AppTheme.orangeGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _t('recent_updates'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingHome)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (_homeComics.isEmpty && _homeError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_t('load_error')}: $_homeError', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _fetchHomeComics(page: _currentPage),
                  child: Text(_t('retry')),
                ),
              ],
            ),
          )
        else ...[
          if (_homeStatusMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.lightBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 18, color: AppTheme.getBrandPrimary(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _homeStatusMessage!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    final int? lastPage = _effectiveTotalPages;
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
        if (!isActive) _fetchHomeComics(page: pageNumber);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: isActive ? AppTheme.paginationActiveGradient : null,
          color: isActive ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? null
              : Border.all(
                  color: AppTheme.dividerColor.withOpacity(0.6),
                  width: 1,
                ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.getBrandPrimary(context).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : AppTheme.cardShadow,
        ),
        child: Text(
          '$pageNumber',
          style: TextStyle(
            color: isActive
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPageChip({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? AppTheme.getBrandPrimary(context).withOpacity(0.3)
                  : AppTheme.dividerColor.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: enabled
                  ? AppTheme.getBrandPrimary(context)
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
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
    final int maxPage = _effectiveTotalPages ?? 9999;
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
    final String? firstCategory =
        comic.categories.isNotEmpty ? comic.categories.first.name : null;
    final String typeLabel = comic.typeLabel;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color badgeColor = AppTheme.getBadgeColor(typeLabel);

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
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppTheme.darkDivider.withOpacity(0.4)
                : AppTheme.dividerColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : AppTheme.getBrandPrimary(context).withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Ảnh bìa
                    if (comic.thumbUrl != null)
                      Image.network(
                        comic.thumbUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                badgeColor.withOpacity(0.6),
                                badgeColor.withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.menu_book_rounded,
                              color: Colors.white, size: 28),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              badgeColor.withOpacity(0.6),
                              badgeColor.withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: Colors.white, size: 28),
                      ),
                    // Gradient overlay ở đáy
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xAA000000), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // Badge loại truyện — màu theo typeLabel
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: badgeColor.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comic.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      comic.latestChapterLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.getBrandPrimary(context).withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Category tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: badgeColor.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        firstCategory ?? 'Comic',
                        style: TextStyle(
                          fontSize: 8,
                          color: badgeColor,
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
    final isDark = theme.brightness == Brightness.dark;
    return CommonBottomNav(
      currentIndex: _selectedIndex,
      isDark: isDark,
      onTap: _handleBottomNavTap,
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    Widget? destination;
    switch (index) {
      case 1:
        destination = const ExploreScreen();
        break;
      case 2:
        destination = const BookListScreen();
        break;
      case 3:
        destination = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination!),
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
    _shakeController.dispose();
    _notificationService.dispose();
    _autoBannerTimer?.cancel();
    _autoBannerRestartDelay?.cancel();
    _homeFetchTimeout?.cancel();
    _bannerController.dispose();
    _comicsSubscription?.cancel();
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