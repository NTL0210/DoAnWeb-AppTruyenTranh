/// Model cho thông báo crawler từ SignalR
class CrawlNotification {
  final String comicId;
  final String comicName;
  final String? chapterName;
  final int? chapterIndex;
  final String? thumbUrl;
  final String? comicSlug;
  final bool isNewComic;
  final bool isSuggestion;
  final bool isFollowed;
  final DateTime timestampUtc;

  CrawlNotification({
    required this.comicId,
    required this.comicName,
    this.chapterName,
    this.chapterIndex,
    this.thumbUrl,
    this.comicSlug,
    required this.isNewComic,
    required this.isSuggestion,
    required this.isFollowed,
    required this.timestampUtc,
  });

  factory CrawlNotification.fromJson(Map<String, dynamic> json) {
    return CrawlNotification(
      comicId: json['comicId'] as String,
      comicName: json['comicName'] as String,
      chapterName: json['chapterName'] as String?,
      chapterIndex: json['chapterIndex'] as int?,
      thumbUrl: json['thumbUrl'] as String?,
      comicSlug: json['comicSlug'] as String?,
      isNewComic: json['isNewComic'] as bool? ?? false,
      isSuggestion: json['isSuggestion'] as bool? ?? false,
      isFollowed: json['isFollowed'] as bool? ?? false,
      timestampUtc: DateTime.parse(json['timestampUtc'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comicId': comicId,
      'comicName': comicName,
      'chapterName': chapterName,
      'chapterIndex': chapterIndex,
      'thumbUrl': thumbUrl,
      'comicSlug': comicSlug,
      'isNewComic': isNewComic,
      'isSuggestion': isSuggestion,
      'isFollowed': isFollowed,
      'timestampUtc': timestampUtc.toIso8601String(),
    };
  }
}

