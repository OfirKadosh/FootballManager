enum NewsCategory { matchResult, transfer, objective, promotionRelegation, finance }

class NewsItem {
  final String id;
  final NewsCategory category;
  final String headline;
  final String body;
  final int gameWeek;
  bool read;

  NewsItem({
    required this.id,
    required this.category,
    required this.headline,
    required this.body,
    required this.gameWeek,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'headline': headline,
        'body': body,
        'game_week': gameWeek,
        'read': read,
      };

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
        id: json['id'] as String,
        category: NewsCategory.values.byName(json['category'] as String),
        headline: json['headline'] as String,
        body: json['body'] as String,
        gameWeek: json['game_week'] as int,
        read: json['read'] as bool? ?? false,
      );
}
