import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/top_stats_bar.dart';
import '../../data/app_state.dart';
import '../../data/models/rating_models.dart';
import '../../data/repositories/rating_repository.dart';

/// Рейтинг: leaderboard, shared by child/parent, free/paid via AppState.
class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  bool _loading = true;
  String? _error;
  RatingMe? _me;
  List<LeaderboardEntry> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<RatingRepository>();
    try {
      final results = await Future.wait([repo.getMe(), repo.getLeaderboard()]);
      if (!mounted) return;
      setState(() {
        _me = results[0] as RatingMe;
        _leaderboard = results[1] as List<LeaderboardEntry>;
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
    final isParent = context.watch<AppState>().isParent;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.ratingGradient),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.white)),
                  TextButton(onPressed: _load, child: const Text('Повторить')),
                ],
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                MediaQuery.of(context).padding.top + 8,
                AppSpacing.md,
                130,
              ),
              children: [
                if (isParent)
                  Column(
                    children: [
                      for (final child in _leaderboard)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _LeaderRow(
                            name: child.name,
                            percent: child.percent,
                            stars: child.stars,
                            points: child.points,
                            total: child.total,
                            coins: child.coins,
                            avatarIndex: child.avatarIndex,
                            rewardsCount: child.rewardsCount,
                            onTap: () => context.push(AppRoutes.ratingStatistics),
                          ),
                        ),
                    ],
                  )
                else ...[
                  _ChildRatingHeader(
                    me: _me!,
                    onTrophyTap: () => context.push(AppRoutes.rewards),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Лига здоровья',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final entry in _leaderboard)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _LeaderRow(
                        name: entry.name,
                        percent: entry.percent,
                        stars: entry.stars,
                        points: entry.points,
                        total: entry.total,
                        coins: entry.coins,
                        avatarIndex: entry.avatarIndex,
                        place: entry.place,
                        highlighted: entry.place == 1,
                        onTap: () => context.push(AppRoutes.ratingStatistics),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    style: AppButtonStyle.invite,
                    expand: true,
                    label: 'Пригласить друзей',
                    onPressed: () => context.push(AppRoutes.inviteFriend),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Шапка рейтинга ребёнка: карточка 361×100 r=30, аватар 80,
/// имя + звёзды + очки/монеты, справа кубок и «N наград».
class _ChildRatingHeader extends StatelessWidget {
  const _ChildRatingHeader({required this.me, this.onTrophyTap});

  final RatingMe me;
  final VoidCallback? onTrophyTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          AppAvatar(index: me.avatarIndex, percent: me.percent, size: 80),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                StarsRow(count: me.stars, size: 18),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${me.points}/${me.total}', style: AppTextStyles.points),
              CoinsRow(coins: me.coins, iconSize: 22),
            ],
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onTrophyTap,
            child: SizedBox(
              width: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.goldStroke, size: 32),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${me.rewardsCount} наград',
                      maxLines: 1,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHeading,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ряд лидерборда из фигмы: 361×80 r=20. У ребёнка в глобальном рейтинге —
/// золотая рамка и жёлтый круг ранга у №1, у остальных просто номер.
/// У родителя (свои дети) вместо ранга — кубок и «N наград».
class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.name,
    required this.percent,
    required this.stars,
    required this.points,
    required this.total,
    required this.coins,
    required this.avatarIndex,
    this.place,
    this.rewardsCount,
    this.highlighted = false,
    this.onTap,
  });

  final String name;
  final int percent;
  final int stars;
  final int points;
  final int total;
  final int coins;
  final int avatarIndex;
  final int? place;
  final int? rewardsCount;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: highlighted ? Border.all(color: AppColors.goldStroke) : null,
        ),
        child: Row(
          children: [
            AppAvatar(index: avatarIndex, percent: percent, size: 60),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.interName),
                  const SizedBox(height: 4),
                  StarsRow(count: stars, size: 20),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$points/$total', style: AppTextStyles.points),
                CoinsRow(coins: coins),
              ],
            ),
            if (place != null) ...[
              const SizedBox(width: 12),
              if (highlighted)
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.rankYellow,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$place',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.interFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 36,
                  child: Center(
                    child: Text(
                      '$place',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.interFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ] else if (rewardsCount != null) ...[
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.goldStroke, size: 32),
                  Text(
                    '$rewardsCount наград',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHeading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
