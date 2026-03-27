import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../data/services/comic_service.dart';
import '../data/models/comic.dart';
import '../data/models/genre.dart';
import '../widgets/comic_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/genre_chips.dart';
import '../widgets/common_bottom_nav.dart';
import '../widgets/loading_indicator.dart' as widgets;
import 'book_details_screen.dart';
import 'enhanced_home_screen.dart';
import 'booklist_screen.dart';
import 'profile_screen.dart';

// Màn hình Khám phá (Explore) – nơi người dùng tìm truyện theo từ khóa và thể loại
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  int _selectedIndex = 1; // Tab đang chọn ở thanh điều hướng dưới (Explore = 1)
  final TextEditingController _searchController = TextEditingController(); // Điều khiển ô tìm kiếm
  
  // Dữ liệu lấy từ API
  List<Comic> _comics = []; // Danh sách truyện hiển thị
  String _selectedSort = 'Popular'; // Tuỳ chọn sắp xếp (hiện chưa dùng nhiều)
  bool _isGridView = true; // Chuyển đổi giữa dạng lưới và danh sách
  bool _isLoadingComics = false; // Trạng thái tải danh sách truyện
  String? _error; // Lưu lỗi nếu có khi gọi API
  int _currentPage = 1; // Trang hiện tại (để tải thêm)
  bool _hasMorePages = true; // Còn trang để tải không
  
  // Chọn thể loại
  Set<String> _selectedGenres = {}; // Tập các tên thể loại đã chọn
  List<Genre> _availableGenres = []; // Danh sách thể loại lấy từ API
  bool _isLoadingGenres = false; // Trạng thái tải danh sách thể loại
  
  // Hiệu ứng mờ dần khi xuất hiện item
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Chống gọi API liên tục khi gõ phím (debounce)
  Timer? _debounceTimer;
  
  bool _isLoadingMore = false; // Đang tải thêm dữ liệu hay không
  final ScrollController _scrollController = ScrollController(); // Theo dõi vị trí cuộn để auto tải thêm

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Tải danh sách thể loại từ API khi mở màn hình
    _loadGenres();
    
    // Lắng nghe vị trí cuộn để gọi tải thêm khi gần cuối danh sách
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMoreComics();
      }
    });
  }

  Future<void> _loadGenres() async {
    setState(() {
      _isLoadingGenres = true;
    });
    
    try {
      final genres = await ComicService().fetchGenres();
      setState(() {
        _availableGenres = genres;
        _isLoadingGenres = false;
      });
      print('Loaded ${genres.length} genres from API');
    } catch (e) {
      print('Error loading genres: $e');
      setState(() {
        _isLoadingGenres = false;
      });
    }
  }

  // Chuẩn hoá chuỗi để tìm kiếm: bỏ dấu tiếng Việt, ký tự kết hợp và không phân biệt hoa/thường
  String _normalize(String input) {
    const Map<String, String> vi = {
      'à':'a','á':'a','ả':'a','ã':'a','ạ':'a','ă':'a','ằ':'a','ắ':'a','ẳ':'a','ẵ':'a','ặ':'a','â':'a','ầ':'a','ấ':'a','ẩ':'a','ẫ':'a','ậ':'a',
      'è':'e','é':'e','ẻ':'e','ẽ':'e','ẹ':'e','ê':'e','ề':'e','ế':'e','ể':'e','ễ':'e','ệ':'e',
      'ì':'i','í':'i','ỉ':'i','ĩ':'i','ị':'i',
      'ò':'o','ó':'o','ỏ':'o','õ':'o','ọ':'o','ô':'o','ồ':'o','ố':'o','ổ':'o','ỗ':'o','ộ':'o','ơ':'o','ờ':'o','ớ':'o','ở':'o','ỡ':'o','ợ':'o',
      'ù':'u','ú':'u','ủ':'u','ũ':'u','ụ':'u','ư':'u','ừ':'u','ứ':'u','ử':'u','ữ':'u','ự':'u',
      'ỳ':'y','ý':'y','ỷ':'y','ỹ':'y','ỵ':'y',
      'đ':'d',
      'À':'A','Á':'A','Ả':'A','Ã':'A','Ạ':'A','Ă':'A','Ằ':'A','Ắ':'A','Ẳ':'A','Ẵ':'A','Ặ':'A','Â':'A','Ầ':'A','Ấ':'A','Ẩ':'A','Ẫ':'A','Ậ':'A',
      'È':'E','É':'E','Ẻ':'E','Ẽ':'E','Ẹ':'E','Ê':'E','Ề':'E','Ế':'E','Ể':'E','Ễ':'E','Ệ':'E',
      'Ì':'I','Í':'I','Ỉ':'I','Ĩ':'I','Ị':'I',
      'Ò':'O','Ó':'O','Ỏ':'O','Õ':'O','Ọ':'O','Ô':'O','Ồ':'O','Ố':'O','Ổ':'O','Ỗ':'O','Ộ':'O','Ơ':'O','Ờ':'O','Ớ':'O','Ở':'O','Ỡ':'O','Ợ':'O',
      'Ù':'U','Ú':'U','Ủ':'U','Ũ':'U','Ụ':'U','Ư':'U','Ừ':'U','Ứ':'U','Ử':'U','Ữ':'U','Ự':'U',
      'Ỳ':'Y','Ý':'Y','Ỷ':'Y','Ỹ':'Y','Ỵ':'Y',
      'Đ':'D'
    };
    
    final StringBuffer sb = StringBuffer();
    final String safe = input.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '');
    for (int i = 0; i < safe.length; i++) {
      final String ch = safe[i];
      sb.write(vi[ch] ?? ch);
    }
    final noCombining = sb.toString().replaceAll(RegExp('[\u0300-\u036f]'), '');
    return noCombining.toLowerCase();
  }

  // Gọi API lấy truyện theo từ khoá hoặc thể loại đã chọn
  Future<void> _fetchComics({bool loadMore = false}) async {
    // Nếu chưa nhập từ khoá và chưa chọn thể loại thì không gọi API
    if (_searchController.text.isEmpty && _selectedGenres.isEmpty) {
      return;
    }

    try {
      setState(() {
        _isLoadingComics = true;
        _error = null;
        if (!loadMore) {
          _currentPage = 1;
            _comics.clear();
        }
      });

      List<Comic> comics = [];
      
      // Nếu có chọn thể loại: ưu tiên gọi API theo thể loại
      if (_selectedGenres.isNotEmpty) {
        // Lấy ID của thể loại đầu tiên đang chọn (API hiện nhận một ID)
        final selectedGenre = _availableGenres.firstWhere(
          (genre) => _selectedGenres.contains(genre.name),
          orElse: () => _availableGenres.first,
        );
        comics = await ComicService().fetchComicsByGenre(selectedGenre.id);
        
        // Nếu đồng thời có từ khoá, lọc kết quả theo tên truyện
        if (_searchController.text.isNotEmpty) {
          final String query = _normalize(_searchController.text);
          comics = comics.where((comic) {
            final String nameNorm = _normalize(comic.name);
            return nameNorm.contains(query);
          }).toList();
        }
      } else if (_searchController.text.isNotEmpty) {
        // Không chọn thể loại thì dùng API tìm kiếm theo từ khoá
        comics = await ComicService().searchComics(_searchController.text);
      }

       if (mounted) {
         setState(() {
           if (loadMore) {
             // Chỉ thêm các truyện mới (tránh trùng ID)
             final existingIds = _comics.map((c) => c.comicId).toSet();
             final newComics = comics.where((c) => !existingIds.contains(c.comicId)).toList();
             _comics.addAll(newComics);
             _isLoadingMore = false; // Reset loading more flag
             
             // Khi tải thêm: nếu số kết quả ít hơn kích thước trang, hiểu là hết trang
             _hasMorePages = comics.length >= 12;
           } else {
             // Tải lần đầu: thay thế toàn bộ danh sách
             _comics = comics;
             _isLoadingComics = false;
             
             // Kiểm tra còn trang hay không theo kích thước trang dự kiến
             _hasMorePages = comics.length >= 12;
           }
           
           // Trả về rỗng: coi như hết dữ liệu
           if (comics.isEmpty) {
             _hasMorePages = false;
           }
         });
       }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingComics = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  // Tải thêm dữ liệu khi người dùng cuộn đến cuối
  void _loadMoreComics() {
    if (!_isLoadingComics && !_isLoadingMore && _hasMorePages && _comics.isNotEmpty) {
      _isLoadingMore = true;
      _currentPage++;
      _fetchComics(loadMore: true);
    }
  }

  void _showGenreSelectionModal() {
    final theme = Theme.of(context);
    final translate = LanguageProvider.of(context)?.translate ?? LanguageManager.translate;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder( // ✅ Thêm StatefulBuilder
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: theme.cardColor, // ✅ Dark mode support
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
          children: [
            // Thanh kéo ở đầu bottom sheet
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Tiêu đề và các nút thao tác của bottom sheet chọn thể loại
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    translate('select_genre'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          // ✅ Dùng setModalState để update UI trong modal
                          setModalState(() {
                            _selectedGenres.clear();
                          });
                          // ✅ Cũng cần update parent state
                          setState(() {});
                        },
                        child: Text(
                          translate('clear_all'),
                          style: TextStyle(color: AppTheme.primaryBlue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _fetchComics(); // Refresh with selected genres
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          translate('done'),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Lưới hiển thị toàn bộ thể loại để chọn/bỏ chọn
            Expanded(
              child: _isLoadingGenres
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _availableGenres.length,
                        itemBuilder: (context, index) {
                          final genre = _availableGenres[index];
                          final isSelected = _selectedGenres.contains(genre.name);
                          
                          return GestureDetector(
                            onTap: () {
                              // ✅ Dùng setModalState để update UI trong modal ngay lập tức
                              setModalState(() {
                                if (isSelected) {
                                  _selectedGenres.remove(genre.name);
                                } else {
                                  _selectedGenres.add(genre.name);
                                }
                              });
                              // ✅ Cũng update parent state
                              setState(() {});
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? AppTheme.primaryBlue 
                                    : theme.cardColor, // ✅ Dark mode
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected 
                                      ? AppTheme.primaryBlue 
                                      : theme.dividerColor, // ✅ Dark mode
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  genre.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color, // ✅ Dark mode
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
          ); // ✅ Đóng Container
        }, // ✅ Đóng StatefulBuilder builder
      ), // ✅ Đóng StatefulBuilder
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ Dark mode support
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSearchSection(),
          _buildBooksSection(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Thanh tiêu đề phía trên cùng (AppBar tuỳ biến)
  Widget _buildAppBar() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'Explore',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: () {
                      // Show filter options
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Khu vực tìm kiếm: ô nhập, chọn thể loại, chuyển đổi lưới/danh sách
  Widget _buildSearchSection() {
    final theme = Theme.of(context); // ✅ Get theme from context
    final translate = LanguageProvider.of(context)?.translate ?? LanguageManager.translate;
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Ô nhập từ khoá tìm kiếm
            Container(
        decoration: BoxDecoration(
                color: theme.cardColor, // ✅ Dark mode
                borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
                  hintText: 'Search books, authors, genres...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _comics.clear();
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Colors.grey),
                        onPressed: () {
                          _showGenreSelectionModal();
                        },
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                    if (value.isNotEmpty) {
                _fetchComics();
                    } else {
                      setState(() {
                        _comics.clear();
                      });
              }
            });
          },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _fetchComics();
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            // Hàng nút: mở chọn thể loại + nút chuyển kiểu hiển thị
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showGenreSelectionModal(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedGenres.isEmpty 
                                ? translate('select_genre')
                                : '${_selectedGenres.length} ${translate('genres')}',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isGridView 
                          ? AppTheme.primaryBlue 
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isGridView ? Icons.grid_view : Icons.list,
                      color: _isGridView ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Khu vực nội dung kết quả
  Widget _buildBooksSection() {
    final translate = LanguageProvider.of(context)?.translate ?? LanguageManager.translate;
    // Trạng thái ban đầu: chưa tìm kiếm và chưa chọn thể loại -> hiển thị gif + hướng dẫn
    if (_searchController.text.isEmpty && _selectedGenres.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.55,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // GIF loading animation
              Image.asset(
                'lib/Loading/everknight-evernight.gif',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  translate('start_search_hint'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingComics) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  '${translate('error_prefix')} $_error',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.red.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _fetchComics(),
                  child: Text(translate('retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredComics = _getFilteredComics();
    
    if (filteredComics.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  translate('no_results'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedGenres.isNotEmpty 
                      ? translate('try_other_genre_or_keyword')
                      : translate('try_other_keyword'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Hiển thị phần thông tin tìm kiếm/đã chọn thể loại và danh sách kết quả
    return SliverList(
      delegate: SliverChildListDelegate([
        // Khối thông tin điều kiện lọc (từ khoá, thể loại) + nút xoá
        if (_searchController.text.isNotEmpty || _selectedGenres.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
            child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      if (_searchController.text.isNotEmpty)
                Text(
                          'Tìm kiếm: "${_searchController.text}"',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (_selectedGenres.isNotEmpty)
                Text(
                          'Thể loại: ${_selectedGenres.join(", ")}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Tìm thấy ${filteredComics.length} truyện',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryBlue.withOpacity(0.8),
                        ),
                ),
              ],
            ),
          ),
                if (_selectedGenres.isNotEmpty || _searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedGenres.clear();
                        _searchController.clear();
                        _comics.clear();
                      });
                    },
                    icon: Icon(
                      Icons.clear,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        // Lưới/ký danh sách kết quả với nút tải thêm ở cuối
        Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _isGridView ? 2 : 1,
              childAspectRatio: _isGridView ? 0.7 : 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredComics.length + (_hasMorePages && !_isLoadingComics && !_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < filteredComics.length) {
                return _isGridView 
                    ? _buildComicCard(filteredComics[index])
                    : _buildComicListItem(filteredComics[index]);
              } else if (index == filteredComics.length && _hasMorePages && !_isLoadingComics && !_isLoadingMore) {
                return _buildLoadMoreButton();
              } else if (index == filteredComics.length && _isLoadingMore) {
                return const Center(child: CircularProgressIndicator());
              }
              return null;
            },
          ),
        ),
      ]),
    );
  }

  List<Comic> _getFilteredComics() {
    List<Comic> filtered = _comics;
    
    // Lọc theo từ khoá (không dấu, không phân biệt hoa/thường)
    if (_searchController.text.isNotEmpty) {
      final String query = _normalize(_searchController.text);
      filtered = filtered.where((comic) {
        final String nameNorm = _normalize(comic.name);
        final bool nameMatch = nameNorm.contains(query);
        // Lớp Comic không có danh sách thể loại, nên chỉ lọc theo tên
        return nameMatch;
      }).toList();
    }
    
    // Sắp xếp danh sách theo lựa chọn
    switch (_selectedSort) {
      case 'A-Z':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Z-A':
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Newest':
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      default: // Mặc định: giữ nguyên thứ tự trả về từ API
        break;
    }
    
    return filtered;
  }

  Widget _buildComicCard(Comic comic) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
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
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh bìa truyện
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: comic.thumbUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage('https://img.otruyenapi.com/uploads/comics/${comic.thumbUrl}'),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: comic.thumbUrl.isEmpty
                      ? const Center(
                          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                        )
                      : null,
                ),
              ),
              // Thông tin truyện (tên, trạng thái)
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comic.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comic.status,
                        style: Theme.of(context).textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // Lớp Comic không có danh sách thể loại: hiển thị trạng thái thay thế
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                          comic.status,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
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
      ),
    );
  }

  Widget _buildComicListItem(Comic comic) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailsScreen(slug: comic.slug),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              // Ảnh bìa truyện
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: comic.thumbUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage('https://img.otruyenapi.com/uploads/comics/${comic.thumbUrl}'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: comic.thumbUrl.isEmpty
                    ? const Center(
                        child: Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Thông tin truyện (tên, trạng thái)
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comic.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comic.status,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    // Lớp Comic không có danh sách thể loại: hiển thị trạng thái thay thế
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                        comic.status,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Nút "Tải thêm" hiển thị ở cuối danh sách
  Widget _buildLoadMoreButton() {
            return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: _loadMoreComics,
        child: const Text('Tải thêm'),
      ),
    );
  }

  // Thanh điều hướng dưới cùng (Bottom Navigation)
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
            return; // Đã ở Explore
          case 2:
            destination = const BookListScreen();
            break;
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