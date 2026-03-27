/// Comic chapter model
class ComicChapter {
  final int id;
  final String comicId;
  final String slug;
  final String serverName;
  final int serverIndex;
  final int chapterIndex;
  final String filename;
  final String chapterName;
  final String chapterTitle;
  final String chapterApiData;
  final String createdAt;
  final String updatedAt;

  ComicChapter({
    required this.id,
    required this.comicId,
    required this.slug,
    required this.serverName,
    required this.serverIndex,
    required this.chapterIndex,
    required this.filename,
    required this.chapterName,
    required this.chapterTitle,
    required this.chapterApiData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ComicChapter.fromJson(Map<String, dynamic> json) {
    return ComicChapter(
      id: json['id'] ?? 0,
      comicId: json['comicId'] ?? '',
      slug: json['slug'] ?? '',
      serverName: json['serverName'] ?? '',
      serverIndex: json['serverIndex'] ?? 0,
      chapterIndex: json['chapterIndex'] ?? 0,
      filename: json['filename'] ?? '',
      chapterName: json['chapterName'] ?? '',
      chapterTitle: json['chapterTitle'] ?? '',
      chapterApiData: json['chapterApiData'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

