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
                          points: _me!.points,
                          pointsTotal: _me!.total,
                          rank: _me!.place,
                          avatarIndex: _me!.avatarIndex,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Text('Полученные', style: AppTextStyles.sectionTitle),
                        const SizedBox(height: AppSpacing.sm),
                        if (unlocked.isEmpty)
                          Text('Пока нет полученных наград', style: AppTextStyles.caption)
                        else
                          _rewardGrid(unlocked),
                        const SizedBox(height: AppSpacing.lg),
                        const Text('В процессе', style: AppTextStyles.sectionTitle),
                        const SizedBox(height: AppSpacing.sm),
                        if (inProgress.isEmpty)
                          Text('Все награды уже получены', style: AppTextStyles.caption)
                        else
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final achievement in achievements)
              SizedBox(
                width: width,
                child: _AchievementCard(achievement: achievement),
              ),
          ],
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final AchievementModel achievement;

  @override
  Widget build(BuildContext context) {
    final progress = achievement.total <= 0
        ? 0.0
        : (achievement.progress / achievement.total).clamp(0.0, 1.0);

    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: achievement.unlocked
                      ? AppColors.primary
                      : AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  achievement.unlocked ? Icons.shield : Icons.hourglass_bottom,
                  size: 20,
                  color: achievement.unlocked ? Colors.white : AppColors.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  achievement.title,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 14, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            achievement.subtitle,
            style: AppTextStyles.caption.copyWith(height: 1.25),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (!achievement.unlocked) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.textHeading),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${achievement.progress}/${achievement.total}',
              style: AppTextStyles.caption.copyWith(color: AppColors.primaryDark),
            ),
          ],
        ],
      ),
    );
  }
}
