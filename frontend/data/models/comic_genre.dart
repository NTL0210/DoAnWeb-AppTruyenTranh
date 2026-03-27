import 'genre.dart';

/// Comic-Genre relationship model
class ComicGenre {
  final int id;
  final String comicId;
  final String genreId;
  final String createdAt;
  final String comic;
  final Genre? genre;

  ComicGenre({
    required this.id,
    required this.comicId,
    required this.genreId,
    required this.createdAt,
    required this.comic,
    this.genre,
  });

  factory ComicGenre.fromJson(Map<String, dynamic> json) {
    return ComicGenre(
      id: json['id'] ?? 0,
      comicId: json['comicId'] ?? '',
      genreId: json['genreId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      comic: json['comic'] ?? '',
      genre: json['genre'] != null ? Genre.fromJson(json['genre']) : null,
    );
  }
}

