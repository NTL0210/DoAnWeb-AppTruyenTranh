import 'dart:convert';
import 'comic_chapter.dart';
import 'comic_genre.dart';

/// Comic model
class Comic {
  final String comicId;
  final String name;
  final String slug;
  final String originName;
  final String status;
  final String thumbUrl;
  final bool subDocquyen;
  final String chaptersLatest;
  final String updatedAt;
  final String createdAt;
  final String modifiedAt;
  final List<ComicChapter>? chapters;
  final List<ComicGenre>? comicGenres;

  Comic({
    required this.comicId,
    required this.name,
    required this.slug,
    required this.originName,
    required this.status,
    required this.thumbUrl,
    required this.subDocquyen,
    required this.chaptersLatest,
    required this.updatedAt,
    required this.createdAt,
    required this.modifiedAt,
    this.chapters,
    this.comicGenres,
  });

  factory Comic.fromJson(Map<String, dynamic> json) {
    return Comic(
      comicId: json['comicId'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      originName: json['originName'] ?? '',
      status: json['status'] ?? '',
      thumbUrl: json['thumbUrl'] ?? '',
      subDocquyen: json['subDocquyen'] ?? false,
      chaptersLatest: json['chaptersLatest'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      createdAt: json['createdAt'] ?? '',
      modifiedAt: json['modifiedAt'] ?? '',
      chapters: json['chapters'] != null
          ? _parseChaptersFromJson(json['chapters'])
          : null,
      comicGenres: json['comicGenres'] != null
          ? _parseComicGenresFromJson(json['comicGenres'])
          : null,
    );
  }

  /// Convert to UI-compatible map
  Map<String, dynamic> toComicItem() {
    return {
      'id': comicId,
      'name': name,
      'slug': slug,
      'thumbUrl': thumbUrl.isNotEmpty
          ? 'https://img.otruyenapi.com/uploads/comics/$thumbUrl'
          : null,
      'categories': [],
      'chapterName': _extractChapterName(),
      'status': status,
      'updatedAt': updatedAt,
    };
  }

  String? _extractChapterName() {
    try {
      if (chaptersLatest.isNotEmpty) {
        final List<dynamic> chapters = json.decode(chaptersLatest);
        if (chapters.isNotEmpty) {
          return chapters.first['chapter_name']?.toString();
        }
      }
    } catch (e) {
      print('Error parsing chapters: $e');
    }
    return null;
  }

  static List<ComicChapter>? _parseChaptersFromJson(dynamic chaptersData) {
    try {
      if (chaptersData is Map<String, dynamic>) {
        if (chaptersData.containsKey('\$values')) {
          final List<dynamic> valuesList = chaptersData['\$values'] ?? [];
          print('📚 Parsing chapters from \$values: ${valuesList.length} items');
          final chapterList =
              valuesList.map((e) => ComicChapter.fromJson(e)).toList();
          print('✅ Successfully parsed ${chapterList.length} chapters');
          return chapterList;
        }
      } else if (chaptersData is List) {
        print('📚 Parsing chapters from List: ${chaptersData.length} items');
        final chapterList =
            chaptersData.map((e) => ComicChapter.fromJson(e)).toList();
        print('✅ Successfully parsed ${chapterList.length} chapters');
        return chapterList;
      }
    } catch (e) {
      print('❌ Error parsing chapters from JSON: $e');
      print('📋 Chapters data type: ${chaptersData.runtimeType}');
    }
    return null;
  }

  static List<ComicGenre>? _parseComicGenresFromJson(dynamic comicGenresData) {
    try {
      if (comicGenresData is Map<String, dynamic>) {
        if (comicGenresData.containsKey('\$values')) {
          final List<dynamic> valuesList = comicGenresData['\$values'] ?? [];
          return valuesList.map((e) => ComicGenre.fromJson(e)).toList();
        }
      } else if (comicGenresData is List) {
        return comicGenresData.map((e) => ComicGenre.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error parsing comicGenres from JSON: $e');
    }
    return null;
  }
}

/// Comics response with $values wrapper
class ComicsResponse {
  final String id;
  final List<Comic> values;

  ComicsResponse({
    required this.id,
    required this.values,
  });

  factory ComicsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> valuesList = json['\$values'] ?? [];
    return ComicsResponse(
      id: json['\$id'] ?? '',
      values: valuesList.map((item) => Comic.fromJson(item)).toList(),
    );
  }
}

