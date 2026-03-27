import '../models/comic.dart';

/// Comic cache service
/// Manages in-memory caching for comics with expiry
class ComicCacheService {
  // Singleton pattern
  static final ComicCacheService _instance = ComicCacheService._internal();
  factory ComicCacheService() => _instance;
  ComicCacheService._internal();

  final Map<int, List<Comic>> _comicsCache = {};
  final Map<String, List<Comic>> _searchCache = {};
  final Map<String, List<Comic>> _genreCache = {};
  DateTime? _lastCacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  // ==================== CACHE CHECKS ====================

  /// Check if cache is expired
  bool get _isCacheExpired {
    if (_lastCacheTime == null) return true;
    return DateTime.now().difference(_lastCacheTime!) > _cacheExpiry;
  }

  /// Check if cache has any data
  bool hasCachedData() {
    return _comicsCache.isNotEmpty ||
        _searchCache.isNotEmpty ||
        _genreCache.isNotEmpty;
  }

  // ==================== COMICS CACHE ====================

  /// Get cached comics by page
  List<Comic>? getCachedComics(int page) {
    if (_isCacheExpired) {
      print('🔄 Cache expired, clearing cache');
      _comicsCache.clear();
      _searchCache.clear();
      _genreCache.clear();
      return null;
    }
    return _comicsCache[page];
  }

  /// Cache comics for a page
  void setCachedComics(int page, List<Comic> comics) {
    _comicsCache[page] = comics;
    _lastCacheTime = DateTime.now();
    print('💾 Cached ${comics.length} comics for page $page');
  }

  // ==================== SEARCH CACHE ====================

  /// Get cached search results
  List<Comic>? getCachedSearch(String query) {
    if (_isCacheExpired) return null;
    return _searchCache[query];
  }

  /// Cache search results
  void setCachedSearch(String query, List<Comic> comics) {
    _searchCache[query] = comics;
    print('💾 Cached ${comics.length} search results for "$query"');
  }

  // ==================== GENRE CACHE ====================

  /// Get cached genre comics
  List<Comic>? getCachedGenre(String genreId) {
    if (_isCacheExpired) return null;
    return _genreCache[genreId];
  }

  /// Cache genre comics
  void setCachedGenre(String genreId, List<Comic> comics) {
    _genreCache[genreId] = comics;
    print('💾 Cached ${comics.length} comics for genre $genreId');
  }

  // ==================== FIND ====================

  /// Find comic by slug in cache
  Comic? findComicBySlug(String slug) {
    if (_isCacheExpired) return null;

    // Search in comics cache
    for (final pageComics in _comicsCache.values) {
      try {
        final comic = pageComics.firstWhere((comic) => comic.slug == slug);
        print('💾 Found comic by slug in cache: ${comic.name}');
        return comic;
      } catch (e) {
        // Not found in this page, continue
      }
    }

    // Search in search cache
    for (final searchResults in _searchCache.values) {
      try {
        final comic = searchResults.firstWhere((comic) => comic.slug == slug);
        print('💾 Found comic by slug in search cache: ${comic.name}');
        return comic;
      } catch (e) {
        // Not found in this search, continue
      }
    }

    return null;
  }

  // ==================== UTILITIES ====================

  /// Clear all cache
  void clearCache() {
    _comicsCache.clear();
    _searchCache.clear();
    _genreCache.clear();
    _lastCacheTime = null;
    print('🗑️ Cleared all cache');
  }

  /// Force refresh cache
  void forceRefresh() {
    clearCache();
    print('🔄 Force refresh cache');
  }

  /// Get number of cached pages
  int getCachedPagesCount() {
    return _comicsCache.length;
  }

  /// Get total number of cached comics
  int getTotalCachedComics() {
    return _comicsCache.values.fold(0, (sum, comics) => sum + comics.length);
  }
}

