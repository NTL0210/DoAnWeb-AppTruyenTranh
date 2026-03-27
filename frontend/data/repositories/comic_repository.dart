import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/comic_service.dart';
import '../services/comic_cache_service.dart';
import '../services/follow_service.dart';
import '../models/comic.dart';
import '../models/genre.dart';
import '../states/comic_data_state.dart';
import '../../core/network/retry_config.dart';

/// Comic repository
/// Aggregates comic-related services and manages comic data with caching
class ComicRepository {
  final ComicService _comicService = ComicService();
  final ComicCacheService _cacheService = ComicCacheService();
  final FollowService _followService = FollowService();

  // ==================== COMICS ====================

  /// Get comics by page with caching
  Future<List<Comic>> getComics({
    int page = 1,
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh) {
      final cached = _cacheService.getCachedComics(page);
      if (cached != null) {
        print('💾 Using cached comics for page $page');
        return cached;
      }
    }

    // Fetch from API
    final comics = await _comicService.fetchComics(
      page: page,
      forceRefresh: forceRefresh,
    );

    // Cache the results
    _cacheService.setCachedComics(page, comics);

    return comics;
  }

  /// Get all comics from pages 1-20
  Future<List<Comic>> getAllComics() async {
    return await _comicService.fetchAllComics();
  }

  /// Get comic details by ID
  Future<Comic?> getComicDetails(
    String comicId, {
    bool forceRefresh = false,
  }) async {
    // Try to find in cache first
    if (!forceRefresh) {
      final cached = _cacheService.findComicBySlug(comicId);
      if (cached != null) {
        print('💾 Using cached comic details');
        return cached;
      }
    }

    // Fetch from API
    return await _comicService.fetchComicDetails(
      comicId,
      forceRefresh: forceRefresh,
    );
  }

  // ==================== SEARCH ====================

  /// Search comics by keyword with caching
  Future<List<Comic>> searchComics(String query) async {
    if (query.isEmpty) {
      return await getComics(page: 1);
    }

    // Check cache first
    final cached = _cacheService.getCachedSearch(query);
    if (cached != null) {
      print('💾 Using cached search results for "$query"');
      return cached;
    }

    // Search from API
    final results = await _comicService.searchComics(query);

    // Cache the results
    _cacheService.setCachedSearch(query, results);

    return results;
  }

  // ==================== GENRES ====================

  /// Get all genres
  Future<List<Genre>> getGenres() async {
    return await _comicService.fetchGenres();
  }

  /// Get comics by genre with caching
  Future<List<Comic>> getComicsByGenre(String genreId) async {
    // Check cache first
    final cached = _cacheService.getCachedGenre(genreId);
    if (cached != null) {
      print('💾 Using cached genre comics');
      return cached;
    }

    // Fetch from API
    final comics = await _comicService.fetchComicsByGenre(genreId);

    // Cache the results
    _cacheService.setCachedGenre(genreId, comics);

    return comics;
  }

  // ==================== FOLLOW ====================

  /// Follow a comic
  Future<Map<String, dynamic>> followComic({
    required String accountId,
    required String comicId,
  }) async {
    final result = await _followService.followComic(
      accountId: accountId,
      comicId: comicId,
    );

    if (result['success'] == true) {
      // Update local follow list
      await _addToFollowList(accountId, comicId);
    }

    return result;
  }

  /// Unfollow a comic
  Future<Map<String, dynamic>> unfollowComic({
    required String accountId,
    required String comicId,
  }) async {
    final result = await _followService.unfollowComic(
      accountId: accountId,
      comicId: comicId,
    );

    if (result['success'] == true) {
      // Update local follow list
      await _removeFromFollowList(accountId, comicId);
    }

    return result;
  }

  /// Get followed comics list
  Future<List<String>> getFollowedComics(String accountId) async {
    return await _followService.getFollowedComics(accountId);
  }

  /// Sync follow list from server
  Future<void> syncFollowListFromServer(String? accountId) async {
    await _followService.syncFollowListFromServer(accountId);
  }

