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
  final List<LaunchInfo>? launches;
  final List<Event>? events;

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
      launches:
          json["launches"] == null ? null : List<LaunchInfo>.from(json["launches"].map((x) => LaunchInfo.fromJson(x))),
      events: json["events"] == null ? null : List<Event>.from(json["events"].map((x) => Event.fromJson(x))),
    );
  }
}

class Event {
  Event({
    required this.id,
    required this.provider,
  });

  final int id;
  final String? provider;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json["id"],
      provider: json["provider"],
    );
  }
}

class LaunchInfo {
  LaunchInfo({
    required this.id,
    required this.provider,
  });

  final String id;
  final String? provider;

  factory LaunchInfo.fromJson(Map<String, dynamic> json) {
    return LaunchInfo(
      id: json["id"],
      provider: json["provider"],
    );
  }
}
