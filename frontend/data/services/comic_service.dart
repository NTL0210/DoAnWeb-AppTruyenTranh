import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/comic.dart';
import '../models/genre.dart';
import '../models/comic_chapter.dart';
import 'comic_cache_service.dart';
import '../../utils/http_client_helper.dart';
import '../../core/network/resilient_api_client.dart';
import '../../core/network/retry_config.dart';
import '../mock/comic_mock_data.dart';
import '../states/comic_data_state.dart';

/// Comic service
/// Handles comic fetching, searching, and genre operations
class ComicsPagination {
  final int? totalPages;
  final int? totalItems;
  final int? pageSize;
  final int? pageIndex;

  const ComicsPagination({
    this.totalPages,
    this.totalItems,
    this.pageSize,
    this.pageIndex,
  });

  bool get hasAnyValue =>
      totalPages != null || totalItems != null || pageSize != null || pageIndex != null;
}

class ComicService {
    static const String _baseUrl =
      'https://cytostomal-nonsubtractive-bryanna.ngrok-free.dev/api';

  static ComicsPagination? lastPagination;
  static int? lastEstimatedTotalPages;

  // Public getter for building absolute URLs
  static String get baseUrl => _baseUrl;

  // Cache service instance
  final ComicCacheService _cacheService = ComicCacheService();

  // Create HTTP client with SSL configuration
  http.Client _createClient() {
    return IOClient(HttpClientHelper.createHttpClient());
  }

  // ==================== FETCH COMICS ====================

