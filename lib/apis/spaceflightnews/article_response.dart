class Article {
  Article({
    required this.id,
    required this.title,
    required this.url,
    required this.imageUrl,
    required this.newsSite,
    required this.summary,
    required this.publishedAt,
    required this.updatedAt,
    required this.featured,
    required this.launches,
    required this.events,
  });

  final int id;
  final String? title;
  final String? url;
  final String? imageUrl;
  final String? newsSite;
  final String? summary;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final bool? featured;
  final List<BasicLaunchInfo>? launches;
  final List<BasicEventInfo>? events;

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json["id"],
      title: json["title"],
      url: json["url"],
      imageUrl: json["imageUrl"],
      newsSite: json["newsSite"],
      summary: json["summary"],
      publishedAt: json["publishedAt"] == null ? null : DateTime.parse(json["publishedAt"]),
      updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
      featured: json["featured"],
      launches: json["launches"] == null
          ? null
          : List<BasicLaunchInfo>.from(json["launches"].map((x) => BasicLaunchInfo.fromJson(x))),
      events: json["events"] == null
          ? null
          : List<BasicEventInfo>.from(json["events"].map((x) => BasicEventInfo.fromJson(x))),
    );
  }
}

class BasicEventInfo {
  BasicEventInfo({
    required this.id,
    required this.provider,
  });

  final int id;
  final String? provider;

  factory BasicEventInfo.fromJson(Map<String, dynamic> json) {
    return BasicEventInfo(
      id: json["id"],
      provider: json["provider"],
    );
  }
}

class BasicLaunchInfo {
  BasicLaunchInfo({
    required this.id,
    required this.provider,
  });

  final String id;
  final String? provider;

  factory BasicLaunchInfo.fromJson(Map<String, dynamic> json) {
    return BasicLaunchInfo(
      id: json["id"],
      provider: json["provider"],
    );
  }
}
