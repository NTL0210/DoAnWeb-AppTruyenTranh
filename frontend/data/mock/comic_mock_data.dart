import '../models/comic.dart';
import '../models/genre.dart';
import '../models/comic_genre.dart';

/// Mock data dùng khi API không khả dụng
///
/// Đảm bảo user luôn thấy nội dung thay vì màn hình trống.
class ComicMockData {
  // ──────────────────────────────────────────────
  // Mock Comics
  // ──────────────────────────────────────────────

  /// Trả về danh sách truyện tranh mock
  static List<Comic> getMockComics() {
    return [
      Comic(
        comicId: 'mock-001',
        name: 'Naruto',
        slug: 'naruto',
        originName: 'ナルト',
        status: 'Hoàn thành',
        thumbUrl: 'https://via.placeholder.com/150x200/EF4444/FFFFFF?text=Naruto',
        subDocquyen: false,
        chaptersLatest: '[]',
        updatedAt: '2024-01-01T00:00:00',
        createdAt: '2024-01-01T00:00:00',
        modifiedAt: '2024-01-01T00:00:00',
        comicGenres: [
          ComicGenre(
            id: 1,
            comicId: 'mock-001',
            genreId: 'mock-g1',
            createdAt: '',
            comic: '',
            genre: null,
          ),
        ],
      ),
      Comic(
        comicId: 'mock-002',
        name: 'One Piece',
        slug: 'one-piece',
        originName: 'ワンピース',
        status: 'Đang tiến hành',
        thumbUrl: 'https://via.placeholder.com/150x200/3B82F6/FFFFFF?text=One+Piece',
        subDocquyen: false,
        chaptersLatest: '[]',
        updatedAt: '2024-01-02T00:00:00',
        createdAt: '2024-01-02T00:00:00',
        modifiedAt: '2024-01-02T00:00:00',
        comicGenres: [],
      ),
      Comic(
        comicId: 'mock-003',
        name: 'Attack on Titan',
        slug: 'attack-on-titan',
        originName: '進撃の巨人',
        status: 'Hoàn thành',
        thumbUrl: 'https://via.placeholder.com/150x200/1F2937/FFFFFF?text=AOT',
        subDocquyen: false,
        chaptersLatest: '[]',
        updatedAt: '2024-01-03T00:00:00',
        createdAt: '2024-01-03T00:00:00',
        modifiedAt: '2024-01-03T00:00:00',
        comicGenres: [],
      ),
      Comic(
        comicId: 'mock-004',
        name: 'Dragon Ball Z',
        slug: 'dragon-ball-z',
        originName: 'ドラゴンボールZ',
        status: 'Hoàn thành',
        thumbUrl: 'https://via.placeholder.com/150x200/F59E0B/FFFFFF?text=DBZ',
        subDocquyen: false,
        chaptersLatest: '[]',
        updatedAt: '2024-01-04T00:00:00',
        createdAt: '2024-01-04T00:00:00',
        modifiedAt: '2024-01-04T00:00:00',
        comicGenres: [],
      ),
      Comic(
        comicId: 'mock-005',
        name: 'Demon Slayer',
        slug: 'demon-slayer',
        originName: '鬼滅の刃',
        status: 'Hoàn thành',
        thumbUrl: 'https://via.placeholder.com/150x200/7C3AED/FFFFFF?text=DS',
        subDocquyen: false,
        chaptersLatest: '[]',
        updatedAt: '2024-01-05T00:00:00',
        createdAt: '2024-01-05T00:00:00',
        modifiedAt: '2024-01-05T00:00:00',
        comicGenres: [],
      ),
      Comic(
        comicId: 'mock-006',
        name: 'My Hero Academia',
        slug: 'my-hero-academia',
        originName: '僕のヒーローアカデミア',
        status: 'Đang tiến hành',
        thumbUrl: 'https://via.placeholder.com/150x200/10B981/FFFFFF?text=MHA',
        subDocquyen: false,
        chaptersLatest: '[]',
        updatedAt: '2024-01-06T00:00:00',
        createdAt: '2024-01-06T00:00:00',
        modifiedAt: '2024-01-06T00:00:00',
        comicGenres: [],
      ),
      Comic(
        comicId: 'mock-007',
        name: 'Bleach',
        slug: 'bleach',
        originName: 'ブリーチ',
        status: 'Hoàn thành',
        thumbUrl: 'https://via.placeholder.com/150x200/6366F1/FFFFFF?text=Bleach',
        subDocquyen: false,
        chaptersLatest: '[]',
        updatedAt: '2024-01-07T00:00:00',
        createdAt: '2024-01-07T00:00:00',
        modifiedAt: '2024-01-07T00:00:00',
        comicGenres: [],
      ),
      Comic(
        comicId: 'mock-008',
        name: 'Tokyo Ghoul',
        slug: 'tokyo-ghoul',
        originName: '東京喰種',
        status: 'Hoàn thành',
        thumbUrl: 'https://via.placeholder.com/150x200/EC4899/FFFFFF?text=TG',
        subDocquyen: false,
        chaptersLatest: '[]',
        updatedAt: '2024-01-08T00:00:00',
        createdAt: '2024-01-08T00:00:00',
        modifiedAt: '2024-01-08T00:00:00',
        comicGenres: [],
      ),
    ];
  }

  // ──────────────────────────────────────────────
  // Mock Genres
  // ──────────────────────────────────────────────

  /// Trả về danh sách thể loại mock (dùng đúng field của Genre model)
  static List<Genre> getMockGenres() {
    return [
      Genre(id: 'mock-g1', name: 'Hành động', slug: 'hanh-dong', createdAt: '', updatedAt: ''),
      Genre(id: 'mock-g2', name: 'Phiêu lưu', slug: 'phieu-luu', createdAt: '', updatedAt: ''),
      Genre(id: 'mock-g3', name: 'Tình cảm', slug: 'tinh-cam', createdAt: '', updatedAt: ''),
      Genre(id: 'mock-g4', name: 'Học đường', slug: 'hoc-duong', createdAt: '', updatedAt: ''),
      Genre(id: 'mock-g5', name: 'Kinh dị', slug: 'kinh-di', createdAt: '', updatedAt: ''),
      Genre(id: 'mock-g6', name: 'Hài hước', slug: 'hai-huoc', createdAt: '', updatedAt: ''),
      Genre(id: 'mock-g7', name: 'Fantasy', slug: 'fantasy', createdAt: '', updatedAt: ''),
      Genre(id: 'mock-g8', name: 'Isekai', slug: 'isekai', createdAt: '', updatedAt: ''),
    ];
  }

  /// Trả về mock comics theo trang (mock không phân biệt page, luôn trả cùng list)
  static List<Comic> getMockComicsForPage(int page) {
    return getMockComics();
  }
}
