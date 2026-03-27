import '../models/comic.dart';
import '../models/genre.dart';

/// Sealed class đại diện cho trạng thái data truyện tranh
///
/// Dùng với StreamBuilder hoặc ChangeNotifier để update UI an toàn.
sealed class ComicDataState {}

/// Đang tải lần đầu (chưa có data nào)
class ComicLoading extends ComicDataState {}

/// Đã có data (thật hoặc mock)
class ComicLoaded extends ComicDataState {
  /// Danh sách truyện tranh
  final List<Comic> comics;

  /// [true] = đang hiển thị mock data (API chưa sẵn sàng)
  final bool isMock;

  /// [true] = đang retry API ngầm trong background
  final bool isRefreshing;

  /// Thông báo hiển thị cho user (null = không hiển thị)
  final String? statusMessage;

  ComicLoaded({
    required this.comics,
    this.isMock = false,
    this.isRefreshing = false,
    this.statusMessage,
  });

  /// Tạo bản copy với các field được thay đổi
  ComicLoaded copyWith({
    List<Comic>? comics,
    bool? isMock,
    bool? isRefreshing,
    String? statusMessage,
  }) {
    return ComicLoaded(
      comics: comics ?? this.comics,
      isMock: isMock ?? this.isMock,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

/// Load thất bại hoàn toàn (không có cả mock)
class ComicFailed extends ComicDataState {
  final String message;
  final Object? error;

  ComicFailed({
    this.message = 'Không thể tải dữ liệu',
    this.error,
  });
}

// ──────────────────────────────────────────────
// Genre states
// ──────────────────────────────────────────────

sealed class GenreDataState {}

class GenreLoading extends GenreDataState {}

class GenreLoaded extends GenreDataState {
  final List<Genre> genres;
  final bool isMock;

  GenreLoaded({required this.genres, this.isMock = false});
}

class GenreFailed extends GenreDataState {
  final String message;
  GenreFailed({this.message = 'Không thể tải thể loại'});
}
