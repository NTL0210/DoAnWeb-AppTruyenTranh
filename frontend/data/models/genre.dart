/// Genre model
class Genre {
  final String id;
  final String slug;
  final String name;
  final String createdAt;
  final String updatedAt;
  final List<String>? comicGenres;

  Genre({
    required this.id,
    required this.slug,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.comicGenres,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] ?? '',
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      comicGenres: json['comicGenres'] != null
          ? (json['comicGenres'] as List).cast<String>()
          : null,
    );
  }
}

/// Genres response with $values wrapper
class GenresResponse {
  final String id;
  final List<Genre> values;

  GenresResponse({
    required this.id,
    required this.values,
  });

  factory GenresResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> valuesList = json['\$values'] ?? [];
    return GenresResponse(
      id: json['\$id'] ?? '',
      values: valuesList.map((item) => Genre.fromJson(item)).toList(),
    );
  }
}