  /// Check if a comic is followed
  Future<bool> isComicFollowed(String accountId, String comicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final followedComics =
          prefs.getStringList('followed_comics_$accountId') ?? [];
      return followedComics.contains(comicId);
    } catch (e) {
      print('❌ Error checking follow status: $e');
      return false;
    }
  }

  // ==================== READING PROGRESS ====================

  /// Save reading progress for a comic
  Future<void> saveReadingProgress({
    required String comicSlug,
    required String chapterApiUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readChaptersJson = prefs.getString('read_chapters_$comicSlug');

      Set<String> readChapters = {};
      if (readChaptersJson != null) {
        final List<dynamic> list = json.decode(readChaptersJson);
        readChapters = list.cast<String>().toSet();
      }

      readChapters.add(chapterApiUrl);
      await prefs.setString(
        'read_chapters_$comicSlug',
        json.encode(readChapters.toList()),
      );

      print('✅ Saved reading progress for $comicSlug');
    } catch (e) {
      print('❌ Error saving reading progress: $e');
    }
  }

  /// Get read chapters for a comic
  Future<Set<String>> getReadChapters(String comicSlug) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readChaptersJson = prefs.getString('read_chapters_$comicSlug');

      if (readChaptersJson != null) {
        final List<dynamic> list = json.decode(readChaptersJson);
        return list.cast<String>().toSet();
      }
      return {};
    } catch (e) {
      print('❌ Error getting read chapters: $e');
      return {};
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear all cache
  void clearCache() {
    _cacheService.clearCache();
  }

  /// Force refresh cache
  void forceRefreshCache() {
    _cacheService.forceRefresh();
  }

  /// Check if cache has data
  bool hasCachedData() {
    return _cacheService.hasCachedData();
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'cachedPages': _cacheService.getCachedPagesCount(),
      'totalComics': _cacheService.getTotalCachedComics(),
    };
  }

  // ==================== RESILIENT STREAMS ====================
  //
  // Dùng các method này thay vì getComics() khi muốn:
  // - Hiển thị ngay (mock data nếu API lỗi)
  // - Tự động cập nhật UI khi API phục hồi
  // - Không block UI trong quá trình chờ

  /// Stream danh sách truyện theo trang với resilience
  ///
  /// Widget dùng StreamBuilder<ComicDataState> để lắng nghe:
  /// ```dart
  /// StreamBuilder<ComicDataState>(
  ///   stream: ComicRepository().watchComics(page: 1),
  ///   builder: (ctx, snap) {
  ///     final state = snap.data;
  ///     if (state is ComicLoaded) { ... }
  ///   },
  /// )
  /// ```
  Stream<ComicDataState> watchComics({
    int page = 1,
    RetryConfig config = RetryConfig.defaultConfig,
  }) {
    return _comicService.watchComics(page: page, config: config);
  }

  /// Stream thể loại với resilience
  Stream<GenreDataState> watchGenres({
    RetryConfig config = RetryConfig.defaultConfig,
  }) {
    return _comicService.watchGenres(config: config);
  }

  /// Stream tìm kiếm với resilience
  Stream<ComicDataState> watchSearch({
    required String query,
    RetryConfig config = RetryConfig.defaultConfig,
  }) {
    return _comicService.watchSearch(query: query, config: config);
  }

  /// Stream truyện theo thể loại với resilience
  Stream<ComicDataState> watchComicsByGenre({
    required String genreId,
    RetryConfig config = RetryConfig.defaultConfig,
  }) {
    return _comicService.watchComicsByGenre(genreId: genreId, config: config);
  }

  /// Hủy tất cả stream resilient (gọi trong dispose)
  void cancelAllResilientStreams() {
    _comicService.cancelAllResilientStreams();
  }

  // ==================== UTILITIES ====================

  /// Test API connectivity
  Future<bool> testApi() async {
    return await _comicService.testApi();
  }

  /// Get account ID for current user
  Future<String?> getAccountId() async {
    return await _followService.getAccountId();
  }

  // ==================== PRIVATE HELPERS ====================

  /// Add comic to local follow list
  Future<void> _addToFollowList(String accountId, String comicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'followed_comics_$accountId';
      final followedComics = prefs.getStringList(key) ?? [];

      if (!followedComics.contains(comicId)) {
        followedComics.add(comicId);
        await prefs.setStringList(key, followedComics);
        print('✅ Added to local follow list');
      }
    } catch (e) {
      print('❌ Error adding to follow list: $e');
    }
  }

  /// Remove comic from local follow list
  Future<void> _removeFromFollowList(String accountId, String comicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'followed_comics_$accountId';
      final followedComics = prefs.getStringList(key) ?? [];

      followedComics.remove(comicId);
      await prefs.setStringList(key, followedComics);
      print('✅ Removed from local follow list');
    } catch (e) {
      print('❌ Error removing from follow list: $e');
    }
  }
}

