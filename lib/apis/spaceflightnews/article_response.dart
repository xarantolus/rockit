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

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json["id"],
      title: json["title"],
      url: json["url"],
      imageUrl: json["image_url"],
      newsSite: json["news_site"],
      summary: json["summary"],
      publishedAt: json["published_at"] == null ? null : DateTime.parse(json["published_at"]),
      updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
      featured: json["featured"],
    );
  }
}
