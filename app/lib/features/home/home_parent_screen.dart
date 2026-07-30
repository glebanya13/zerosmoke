import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_args.dart';
import '../../core/widgets/app_avatar.dart';
import '../../data/app_state.dart';
import '../../data/models/content_models.dart';
import '../../data/models/rating_models.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/rating_repository.dart';
import '../tips/tip_colors.dart';
import 'send_test_sheet.dart';

/// Главная (Родитель): градиентный фон, карусель прогресса детей,
/// новые тесты, рекомендации и советы — 1:1 с фигмой.
class HomeParentScreen extends StatefulWidget {
  const HomeParentScreen({super.key});

  @override
  State<HomeParentScreen> createState() => _HomeParentScreenState();
}

class _HomeParentScreenState extends State<HomeParentScreen> {
  bool _loading = true;
  String? _error;
  List<LeaderboardEntry> _children = [];
  List<GuideSection> _tips = [];
  List<ContentTest> _tests = [];
  List<TestAssignment> _assignments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final content = context.read<ContentRepository>();
      final results = await Future.wait([
        context.read<RatingRepository>().getLeaderboard(),
        content.getGuide(),
        content.getTests(),
        content.getAssignments(),
      ]);
      if (!mounted) return;
      setState(() {
        _children = results[0] as List<LeaderboardEntry>;
        _tips = (results[1] as GuideModel).sections;
        _tests = results[2] as List<ContentTest>;
        _assignments = results[3] as List<TestAssignment>;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openSendSheet(ContentTest test) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SendTestSheet(test: test),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final parent = context.watch<AppState>().parentUser;
    final newTests = _tests.take(2).toList();
    final incomplete = _assignments.where((a) => a.isIncomplete).toList();
    final recommendationTitle = incomplete.isNotEmpty
        ? incomplete.first.testTitle
        : (_tips.isNotEmpty ? _tips.first.title : 'Тема рекомендации');
    final recommendationSubtitle = incomplete.isNotEmpty
        ? (incomplete.first.message ?? 'Пройти назначенный тест')
        : 'Повторить тему и ответить\nна вопросы';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: AppTextStyles.body, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/illustrations/sky_clouds_background.png',
            fit: BoxFit.cover,
          ),
        ),
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(0, topPad + 8, 0, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppAvatar(index: parent.avatarIndex, size: 60),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        parent.name.isEmpty ? 'Привет!' : 'Привет, ${parent.name}!',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 24 / 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
                      onSelected: (value) {
                        switch (value) {
                          case 'settings':
                            context.push(AppRoutes.settings);
                          case 'profile':
                            context.go('${AppRoutes.root}?tab=3');
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'settings', child: Text('Настройки')),
                        PopupMenuItem(value: 'profile', child: Text('Профиль')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_children.isNotEmpty)
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: _children.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final child = _children[i];
                      return _ChildProgressCard(
                        name: 'Прогресс ${child.name}',
                        percent: child.percent,
                        points: child.points,
                        total: child.total,
                        avatarIndex: child.avatarIndex,
                        onView: () => context.go('${AppRoutes.root}?tab=2'),
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Новые тесты', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    if (newTests.isEmpty)
                      const Text('Пока нет тестов', style: AppTextStyles.caption)
                    else
                      for (final test in newTests) ...[
                        _NewTestCard(
                          title: test.title,
                          description: test.description ??
                              'Количество вопросов: ${test.questionCount}',
                          onSend: () => _openSendSheet(test),
                        ),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 12),
                    const Text('Ваши рекомендации', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    _RecommendationCard(
                      title: recommendationTitle,
                      subtitle: recommendationSubtitle,
                    ),
                    const SizedBox(height: 24),
                    const Text('Советы', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    for (int i = 0; i < _tips.length; i++) ...[
                      _TipRowCard(
                        section: _tips[i],
                        colorIndex: i % tipColors.length,
                        onTap: () => context.push(
                          AppRoutes.tipDetail,
                          extra: TipDetailArgs(
                            section: _tips[i],
                            colorIndex: i % tipColors.length,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChildProgressCard extends StatelessWidget {
  const _ChildProgressCard({
    required this.name,
    required this.percent,
    required this.points,
    required this.total,
    required this.avatarIndex,
    required this.onView,
  });

  final String name;
  final int percent;
  final int points;
  final int total;
  final int avatarIndex;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppColors.progressCardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppAvatar(index: avatarIndex, percent: percent, size: 60),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(height: 20 / 16),
                      ),
                    ),
                    Text(
                      '$points/$total',
                      style: AppTextStyles.points.copyWith(height: 1.0),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        '$percent% пройдено',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 16 / 12,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onView,
                      child: Row(
                        children: [
                          Text(
                            'Смотреть',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textHeading,
                              height: 16 / 12,
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 14, color: AppColors.textHeading),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewTestCard extends StatelessWidget {
  const _NewTestCard({
    required this.title,
    required this.description,
    required this.onSend,
  });

  final String title;
  final String description;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.textHeading,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Отправить',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.nodeOrangeGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/icons/icon_star_broken.png',
              width: 36,
              height: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12,
                    height: 16 / 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryDeep),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Активна',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                color: AppColors.textHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRowCard extends StatelessWidget {
  const _TipRowCard({required this.section, required this.colorIndex, required this.onTap});

  final GuideSection section;
  final int colorIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: tipColors[colorIndex],
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: AppTextStyles.cardTitle, maxLines: 2),
                  const SizedBox(height: 6),
                  Text(
                    section.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  const MoreChip(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoreChip extends StatelessWidget {
  const MoreChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textHeading),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Подробнее',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 12,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right, size: 14, color: AppColors.textHeading),
        ],
      ),
    );
  }
}
