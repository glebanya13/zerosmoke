class UserSettingsModel {
  UserSettingsModel({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.hintsEnabled,
    required this.notifyTests,
    required this.notifyRankChanges,
    required this.dataCollection,
    required this.showActivity,
  });

  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool hintsEnabled;
  final bool notifyTests;
  final bool notifyRankChanges;
  final bool dataCollection;
  final bool showActivity;

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      soundEnabled: json['soundEnabled'] as bool,
      vibrationEnabled: json['vibrationEnabled'] as bool,
      hintsEnabled: json['hintsEnabled'] as bool,
      notifyTests: json['notifyTests'] as bool,
      notifyRankChanges: json['notifyRankChanges'] as bool,
      dataCollection: json['dataCollection'] as bool,
      showActivity: json['showActivity'] as bool,
    );
  }

  UserSettingsModel copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? hintsEnabled,
    bool? notifyTests,
    bool? notifyRankChanges,
    bool? dataCollection,
    bool? showActivity,
  }) {
    return UserSettingsModel(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      hintsEnabled: hintsEnabled ?? this.hintsEnabled,
      notifyTests: notifyTests ?? this.notifyTests,
      notifyRankChanges: notifyRankChanges ?? this.notifyRankChanges,
      dataCollection: dataCollection ?? this.dataCollection,
      showActivity: showActivity ?? this.showActivity,
    );
  }
}
