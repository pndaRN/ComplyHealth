import 'package:hive/hive.dart';

part 'education_content.g.dart';

@HiveType(typeId: 6)
class EducationContent {
  @HiveField(0)
  final String conditionCode;

  @HiveField(1)
  final List<Article> articles;

  @HiveField(2)
  final List<String> lifestyleTips;

  @HiveField(3)
  final List<Video> videos;

  EducationContent({
    required this.conditionCode,
    required this.articles,
    required this.lifestyleTips,
    required this.videos,
  });

  factory EducationContent.fromJson(Map<String, dynamic> json) {
    return EducationContent(
      conditionCode: json['conditionCode'] as String,
      articles: (json['articles'] as List<dynamic>?)
              ?.map((e) => Article.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lifestyleTips: (json['lifestyleTips'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      videos: (json['videos'] as List<dynamic>?)
              ?.map((e) => Video.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conditionCode': conditionCode,
      'articles': articles.map((e) => e.toJson()).toList(),
      'lifestyleTips': lifestyleTips,
      'videos': videos.map((e) => e.toJson()).toList(),
    };
  }
}

@HiveType(typeId: 7)
class Article {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String source;

  @HiveField(3)
  final String? description;

  Article({
    required this.title,
    required this.url,
    required this.source,
    this.description,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] as String,
      url: json['url'] as String,
      source: json['source'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'source': source,
      if (description != null) 'description': description,
    };
  }
}

@HiveType(typeId: 8)
class Video {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String? thumbnail;

  @HiveField(3)
  final String? duration;

  Video({
    required this.title,
    required this.url,
    this.thumbnail,
    this.duration,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      title: json['title'] as String,
      url: json['url'] as String,
      thumbnail: json['thumbnail'] as String?,
      duration: json['duration'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (duration != null) 'duration': duration,
    };
  }
}