  /// Fetch comics by page with caching support
  Future<List<Comic>> fetchComics({
    int page = 1,
    bool forceRefresh = false,
  }) async {
    // Check cache first if not forcing refresh
    if (!forceRefresh) {
      final cached = _cacheService.getCachedComics(page);
      if (cached != null) {
        print('💾 Using cached comics for page $page');
        return cached;
      }
    }

    try {
      print('=== ComicService: Fetching comics from API, page: $page ===');
      final uri = Uri.parse('$_baseUrl/Comics/page?page=$page');
      print('🌐 Request URL: $uri');

      final client = _createClient();
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'text/plain',
          'User-Agent': 'demo-app/1.0 (flutter)',
        },
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Response status: ${response.statusCode}');
      print('📏 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          print('📦 JSON parsed successfully');
          final parsed = ComicsResponse.fromJson(jsonData);

          final pagination = _extractPagination(jsonData, response.headers);
          if (pagination != null) {
            lastPagination = pagination;
            if (pagination.totalPages != null && pagination.totalPages! > 0) {
              lastEstimatedTotalPages = pagination.totalPages;
            } else if (pagination.totalItems != null &&
                pagination.pageSize != null &&
                pagination.pageSize! > 0) {
              lastEstimatedTotalPages =
                  ((pagination.totalItems! + pagination.pageSize! - 1) ~/
                      pagination.pageSize!);
            }
          }

          print('✅ Successfully parsed ${parsed.values.length} comics');
          for (int i = 0; i < parsed.values.length && i < 3; i++) {
            print('📚 Comic ${i + 1}: ${parsed.values[i].name}');
          }

          // Cache the results
          _cacheService.setCachedComics(page, parsed.values);

          return parsed.values;
        } catch (parseError) {
          print('❌ JSON parse error: $parseError');
          print('📄 Response body preview: ${response.body.substring(
              0, response.body.length > 500 ? 500 : response.body.length)}');
          return [];
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        return [];
      }
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      return [];
    } on SocketException catch (e) {
      print('❌ Socket error: $e');
      return [];
    } catch (e) {
      print('❌ Network error: $e');
      return [];
    }
  }

  /// Fetch all comics across all available pages
  Future<List<Comic>> fetchAllComics() async {
    try {
      print('Starting to fetch all comics from all pages...');
      final List<Comic> allComics = [];
      final Set<String> seenIds = {};

      final int totalPages =
          await _resolveTotalPagesForFetchAll() ?? 20;

      for (int page = 1; page <= totalPages; page++) {
        print('Fetching page $page...');
        final List<Comic> pageComics = await fetchComics(page: page)
            .timeout(const Duration(seconds: 3), onTimeout: () => <Comic>[]);

        for (final comic in pageComics) {
          if (!seenIds.contains(comic.comicId)) {
            allComics.add(comic);
            seenIds.add(comic.comicId);
          }
        }

        if (page < totalPages) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      print('Total unique comics fetched: ${allComics.length}');
      return allComics;
    } catch (e) {
      print('Error fetching all comics: $e');
      return [];
    }
  }

  Future<int?> estimateTotalPages({int maxPage = 500}) async {
    if (lastEstimatedTotalPages != null) return lastEstimatedTotalPages;
    if (maxPage < 1) return null;

    try {
      final firstPage = await fetchComics(page: 1);
      if (firstPage.isEmpty) {
        lastEstimatedTotalPages = 0;
        return 0;
      }

      int low = 1;
      int high = 2;
      List<Comic> highComics = await fetchComics(page: high);

      while (highComics.isNotEmpty && high < maxPage) {
        low = high;
        high = (high * 2).clamp(2, maxPage);
        if (high == low) break;
        highComics = await fetchComics(page: high);
      }

      if (highComics.isNotEmpty && high == maxPage) {
        lastEstimatedTotalPages = high;
        return high;
      }

      int left = low + 1;
      int right = high;
      int lastNonEmpty = low;

      while (left <= right) {
        final int mid = (left + right) ~/ 2;
        final List<Comic> comics = await fetchComics(page: mid);
        if (comics.isNotEmpty) {
          lastNonEmpty = mid;
          left = mid + 1;
        } else {
          right = mid - 1;
        }
      }

      lastEstimatedTotalPages = lastNonEmpty;
      return lastNonEmpty;
    } catch (e) {
      print('❌ Error estimating total pages: $e');
      return null;
    }
  }

  // ==================== SEARCH COMICS ====================

  /// Search comics by keyword
  Future<List<Comic>> searchComics(String query) async {
    try {
      print('=== ComicService: Searching comics with query: $query ===');
      if (query.isEmpty) {
        return await fetchComics(page: 1);
      }

      final uri = Uri.parse('$_baseUrl/Comics/search?keyword=$query');
      print('🌐 Search URL: $uri');

      final client = _createClient();
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'text/plain',
          'User-Agent': 'demo-app/1.0 (flutter)',
        },
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Search response status: ${response.statusCode}');
      print('📏 Search response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          print('📦 Search JSON parsed successfully');

          final ComicsResponse comicsResponse =
              ComicsResponse.fromJson(jsonData);
          print(
              '✅ Successfully parsed ${comicsResponse.values.length} search results');

          return comicsResponse.values;
        } catch (parseError) {
          print('❌ Search JSON parse error: $parseError');
          print('📄 Search response body preview: ${response.body.substring(
              0, response.body.length > 500 ? 500 : response.body.length)}');
          return [];
        }
      } else {
        print('❌ Search HTTP error: ${response.statusCode}');
        print('📄 Search response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Search network error: $e');
      return [];
    }
  }

  // ==================== COMIC DETAILS ====================

  /// Fetch comic details by ID
  Future<Comic?> fetchComicDetails(
    String comicId, {
    bool forceRefresh = false,
  }) async {
    try {
      print('=== ComicService: Fetching comic details for ID: $comicId ===');
      final uri = Uri.parse('$_baseUrl/Comics/$comicId');
      print('🌐 Request URL: $uri');

      final client = _createClient();
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'text/plain',
          'User-Agent': 'demo-app/1.0 (flutter)',
        },
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Response status: ${response.statusCode}');
      print('📏 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          print('📦 JSON parsed successfully');
          final comic = Comic.fromJson(jsonData);
          print('✅ Successfully parsed comic: ${comic.name}');

          return comic;
        } catch (parseError) {
          print('❌ JSON parse error: $parseError');
          print('📄 Response body preview: ${response.body.substring(
              0, response.body.length > 500 ? 500 : response.body.length)}');
          return null;
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Network error: $e');
      return null;
    }
  }

  // ==================== GENRES ====================

  /// Fetch all genres
  Future<List<Genre>> fetchGenres() async {
    try {
      print('=== ComicService: Fetching genres from API ===');
      final uri = Uri.parse('$_baseUrl/Genres');
      print('🌐 Request URL: $uri');

      final client = _createClient();
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'text/plain',
          'User-Agent': 'demo-app/1.0 (flutter)',
        },
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Response status: ${response.statusCode}');
      print('📏 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          print('📦 JSON parsed successfully');
          final parsed = GenresResponse.fromJson(jsonData);

          print('✅ Successfully parsed ${parsed.values.length} genres');
          for (int i = 0; i < parsed.values.length && i < 5; i++) {
            print('🎭 Genre ${i + 1}: ${parsed.values[i].name}');
          }
          return parsed.values;
        } catch (parseError) {
          print('❌ JSON parse error: $parseError');
          print('📄 Response body preview: ${response.body.substring(
              0, response.body.length > 500 ? 500 : response.body.length)}');
          return [];
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Network error: $e');
      return [];
    }
  }

  /// Fetch comics by genre ID
  Future<List<Comic>> fetchComicsByGenre(String genreId) async {
    try {
      print('=== ComicService: Fetching comics by genre ID: $genreId ===');
      final uri = Uri.parse('$_baseUrl/Comics/genre/$genreId');
      print('🌐 Request URL: $uri');

      final client = _createClient();
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'text/plain',
          'User-Agent': 'demo-app/1.0 (flutter)',
        },
      ).timeout(const Duration(seconds: 15));
      client.close();

      print('📡 Response status: ${response.statusCode}');
      print('📏 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          print('📦 JSON parsed successfully');
          final parsed = ComicsResponse.fromJson(jsonData);

          print('✅ Successfully parsed ${parsed.values.length} comics for genre');
          return parsed.values;
        } catch (parseError) {
          print('❌ JSON parse error: $parseError');
          print('📄 Response body preview: ${response.body.substring(
              0, response.body.length > 500 ? 500 : response.body.length)}');
          return [];
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Network error: $e');
      return [];
    }
  }

  // ==================== UTILITIES ====================

  /// Test API connectivity
  Future<bool> testApi() async {
    try {
      print('Testing API connection...');
      final List<Comic> comics = await fetchComics(page: 1);
      final bool isWorking = comics.isNotEmpty;
      print('API test result: $isWorking');
      return isWorking;
    } catch (e) {
      print('API test error: $e');
      return false;
    }
  }

  // ==================== RESILIENT METHODS ====================
  //
  // Các method dưới đây sử dụng ResilientApiClient:
  // - Timeout 2.5s, fallback sang mock ngay lập tức
  // - Background retry với exponential backoff
  // - Deduplication: nhiều widget cùng gọi → 1 request
  // - Stream-based: UI tự update khi real data về

  final ResilientApiClient _resilientClient = ResilientApiClient();

  /// Stream truyện tranh trang [page] với đầy đủ resilience
  ///
  /// Emit ngay (mock hoặc cache), sau đó emit lại khi có real data.
  Stream<ComicDataState> watchComics({
    int page = 1,
    RetryConfig config = RetryConfig.defaultConfig,
  }) {
    final key = 'comics_page_$page';

    return _resilientClient
        .call<List<Comic>>(
          key: key,
          apiCall: () => fetchComics(page: page, forceRefresh: true),
          mockData: ComicMockData.getMockComicsForPage(page),
          config: config,
        )
        .map((result) => ComicLoaded(
              comics: result.data,
              isMock: result.isMock,
              isRefreshing: result.isRetrying,
              statusMessage: result.isMock
                  ? '📡 Đang kết nối lại máy chủ...'
                  : null,
            ));
  }

  /// Stream thể loại với đầy đủ resilience
  Stream<GenreDataState> watchGenres({
    RetryConfig config = RetryConfig.defaultConfig,
  }) {
    const key = 'genres_all';

    return _resilientClient
        .call<List<Genre>>(
          key: key,
          apiCall: () => fetchGenres(),
          mockData: ComicMockData.getMockGenres(),
          config: config,
        )
        .map((result) => GenreLoaded(
              genres: result.data,
              isMock: result.isMock,
            ));
  }

  /// Stream tìm kiếm với resilience
  Stream<ComicDataState> watchSearch({
    required String query,
    RetryConfig config = RetryConfig.defaultConfig,
  }) {
    final key = 'search_${query.toLowerCase()}';

    return _resilientClient
        .call<List<Comic>>(
          key: key,
          apiCall: () => searchComics(query),
          mockData: ComicMockData.getMockComics()
              .where((c) =>
                  c.name.toLowerCase().contains(query.toLowerCase()))
              .toList(),
          config: config,
        )
        .map((result) => ComicLoaded(
              comics: result.data,
              isMock: result.isMock,
              isRefreshing: result.isRetrying,
            ));
  }

  /// Stream truyện theo thể loại với resilience
  Stream<ComicDataState> watchComicsByGenre({
    required String genreId,
    RetryConfig config = RetryConfig.defaultConfig,
  }) {
    final key = 'genre_$genreId';

    return _resilientClient
        .call<List<Comic>>(
          key: key,
          apiCall: () => fetchComicsByGenre(genreId),
          mockData: ComicMockData.getMockComics(),
          config: config,
        )
        .map((result) => ComicLoaded(
              comics: result.data,
              isMock: result.isMock,
              isRefreshing: result.isRetrying,
            ));
  }

  /// Hủy toàn bộ stream resilient (gọi khi dispose)
  void cancelAllResilientStreams() {
    _resilientClient.cancelAll();
  }

  /// Hủy stream của một key cụ thể
  void cancelResilientStream(String key) {
    _resilientClient.cancel(key);
  }

  ComicsPagination? _extractPagination(
    Map<String, dynamic> jsonData,
    Map<String, String> headers,
  ) {
    final totalPages = _readInt(jsonData, [
      'totalPages',
      'totalPage',
      'pageCount',
      'total_pages',
    ]);
    final totalItems = _readInt(jsonData, [
      'totalItems',
      'totalCount',
      'total',
      'total_items',
      'count',
    ]);
    final pageSize = _readInt(jsonData, [
      'pageSize',
      'perPage',
      'page_size',
      'limit',
    ]);
    final pageIndex = _readInt(jsonData, [
      'pageIndex',
      'page',
      'currentPage',
      'pageNumber',
    ]);

    final headerTotalPages = _readIntFromHeaders(headers, [
      'x-total-pages',
      'x-page-count',
    ]);
    final headerTotalItems = _readIntFromHeaders(headers, [
      'x-total-count',
      'x-total-items',
      'x-total',
    ]);

    final paginationFromHeaders = _readPaginationFromHeader(headers);

    final merged = ComicsPagination(
      totalPages: totalPages ??
          paginationFromHeaders?.totalPages ??
          headerTotalPages,
      totalItems: totalItems ??
          paginationFromHeaders?.totalItems ??
          headerTotalItems,
      pageSize: pageSize ?? paginationFromHeaders?.pageSize,
      pageIndex: pageIndex ?? paginationFromHeaders?.pageIndex,
    );

    return merged.hasAnyValue ? merged : null;
  }

  ComicsPagination? _readPaginationFromHeader(
    Map<String, String> headers,
  ) {
    final raw = headers['x-pagination'] ?? headers['x-paging'];
    if (raw == null || raw.isEmpty) return null;

    try {
      final Map<String, dynamic> data = json.decode(raw);
      return ComicsPagination(
        totalPages: _readInt(data, ['totalPages', 'total_pages', 'pageCount']),
        totalItems: _readInt(data, ['totalItems', 'totalCount', 'total']),
        pageSize: _readInt(data, ['pageSize', 'perPage', 'page_size']),
        pageIndex: _readInt(data, ['pageIndex', 'page', 'currentPage']),
      );
    } catch (_) {
      return null;
    }
  }

  int? _readInt(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (!source.containsKey(key)) continue;
      final value = source[key];
      final parsed = _parseInt(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  int? _readIntFromHeaders(Map<String, String> headers, List<String> keys) {
    for (final key in keys) {
      final value = headers[key];
      if (value == null) continue;
      final parsed = _parseInt(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<int?> _resolveTotalPagesForFetchAll() async {
    if (lastEstimatedTotalPages != null) return lastEstimatedTotalPages;
    if (lastPagination?.totalPages != null) {
      return lastPagination!.totalPages;
    }
    return estimateTotalPages();
  }
}

