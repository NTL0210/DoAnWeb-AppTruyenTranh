import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../data/services/auth_service.dart';
import '../data/services/comic_service.dart';
import '../data/services/follow_service.dart';
import '../data/services/comic_cache_service.dart';  // ← THÊM DÒNG NÀY
import '../data/models/comic.dart';
import '../data/models/genre.dart';
import 'enhanced_home_screen.dart';
import 'chapter_reader_screen.dart';
import 'modern_onboarding.dart';

class BookDetailsScreen extends StatefulWidget {
  final String? slug; // prefer slug when available
  final String? comicId; // for direct comic ID lookup (from notifications)
  final Book? book;   // fallback for legacy callers

  const BookDetailsScreen({super.key, this.slug, this.comicId, this.book}) 
    : assert(slug != null || comicId != null || book != null);

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBookmarked = false;
  bool _isFollowing = false; // Trạng thái theo dõi truyện
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _item;
  Comic? _comic; // New API comic data
  String _cdnBase = 'https://cytostomal-nonsubtractive-bryanna.ngrok-free.dev';
  Set<String> _readChapters = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReadChapters();
    _syncFollowListIfLoggedIn(); // Sync follow list từ server nếu đã login
    if (widget.slug != null || widget.comicId != null) {
      _fetchDetails();
    } else {
      // Legacy: display from provided book without fetching
      setState(() {
        _loading = false;
      });
    }
  }

  // Sync follow list từ server
  Future<void> _syncFollowListIfLoggedIn() async {
    try {
      final isLoggedIn = await AuthService().isLoggedIn();
      if (isLoggedIn) {
        final accountId = await FollowService().getAccountId();
        if (accountId != null) {
          await FollowService().syncFollowListFromServer(accountId);
        }
      }
    } catch (e) {
      print('Error syncing follow list: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReadChapters() async {
    final key = widget.slug ?? widget.comicId;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final readChaptersJson = prefs.getString('read_chapters_$key');
    if (readChaptersJson != null) {
      final List<dynamic> readChaptersList = json.decode(readChaptersJson);
      setState(() {
        _readChapters = readChaptersList.cast<String>().toSet();
      });
    }
  }

  Future<void> _markChapterAsRead(String chapterApiUrl) async {
    final key = widget.slug ?? widget.comicId;
    if (key == null) return;
    setState(() {
      _readChapters.add(chapterApiUrl);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('read_chapters_$key', json.encode(_readChapters.toList()));
  }

  // Kiểm tra trạng thái follow từ local storage
  Future<void> _checkFollowStatus() async {
    if (_comic == null && widget.slug == null && widget.comicId == null) return;
    
    // Kiểm tra đăng nhập trước
    final isLoggedIn = await AuthService().isLoggedIn();
    if (!isLoggedIn) {
      // Nếu không đăng nhập (guest) thì luôn là không follow
      setState(() {
        _isFollowing = false;
      });
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      // Lấy account ID để lưu follow theo từng user
      final accountId = await FollowService().getAccountId();
      if (accountId == null) {
        setState(() {
          _isFollowing = false;
        });
        return;
      }
      
      // Load follow list theo user
      final followedComics = prefs.getStringList('followed_comics_$accountId') ?? [];
      
      // Lấy comic ID
      final comicId = _comic?.comicId ?? widget.slug;
      if (comicId != null) {
        setState(() {
          _isFollowing = followedComics.contains(comicId);
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
      setState(() {
        _isFollowing = false;
      });
    }
  }

  // Xử lý follow/unfollow
  Future<void> _handleFollowToggle() async {
    if (_comic == null && widget.slug == null) return;

    // Kiểm tra đăng nhập TRƯỚC
    final isLoggedIn = await AuthService().isLoggedIn();
    if (!isLoggedIn) {
      // Hiển thị dialog yêu cầu đăng nhập
      _showLoginRequiredDialog();
      return;
    }

    // Lấy account ID
    final accountId = await FollowService().getAccountId();
    if (accountId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy thông tin tài khoản'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Lấy comic ID
    final comicId = _comic?.comicId ?? widget.slug;
    if (comicId == null || comicId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy ID truyện'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      // Gọi API khác nhau cho follow và unfollow
      Map<String, dynamic> result;
      if (_isFollowing) {
        // Đang follow -> Unfollow (DELETE)
        result = await FollowService().unfollowComic(
          accountId: accountId,
          comicId: comicId,
        );
      } else {
        // Chưa follow -> Follow (POST)
        result = await FollowService().followComic(
          accountId: accountId,
          comicId: comicId,
        );
      }

      if (mounted) {
        if (result['success'] == true) {
          // Toggle state sau khi API thành công
          setState(() {
            _isFollowing = !_isFollowing;
          });

          // Lưu trạng thái follow vào local storage THEO USER
          final prefs = await SharedPreferences.getInstance();
          final key = 'followed_comics_$accountId'; // Key theo user
          final followedComics = prefs.getStringList(key) ?? [];
          
          if (_isFollowing) {
            // Thêm vào danh sách nếu chưa có
            if (!followedComics.contains(comicId)) {
              followedComics.add(comicId);
            }
          } else {
            // Xóa khỏi danh sách
            followedComics.remove(comicId);
          }
          
          await prefs.setStringList(key, followedComics);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? (_isFollowing ? 'Đã theo dõi truyện' : 'Đã bỏ theo dõi truyện')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Không toggle state nếu thất bại
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Có lỗi xảy ra'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling follow: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Hiển thị dialog yêu cầu đăng nhập
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  'Đăng nhập yêu cầu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineSmall?.color,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  'Bạn cần đăng nhập để có thể sử dụng tính năng này',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    // Nút Từ chối
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Từ chối',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Nút Đăng nhập
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to login screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ModernSignInScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // ✅ PRIORITIZE comicId if provided (from notifications)
      if (widget.comicId != null) {
        print('🔍 Fetching comic by ID: ${widget.comicId}');
        final detailedComic = await ComicService().fetchComicDetails(widget.comicId!);
        if (detailedComic != null) {
          print('✅ Fetched comic from ID: ${detailedComic.name}');
          
          // ⚠️ KIỂM TRA: Nếu không có chapters, thử fetch lại bằng các cách khác
          if (detailedComic.chapters == null || detailedComic.chapters!.isEmpty) {
            print('⚠️ Comic fetched by ID has no chapters. Trying alternative methods...');
            
            Comic? comicWithChapters;
            
            // Phương án 1: Thử search comic by name
            if (detailedComic.name.isNotEmpty) {
              print('🔍 Method 1: Searching by name: ${detailedComic.name}');
              final searchResults = await ComicService().searchComics(detailedComic.name);
              if (searchResults.isNotEmpty) {
                // Tìm comic khớp với comicId
                comicWithChapters = searchResults.firstWhere(
                  (c) => c.comicId == detailedComic.comicId,
                  orElse: () => Comic(comicId: '', name: '', slug: '', originName: '', status: '', thumbUrl: '', subDocquyen: false, chaptersLatest: '', updatedAt: '', createdAt: '', modifiedAt: '', chapters: null, comicGenres: null),
                );
                
                if (comicWithChapters.comicId.isEmpty) {
                  // Nếu không tìm thấy exact match, thử tìm bằng slug
                  comicWithChapters = searchResults.firstWhere(
                    (c) => c.slug == detailedComic.slug,
                    orElse: () => Comic(comicId: '', name: '', slug: '', originName: '', status: '', thumbUrl: '', subDocquyen: false, chaptersLatest: '', updatedAt: '', createdAt: '', modifiedAt: '', chapters: null, comicGenres: null),
                  );
                }
                
                if (comicWithChapters.comicId.isNotEmpty && 
                    comicWithChapters.chapters != null && 
                    comicWithChapters.chapters!.isNotEmpty) {
                  print('✅ Found comic with ${comicWithChapters.chapters!.length} chapters via search');
                  setState(() {
                    _comic = comicWithChapters!;
                    _loading = false;
                  });
                  _checkFollowStatus();
                  return;
                }
              }
            }
            
            // Phương án 2: Thử search by slug nếu có
            if (detailedComic.slug.isNotEmpty) {
              print('🔍 Method 2: Searching by slug: ${detailedComic.slug}');
              final searchResults = await ComicService().searchComics(detailedComic.slug);
              if (searchResults.isNotEmpty) {
                comicWithChapters = searchResults.firstWhere(
                  (c) => c.comicId == detailedComic.comicId || c.slug == detailedComic.slug,
                  orElse: () => searchResults.first,
                );
                
                if (comicWithChapters.chapters != null && comicWithChapters.chapters!.isNotEmpty) {
                  print('✅ Found comic with ${comicWithChapters.chapters!.length} chapters via slug search');
                  setState(() {
                    _comic = comicWithChapters!;
                    _loading = false;
                  });
                  _checkFollowStatus();
                  return;
                }
              }
            }
            
            // Nếu vẫn không có chapters, hiển thị comic nhưng warning
            print('⚠️ Could not load chapters for comic ${detailedComic.name}');
            print('⚠️ User will see detail page but cannot read chapters');
          }
          
          setState(() {
            _comic = detailedComic;
            _loading = false;
          });
          _checkFollowStatus();
          return;
        } else {
          print('❌ Failed to fetch comic by ID: ${widget.comicId}');
          setState(() {
            _loading = false;
            _error = 'Không tìm thấy truyện';
          });
          return;
        }
      }
      
      // Try to find comic ID from slug first
      String? comicId;
      if (widget.slug != null) {
        // Try to find comic from cache first (FAST)
        print('🔍 Looking for comic with slug in cache: ${widget.slug}');
        final cachedComic = ComicCacheService().findComicBySlug(widget.slug!);
        if (cachedComic != null) {
          print('💾 Found comic in cache: ${cachedComic.name}');
          
          // Kiểm tra xem cached comic có đầy đủ chapters không
          if (cachedComic.chapters != null && cachedComic.chapters!.isNotEmpty) {
            print('✅ Cached comic has ${cachedComic.chapters!.length} chapters');
            setState(() {
              _comic = cachedComic;
              _loading = false;
            });
            _checkFollowStatus();
            return;
          } else {
            print('⚠️ Cached comic missing chapters, fetching details...');
            // Nếu cached comic không có chapters → fetch details để lấy đầy đủ data
            final detailedComic = await ComicService().fetchComicDetails(cachedComic.comicId);
            if (detailedComic != null) {
              print('✅ Fetched detailed comic with ${detailedComic.chapters?.length ?? 0} chapters');
              setState(() {
                _comic = detailedComic;
                _loading = false;
              });
              _checkFollowStatus();
              return;
            }
          }
        }
        
        // If not in cache, try search API first (faster than fetchAllComics)
        print('🔍 Comic not in cache, searching for slug: ${widget.slug}');
        final List<Comic> searchResults = await ComicService().searchComics(widget.slug!);
        if (searchResults.isNotEmpty) {
          final matchingComic = searchResults.firstWhere(
            (comic) => comic.slug == widget.slug,
            orElse: () => searchResults.first, // Use first result if exact match not found
          );
          print('✅ Found comic from search: ${matchingComic.name}');
          
          // Kiểm tra xem search result có đầy đủ chapters không
          if (matchingComic.chapters != null && matchingComic.chapters!.isNotEmpty) {
            print('✅ Search result has ${matchingComic.chapters!.length} chapters');
            setState(() {
              _comic = matchingComic;
              _loading = false;
            });
            _checkFollowStatus();
            return;
          } else {
            print('⚠️ Search result missing chapters, fetching details...');
            // Nếu search result không có chapters → fetch details
            final detailedComic = await ComicService().fetchComicDetails(matchingComic.comicId);
            if (detailedComic != null) {
              print('✅ Fetched detailed comic with ${detailedComic.chapters?.length ?? 0} chapters');
              setState(() {
                _comic = detailedComic;
                _loading = false;
              });
              _checkFollowStatus();
              return;
            }
          }
        }
        
        // Last resort: fetchAllComics (SLOW - only if search fails)
        print('⚠️ Search failed, trying fetchAllComics (slow)...');
        final List<Comic> allComics = await ComicService().fetchAllComics();
        final matchingComic = allComics.firstWhereOrNull(
          (comic) => comic.slug == widget.slug,
        );
        
        if (matchingComic == null) {
          print('❌ Comic not found in all comics with slug: ${widget.slug}');
          setState(() {
            _loading = false;
            _error = 'Không tìm thấy truyện này. Có thể đã bị xóa hoặc slug không đúng.';
          });
          return;
        }
        
        comicId = matchingComic.comicId;
        print('Found comic ID: $comicId for slug: ${widget.slug}');
      }
      
      if (comicId != null) {
        // Fetch details using new API
        print('Fetching comic details for ID: $comicId');
        final comic = await ComicService().fetchComicDetails(comicId);
        if (comic != null) {
          print('Successfully loaded comic details: ${comic.name}');
          setState(() {
            _comic = comic;
            _loading = false;
          });
          // Check follow status sau khi load xong comic
          _checkFollowStatus();
          return;
        } else {
          print('Failed to fetch comic details for ID: $comicId');
        }
      }
      
      // Fallback: try to get comic from search results
      if (widget.slug != null) {
        print('Trying fallback: search for comic with slug');
        final List<Comic> searchResults = await ComicService().searchComics(widget.slug!);
        if (searchResults.isNotEmpty) {
          final matchingComic = searchResults.firstWhere(
            (comic) => comic.slug == widget.slug,
            orElse: () => searchResults.first, // Use first result if exact match not found
          );
          print('Found comic from search: ${matchingComic.name}');
          setState(() {
            _comic = matchingComic;
            _loading = false;
          });
          // Check follow status sau khi load xong comic
          _checkFollowStatus();
          return;
        }
      }
      
      // If all methods fail, show error
      setState(() {
        _error = 'Không thể tải thông tin truyện từ API mới';
        _loading = false;
      });
    } catch (e) {
      print('Error fetching comic details: $e');
      setState(() {
        _error = 'Lỗi: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Lỗi: $_error', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        const SizedBox(height: 8),
                        OutlinedButton(onPressed: _fetchDetails, child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildBookInfo(),
                _buildTabBar(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _loading || _error != null ? null : _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    // Use new API data if available, fallback to old API data
    final String itemName = _comic?.name ?? (_item?['name'] ?? '').toString();
    final String thumb = _comic?.thumbUrl ?? (_item?['thumb_url'] ?? '').toString();
    final String? cover = thumb.isNotEmpty ? 'https://img.otruyenapi.com/uploads/comics/$thumb' : null;
    final String legacyTitle = widget.book?.title ?? '';
    
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Nút Follow/Unfollow
        IconButton(
          icon: Icon(
            _isFollowing ? Icons.favorite : Icons.favorite_border,
            color: _isFollowing ? Colors.red : Colors.white,
          ),
          onPressed: _handleFollowToggle,
          tooltip: _isFollowing ? 'Bỏ yêu thích' : 'Yêu thích',
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isBookmarked = !_isBookmarked;
            });
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: null,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image fills the entire header area
            if (cover != null)
              Image.network(
                cover,
                fit: BoxFit.cover,
              )
            else if (widget.book != null)
              Image.network(
                widget.book!.coverUrl,
                fit: BoxFit.cover,
              )
            else
              Container(color: AppTheme.primaryBlue),
            // Subtle gradient overlay for readability (optional)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.25),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookInfo() {
    // Use new API data if available, fallback to old API data
    // Get name with proper fallback logic
    String name;
    if (_comic?.name != null && _comic!.name.isNotEmpty) {
      name = _comic!.name;
    } else if (_item?['name'] != null && (_item!['name'] as String).isNotEmpty) {
      name = _item!['name'] as String;
    } else {
      name = widget.book?.title ?? '';
    }
    final List<dynamic> author = _comic != null ? [] : ((_item?['author'] as List<dynamic>?) ?? (widget.book != null ? [widget.book!.author] : const []));
    final List<dynamic> category = _comic != null 
        ? (_comic!.comicGenres?.map((cg) => {'name': cg.genre?.name ?? 'Unknown'}).toList() ?? [])
        : ((_item?['category'] as List<dynamic>?) ?? (widget.book != null ? [{'name': widget.book!.genre}] : const []));
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.headlineSmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tác giả: ${author.isNotEmpty ? author.join(', ') : '—'}',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 16),
          // Nút Yêu thích lớn, dễ nhận biết
          ElevatedButton.icon(
            onPressed: _handleFollowToggle,
            icon: Icon(
              _isFollowing ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              _isFollowing ? 'Bỏ yêu thích' : 'Yêu thích',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isFollowing ? Colors.red : AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category.isNotEmpty ? ((category.first as Map<String, dynamic>)['name'] ?? '').toString() : 'Comic',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.slug != null ? 'Chương: ${_chapterCount()}' : 'Pages: ${widget.book?.pages ?? '-'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.book != null && widget.slug == null)
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(widget.book!.rating.toString(), style: const TextStyle(color: AppTheme.textLight)),
              ],
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.primaryBlue,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Chapters'),
          Tab(text: 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: SizedBox(
        height: 300,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildChaptersTab(),
            _buildReviewsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final item = _item ?? const {};
    final String contentHtml = widget.slug != null ? (item['content'] ?? '').toString() : (widget.book?.description ?? '');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescriptionCard(contentHtml),
          const SizedBox(height: 16),
          _buildStoryInfoCards(),
        ],
      ),
    );
  }

  Widget _buildChaptersTab() {
    if (widget.slug == null) {
      return ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => _buildLegacyChapterItem(index + 1),
      );
    }
    final list = _chapterList();
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return _buildChapterRow(list[index]);
      },
    );
  }

  Widget _buildDescriptionCard(String contentHtml) {
    final String description = _stripHtml(contentHtml).isNotEmpty ? _stripHtml(contentHtml) : 'Chưa có mô tả cho truyện này.';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Mô tả',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryInfoCards() {
    final item = _item ?? const {};
    final List<dynamic> author = _comic != null ? [] : ((item['author'] as List<dynamic>?) ?? (widget.book != null ? [widget.book!.author] : const []));
    final List<dynamic> category = _comic != null 
        ? (_comic!.comicGenres?.map((cg) => {'name': cg.genre?.name ?? 'Unknown'}).toList() ?? [])
        : ((item['category'] as List<dynamic>?) ?? (widget.book != null ? [{'name': widget.book!.genre}] : const []));
    final int chapterCount = _chapterCount();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline,
                color: Colors.green.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Thông tin truyện',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.headlineSmall?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.person,
          iconColor: Colors.orange,
          title: 'Tác giả',
          value: author.isNotEmpty ? author.join(', ') : 'Chưa cập nhật',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.category,
          iconColor: Colors.purple,
          title: 'Thể loại',
          value: category.isNotEmpty ? ((category.first as Map<String, dynamic>)['name'] ?? '').toString() : 'Comic',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.menu_book,
          iconColor: Colors.blue,
          title: 'Số chương',
          value: '$chapterCount chương',
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.update,
          iconColor: Colors.red,
          title: 'Trạng thái',
          value: 'Đang cập nhật',
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryInfo() {
    final item = _item ?? const {};
    final List<dynamic> author = _comic != null ? [] : ((item['author'] as List<dynamic>?) ?? (widget.book != null ? [widget.book!.author] : const []));
    final List<dynamic> category = _comic != null 
        ? (_comic!.comicGenres?.map((cg) => {'name': cg.genre?.name ?? 'Unknown'}).toList() ?? [])
        : ((item['category'] as List<dynamic>?) ?? (widget.book != null ? [{'name': widget.book!.genre}] : const []));
    final int chapterCount = _chapterCount();
    
    return Column(
      children: [
        _buildInfoRow('Tác giả', author.isNotEmpty ? author.join(', ') : 'Chưa cập nhật'),
        _buildInfoRow('Thể loại', category.isNotEmpty ? ((category.first as Map<String, dynamic>)['name'] ?? '').toString() : 'Comic'),
        _buildInfoRow('Số chương', '$chapterCount chương'),
        _buildInfoRow('Trạng thái', 'Đang cập nhật'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Rating: ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            ...List.generate(5, (index) {
              return Icon(
                Icons.star,
                color: index < 4 ? Colors.amber : Colors.grey[300],
                size: 20,
              );
            }),
            const SizedBox(width: 8),
            Text(
              '4.2 (128 reviews)',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Top Reviews',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineSmall?.color,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) {
              return _buildReviewItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChapterRow(Map<String, dynamic> m) {
    final chapterName = (m['chapterName'] ?? m['chapter_name'] ?? '').toString();
    final filename = (m['filename'] ?? '').toString();
    final String apiUrl = (m['chapterApiData'] ?? m['chapter_api_data'] ?? '').toString();
    final bool isRead = _readChapters.contains(apiUrl);
    
    return ListTile(
      dense: true,
      title: Text(
        'Chap $chapterName',
        style: TextStyle(
          color: isRead ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        filename, 
        maxLines: 1, 
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isRead ? Colors.grey[600] : Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: isRead 
        ? const Icon(Icons.check_circle, color: Colors.grey, size: 20)
        : const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: () {
        if (apiUrl.isEmpty) return;
        _markChapterAsRead(apiUrl);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterReaderScreen(
              chapterApiUrl: apiUrl,
              title: 'Chap $chapterName',
              chapters: _chapterList(),
              initialIndex: _chapterList().indexWhere((x) => (x['chapter_api_data'] ?? '').toString() == apiUrl),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryBlue,
                child: Text(
                  'U${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'User${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              ...List.generate(5, (starIndex) {
                return Icon(
                  Icons.star,
                  color: starIndex < 4 ? Colors.amber : Colors.grey[300],
                  size: 16,
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Great story with amazing character development. '
            'The plot twists keep you engaged throughout.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final chapters = _chapterList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (widget.slug != null) {
                final chapters = _chapterList();
                if (chapters.isNotEmpty) {
                  final first = chapters.first;
                  final apiUrl = (first['chapterApiData'] ?? first['chapter_api_data'] ?? '').toString();
                  final name = (first['chapterName'] ?? first['chapter_name'] ?? '').toString();
                  if (apiUrl.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChapterReaderScreen(
                          chapterApiUrl: apiUrl,
                          title: 'Chap $name',
                          chapters: _chapterList(),
                          initialIndex: 0,
                        ),
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              widget.slug != null
                  ? (chapters.isNotEmpty ? 'Đọc từ chap ${chapters.first['chapterName'] ?? chapters.first['chapter_name']}' : 'Chưa có chương')
                  : LanguageManager.translate('start_reading'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
  List<Map<String, dynamic>> _chapterList() {
    if (_comic != null) {
      // ƯU TIÊN: Sử dụng field 'chapters' (đầy đủ tất cả chapters) nếu có
      if (_comic!.chapters != null && _comic!.chapters!.isNotEmpty) {
        final chapterList = _comic!.chapters!.map((chapter) => {
          'id': chapter.id,
          'comicId': chapter.comicId,
          'slug': chapter.slug,
          'serverName': chapter.serverName,
          'serverIndex': chapter.serverIndex,
          'chapterIndex': chapter.chapterIndex,
          'filename': chapter.filename,
          'chapterName': chapter.chapterName,
          'chapterTitle': chapter.chapterTitle,
          'chapterApiData': chapter.chapterApiData,
          'createdAt': chapter.createdAt,
          'updatedAt': chapter.updatedAt,
          // Keep old field names for compatibility
          'chapter_name': chapter.chapterName,
          'chapter_api_data': chapter.chapterApiData,
        }).toList();
        
        print('✅ Loaded ${chapterList.length} chapters from API');
        return chapterList;
      }
    }
    
    // Fallback to old API data
    final List<dynamic> chapters = ((_item ?? const {})['chapters'] as List<dynamic>?) ?? const [];
    final List<dynamic> serverData = chapters.isNotEmpty
        ? ((chapters.first as Map<String, dynamic>)['server_data'] as List<dynamic>? ?? const [])
        : const [];
    return serverData.cast<Map<String, dynamic>>();
  }

  int _chapterCount() => _chapterList().length;

  String _stripHtml(String html) => html.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  Widget _buildLegacyChapterItem(int chapterNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$chapterNumber',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chapter',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '15 min read',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
