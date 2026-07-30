import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/top_stats_bar.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/rating_models.dart';
import '../../data/repositories/achievements_repository.dart';
import '../../data/repositories/rating_repository.dart';

/// Достижения: полученные и в процессе, из реальных данных.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _loading = true;
  String? _error;
  List<AchievementModel> _achievements = [];
  RatingMe? _me;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        context.read<AchievementsRepository>().getAll(),
        context.read<RatingRepository>().getMe(),
      ]);
      if (!mounted) return;
      setState(() {
        _achievements = results[0] as List<AchievementModel>;
        _me = results[1] as RatingMe;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _achievements.where((a) => a.unlocked).toList();
    final inProgress = _achievements.where((a) => !a.unlocked).toList();

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, 16, AppSpacing.md, 0),
              child: ScreenHeader(title: 'Достижения'),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!, style: AppTextStyles.body))
                  : ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        TopStatsBar(
                          name: _me!.name,
                          percent: _me!.percent,
                          stars: _me!.stars,
                          coins: _me!.coins,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Text('Полученные', style: AppTextStyles.sectionTitle),
                        const SizedBox(height: AppSpacing.sm),
                        _rewardGrid(unlocked),
                        const SizedBox(height: AppSpacing.lg),
                        const Text('В процессе', style: AppTextStyles.sectionTitle),
                        const SizedBox(height: AppSpacing.sm),
                        _rewardGrid(inProgress),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardGrid(List<AchievementModel> achievements) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.6,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, i) {
        final achievement = achievements[i];
        return AppCard(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: achievement.unlocked
                      ? AppColors.primary
                      : AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  achievement.unlocked ? Icons.shield : Icons.hourglass_bottom,
                  color: achievement.unlocked ? Colors.white : AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(achievement.title, style: AppTextStyles.cardTitle, maxLines: 1),
                    Text(achievement.subtitle, style: AppTextStyles.caption, maxLines: 2),
                    if (!achievement.unlocked)
                      Text(
                        '${achievement.progress}/${achievement.total}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
