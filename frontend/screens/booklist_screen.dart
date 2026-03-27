import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../data/services/auth_service.dart';
import '../data/services/comic_service.dart';
import '../data/services/follow_service.dart';
import '../data/models/comic.dart';
import '../data/models/genre.dart';
import '../widgets/common_bottom_nav.dart';
import 'book_details_screen.dart';
import 'enhanced_home_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 2; // Book list is index 2
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedSort = 'Recent';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  // API data state
  bool _isLoading = true;
  String? _error;
  List<Comic> _followedComics = []; // List of comics from Follow API
  Set<String> _completedComicIds = {};
  bool _hasLoadedOnce = false; // ✅ Track if loaded once

  final List<Book> _inProgressBooks = [
    Book(
      id: '1',
      title: 'Eighty-six vol 5',
      author: 'Asato Asato',
      coverUrl: 'https://via.placeholder.com/150x200/2563EB/FFFFFF?text=86',
      genre: 'Light Novel',
      progress: 0.75,
      rating: 4.5,
      pages: 320,
      description: 'In a world where the Eighty-Sixth Sector has been abandoned by the Republic, Shin and his fellow Eighty-Six fight against the Legion.',
      isCompleted: false,
      lastRead: DateTime.now().subtract(const Duration(days: 1)),
      type: 'Light Novel',
    ),
    Book(
      id: '2',
      title: 'The Midnight Library',
      author: 'Matt Haig',
      coverUrl: 'https://via.placeholder.com/150x200/7C3AED/FFFFFF?text=TML',
      genre: 'Fantasy',
      progress: 0.3,
      rating: 4.8,
      pages: 304,
      description: 'Between life and death there is a library, and within that library, the shelves go on forever.',
      isCompleted: false,
      lastRead: DateTime.now().subtract(const Duration(hours: 2)),
      type: 'Novel',
    ),
    Book(
      id: '3',
      title: 'Project Hail Mary',
      author: 'Andy Weir',
      coverUrl: 'https://via.placeholder.com/150x200/059669/FFFFFF?text=PHM',
      genre: 'Sci-Fi',
      progress: 0.6,
      rating: 4.9,
      pages: 496,
      description: 'A lone astronaut must save the earth from disaster in this incredible new science-based thriller.',
      isCompleted: false,
      lastRead: DateTime.now().subtract(const Duration(hours: 5)),
      type: 'Novel',
    ),
    Book(
      id: '4',
      title: 'Dune',
      author: 'Frank Herbert',
      coverUrl: 'https://via.placeholder.com/150x200/F59E0B/FFFFFF?text=DUNE',
      genre: 'Sci-Fi',
      progress: 0.2,
      rating: 4.5,
      pages: 688,
      description: 'Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides.',
      isCompleted: false,
      lastRead: DateTime.now().subtract(const Duration(days: 2)),
      type: 'Novel',
    ),
    Book(
      id: '5',
      title: 'The Silent Patient',
      author: 'Alex Michaelides',
      coverUrl: 'https://via.placeholder.com/150x200/DC2626/FFFFFF?text=TSP',
      genre: 'Mystery',
      progress: 0.1,
      rating: 4.6,
      pages: 336,
      description: 'A woman\'s refusal to give up her silence following a shocking act of violence.',
      isCompleted: false,
      lastRead: DateTime.now().subtract(const Duration(days: 3)),
      type: 'Novel',
    ),
  ];

  final List<Book> _completedBooks = [
    Book(
      id: '6',
      title: 'The Seven Husbands of Evelyn Hugo',
      author: 'Taylor Jenkins Reid',
      coverUrl: 'https://via.placeholder.com/150x200/10B981/FFFFFF?text=TSH',
      genre: 'Romance',
      progress: 1.0,
      rating: 4.7,
      pages: 400,
      description: 'Reclusive Hollywood movie icon Evelyn Hugo is finally ready to tell the truth about her glamorous and scandalous life.',
      isCompleted: true,
      lastRead: DateTime.now().subtract(const Duration(days: 3)),
      type: 'Novel',
    ),
    Book(
      id: '7',
      title: '1984',
      author: 'George Orwell',
      coverUrl: 'https://via.placeholder.com/150x200/8B5CF6/FFFFFF?text=1984',
      genre: 'Sci-Fi',
      progress: 1.0,
      rating: 4.7,
      pages: 328,
      description: 'A dystopian social science fiction novel.',
      isCompleted: true,
      lastRead: DateTime.now().subtract(const Duration(days: 7)),
      type: 'Novel',
    ),
    Book(
      id: '8',
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      coverUrl: 'https://via.placeholder.com/150x200/EF4444/FFFFFF?text=TGG',
      genre: 'Historical',
      progress: 1.0,
      rating: 4.3,
      pages: 180,
      description: 'A classic American novel set in the Jazz Age.',
      isCompleted: true,
      lastRead: DateTime.now().subtract(const Duration(days: 14)),
      type: 'Novel',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ✅ Listen to app lifecycle
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Load followed comics từ API
    _loadFollowedComics();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // ✅ Reload when app comes back to foreground
    if (state == AppLifecycleState.resumed && _hasLoadedOnce) {
      print('📱 App resumed - reloading followed comics');
      _loadFollowedComics();
    }
  }

  // Load danh sách truyện đang follow từ API
  Future<void> _loadFollowedComics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check đăng nhập
      final isLoggedIn = await AuthService().isLoggedIn();
      if (!isLoggedIn) {
        setState(() {
          _isLoading = false;
          _followedComics = [];
          _completedComicIds = {};
        });
        return;
      }

      // Lấy account ID
      final accountId = await FollowService().getAccountId();
      if (accountId == null) {
        setState(() {
          _isLoading = false;
          _error = null;
          _followedComics = [];
          _completedComicIds = {};
          _hasLoadedOnce = true;
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final completedIds =
          prefs.getStringList('completed_comics_$accountId') ?? [];

      // Gọi API để lấy danh sách followed comics
      final List<String> comicIds = await FollowService().getFollowedComics(accountId);
      
      print('✅ Loaded ${comicIds.length} followed comics');
      
      // Fetch details cho từng comic
      final List<Comic> comics = [];
      for (final comicId in comicIds) {
        final comic = await ComicService().fetchComicDetails(comicId);
        if (comic != null) {
          comics.add(comic);
        }
      }

      if (mounted) {
        setState(() {
          _followedComics = comics;
          _completedComicIds = completedIds.toSet();
          _isLoading = false;
          _hasLoadedOnce = true; // ✅ Mark as loaded
        });
      }
    } catch (e) {
      print('❌ Error loading followed comics: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleCompleted(Comic comic) async {
    final isLoggedIn = await AuthService().isLoggedIn();
    if (!isLoggedIn) {
      return;
    }

    final accountId = await FollowService().getAccountId();
    if (accountId == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = 'completed_comics_$accountId';
    final currentIds = prefs.getStringList(key) ?? [];
    final updatedIds = currentIds.toSet();

    if (_completedComicIds.contains(comic.comicId)) {
      updatedIds.remove(comic.comicId);
    } else {
      updatedIds.add(comic.comicId);
    }

    await prefs.setStringList(key, updatedIds.toList());

    if (mounted) {
      setState(() {
        _completedComicIds = updatedIds;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ✅ Remove observer
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildStatsSection(),
          _buildTabBar(),
          _buildTabBarView(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildSliverAppBar() {
    final languageProvider = LanguageProvider.of(context);
    final translate = languageProvider?.translate ?? LanguageManager.translate;
    if (languageProvider == null) {
      return const SliverAppBar(
        title: Text('My Library'),
        backgroundColor: AppTheme.primaryBlue,
      );
    }
    
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      foregroundColor: Colors.white,
      centerTitle: true, // Căn giữa title
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          translate('my_library'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true, // Căn giữa title trong FlexibleSpaceBar
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.secondaryBlue,
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.library_books,
              size: 40,
              color: Colors.white70,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
              }
            });
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          onSelected: (value) {
            setState(() {
              _selectedSort = value;
            });
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'Recent', child: Text(translate('sort_recent'))),
            PopupMenuItem(value: 'Title', child: Text(translate('sort_title'))),
            PopupMenuItem(value: 'Progress', child: Text(translate('sort_progress'))),
            PopupMenuItem(value: 'Rating', child: Text(translate('sort_rating'))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final theme = Theme.of(context);
    final translate = LanguageProvider.of(context)?.translate ?? LanguageManager.translate;
    // Sử dụng data từ API (followed comics)
    final totalBooks = _followedComics.length;
    final totalPages = 0; // API không có thông tin pages
    final avgRating = 4.0; // Default rating

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(translate('books'), totalBooks.toString(), Icons.book),
                _buildStatItem(translate('pages_read'), totalPages.toString(), Icons.pages),
                _buildStatItem(translate('avg_rating'), avgRating.toStringAsFixed(1), Icons.star),
              ],
            ),
            if (_isSearching) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: translate('search_library'),
                    hintStyle: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textLight),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final translate = LanguageProvider.of(context)?.translate ?? LanguageManager.translate;
    final completedCount = _followedComics
        .where((comic) => _completedComicIds.contains(comic.comicId))
        .length;
    return SliverToBoxAdapter(
      child: Container(
        color: Theme.of(context).cardColor,
        child: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_border, size: 18),
                  const SizedBox(width: 8),
                  Text('${translate('in_progress')} (${_followedComics.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 8),
                  Text('${translate('completed')} ($completedCount)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildInProgressTab(),
          _buildCompletedTab(),
        ],
      ),
    );
  }

  Widget _buildInProgressTab() {
    final translate = LanguageProvider.of(context)?.translate ?? LanguageManager.translate;
    // Hiển thị loading state
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Hiển thị error state
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('${translate('error_prefix')} $_error', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFollowedComics,
                child: Text(translate('retry')),
              ),
            ],
          ),
        ),
      );
    }

    // Hiển thị list từ API
    if (_followedComics.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: translate('no_followed_title'),
        subtitle: translate('no_followed_subtitle'),
        buttonText: translate('add_now'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExploreScreen()),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowedComics,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _followedComics.length,
        itemBuilder: (context, index) {
          final comic = _followedComics[index];
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildComicListItem(comic),
          );
        },
      ),
    );
  }

  Widget _buildCompletedTab() {
    final translate = LanguageProvider.of(context)?.translate ?? LanguageManager.translate;
    final completedComics = _getCompletedComics();

    if (completedComics.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: translate('no_completed_title'),
        subtitle: translate('no_completed_subtitle'),
        buttonText: translate('read_now'),
        onPressed: () {
          _tabController.animateTo(0);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedComics.length,
      itemBuilder: (context, index) {
        final comic = completedComics[index];
        return FadeTransition(
          opacity: _fadeAnimation,
          child: _buildComicListItem(comic),
        );
      },
    );
  }

  List<Comic> _getCompletedComics() {
    final filtered = _followedComics
        .where((comic) => _completedComicIds.contains(comic.comicId))
        .toList();

    if (_searchController.text.isEmpty) {
      return filtered;
    }

    final query = _searchController.text.toLowerCase();
    return filtered
        .where((comic) => comic.name.toLowerCase().contains(query))
        .toList();
  }

  // Build comic list item từ Comic object (từ API)
  Widget _buildComicListItem(Comic comic) {
    final theme = Theme.of(context);
    final translate = LanguageProvider.of(context)?.translate ?? LanguageManager.translate;
    final isCompleted = _completedComicIds.contains(comic.comicId);
    final thumbUrl = comic.thumbUrl.isNotEmpty 
        ? 'https://img.otruyenapi.com/uploads/comics/${comic.thumbUrl}'
        : null;

    return GestureDetector(
      onTap: () async {
        // ✅ Navigate và đợi kết quả quay lại
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsScreen(
              comicId: comic.comicId,
              slug: comic.slug,
            ),
          ),
        );
        
        // ✅ Reload followed comics khi quay lại
        print('🔄 Returned from BookDetailsScreen - reloading followed comics');
        _loadFollowedComics();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: thumbUrl != null
                  ? Image.network(
                      thumbUrl,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 120,
                          color: AppTheme.lightBlue,
                          child: const Icon(Icons.menu_book, size: 40),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 120,
                      color: AppTheme.lightBlue,
                      child: const Icon(Icons.menu_book, size: 40),
                    ),
            ),
            const SizedBox(width: 16),
            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comic.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${translate('type')}: Comic',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  // Status
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          translate('followed_status'),
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _toggleCompleted(comic),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.accentGreen.withOpacity(0.15)
                                : Theme.of(context).dividerColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isCompleted
                                ? translate('mark_incomplete')
                                : translate('mark_completed'),
                            style: TextStyle(
                              color: isCompleted
                                  ? AppTheme.accentGreen
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  List<Book> _getFilteredBooks(List<Book> books) {
    List<Book> filtered = books;
    
    // Filter by search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((book) =>
          book.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          book.genre.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }
    
    // Sort books
    switch (_selectedSort) {
      case 'Title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Progress':
        filtered.sort((a, b) => b.progress.compareTo(a.progress));
        break;
      case 'Rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default: // Recent
        filtered.sort((a, b) => b.lastRead.compareTo(a.lastRead));
    }
    
    return filtered;
  }

  Widget _buildBookListItem(Book book) {
    final translate = LanguageProvider.of(context)?.translate ?? LanguageManager.translate;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailsScreen(book: book),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.8),
                        AppTheme.secondaryBlue.withOpacity(0.6),
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
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                book.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (book.isCompleted)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.lightBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              book.genre,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${book.pages} ${translate('pages')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!book.isCompleted) ...[
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: book.progress,
                                backgroundColor: AppTheme.lightBlue.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(book.progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMedium,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${translate('last_read')}: ${_formatLastRead(book.lastRead)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.accentGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                translate('completed_status'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.accentGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${translate('finished')}: ${_formatLastRead(book.lastRead)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 60,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastRead(DateTime lastRead) {
    final now = DateTime.now();
    final difference = now.difference(lastRead);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildBottomNavigation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CommonBottomNav(
      currentIndex: _selectedIndex,
      isDark: isDark,
      onTap: (index) {
        if (index == _selectedIndex) return;
        setState(() => _selectedIndex = index);

        Widget? destination;
        switch (index) {
          case 0:
            destination = const EnhancedHomeScreen();
            break;
          case 1:
            destination = const ExploreScreen();
            break;
          case 2:
            return; // Đang ở Book list
          case 3:
            destination = const ProfileScreen();
            break;
        }

        if (destination != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => destination!),
          );
        }
      },
    );
  }
}