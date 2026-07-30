class QuitProfile {
  QuitProfile({
    required this.userId,
    required this.cigarettesPerDay,
    required this.packPriceCents,
    required this.cigarettesPerPack,
    required this.daysSmokeFree,
    required this.cigarettesAvoided,
    required this.moneySavedCents,
    this.quitDate,
  });

  final String userId;
  final DateTime? quitDate;
  final int cigarettesPerDay;
  final int packPriceCents;
  final int cigarettesPerPack;
  final int daysSmokeFree;
  final int cigarettesAvoided;
  final int moneySavedCents;

  factory QuitProfile.fromJson(Map<String, dynamic> json) {
    return QuitProfile(
      userId: json['userId'] as String,
      quitDate: json['quitDate'] != null ? DateTime.parse(json['quitDate'] as String) : null,
      cigarettesPerDay: json['cigarettesPerDay'] as int? ?? 0,
      packPriceCents: json['packPriceCents'] as int? ?? 0,
      cigarettesPerPack: json['cigarettesPerPack'] as int? ?? 20,
      daysSmokeFree: json['daysSmokeFree'] as int? ?? 0,
      cigarettesAvoided: json['cigarettesAvoided'] as int? ?? 0,
      moneySavedCents: json['moneySavedCents'] as int? ?? 0,
    );
  }
}

class CravingLog {
  CravingLog({
    required this.id,
    required this.intensity,
    required this.createdAt,
    this.note,
  });

  final String id;
  final int intensity;
  final String? note;
  final DateTime createdAt;

  factory CravingLog.fromJson(Map<String, dynamic> json) {
    return CravingLog(
      id: json['id'] as String,
      intensity: json['intensity'] as int,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
