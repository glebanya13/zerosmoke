class AchievementModel {
  AchievementModel({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.unlocked,
    required this.progress,
    required this.total,
  });

  final String code;
  final String title;
  final String subtitle;
  final bool unlocked;
  final int progress;
  final int total;

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      code: json['code'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      unlocked: json['unlocked'] as bool,
      progress: json['progress'] as int,
      total: json['total'] as int,
    );
  }
}
