class LeaderboardEntry {
  LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.avatarIndex,
    required this.percent,
    required this.stars,
    required this.points,
    required this.total,
    required this.coins,
    required this.rewardsCount,
    required this.place,
  });

  final String userId;
  final String name;
  final int avatarIndex;
  final int percent;
  final int stars;
  final int points;
  final int total;
  final int coins;
  final int rewardsCount;
  final int place;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      name: json['name'] as String,
      avatarIndex: json['avatarIndex'] as int,
      percent: json['percent'] as int,
      stars: json['stars'] as int,
      points: json['points'] as int,
      total: json['total'] as int,
      coins: json['coins'] as int,
      rewardsCount: json['rewardsCount'] as int,
      place: json['place'] as int,
    );
  }
}

class RatingSectionStat {
  RatingSectionStat({required this.title, required this.progress, required this.total});

  final String title;
  final int progress;
  final int total;

  factory RatingSectionStat.fromJson(Map<String, dynamic> json) {
    return RatingSectionStat(
      title: json['title'] as String,
      progress: json['progress'] as int,
      total: json['total'] as int,
    );
  }
}

class RatingMe extends LeaderboardEntry {
  RatingMe({
    required super.userId,
    required super.name,
    required super.avatarIndex,
    required super.percent,
    required super.stars,
    required super.points,
    required super.total,
    required super.coins,
    required super.rewardsCount,
    required super.place,
    required this.sections,
  });

  final List<RatingSectionStat> sections;

  factory RatingMe.fromJson(Map<String, dynamic> json) {
    return RatingMe(
      userId: json['userId'] as String,
      name: json['name'] as String,
      avatarIndex: json['avatarIndex'] as int,
      percent: json['percent'] as int,
      stars: json['stars'] as int,
      points: json['points'] as int,
      total: json['total'] as int,
      coins: json['coins'] as int,
      rewardsCount: json['rewardsCount'] as int,
      place: json['place'] as int,
      sections: (json['sections'] as List)
          .map((e) => RatingSectionStat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
