import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_args.dart';
import '../../core/widgets/top_stats_bar.dart';
import '../../data/app_state.dart';
import '../../data/models/content_models.dart';
import '../../data/models/rating_models.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/rating_repository.dart';
import '../quit/quit_progress_card.dart';
import 'home_path_tutorial.dart';

/// Главная (ребёнок/взрослый): карта-тропинка.
/// Небо и CTA зафиксированы.
/// Продолжение — бесшовный повторяющийся фрагмент home_path_tile.png,
/// вырезанный из исходника (см. _tileImageHeight), а не отдельный
/// склеенный ассет — так на стыках нет шва и масштаб не плывёт.
class HomeChildScreen extends StatefulWidget {
  const HomeChildScreen({super.key});

  @override
  State<HomeChildScreen> createState() => _HomeChildScreenState();
}

class _HomeChildScreenState extends State<HomeChildScreen> {
  static const double _designWidth = 393;
  static const double _baseHeight = 852;
  static const double _continuationTop = 720;
  /// Бесшовный повторяющийся фрагмент тропинки: вырезан из home_path_background.png
  /// (строки 413–650 исходника, 1024×1024, подобраны так, чтобы верх и низ
  /// совпадали по ширине/положению тропинки и не задевали ни одного дерева) —
  /// сам с собой стыкуется без шва. Высота переведена в те же design-координаты,
  /// что и база (scale 852/1024), чтобы масштаб тропинки не менялся на стыке.
  static const double _tileImageHeight = 237.0;
  static const double _tileDesignHeight = _tileImageHeight * _baseHeight / 1024;
  static const double _nodeStep = 175;
  static const double _extraNodesStartTop = 720;
  static const double _mentorBtnHeight = 56;

  static const _baseLayouts = [
    (
      left: 196.0,
      top: 244.0,
      gradient: AppColors.nodeBlueGradient,
      icon: 'assets/images/icons/icon_security_check.png',
    ),
    (
      left: 33.0,
      top: 395.0,
      gradient: AppColors.nodeGreenGradient,
      icon: 'assets/images/icons/icon_brain.png',
    ),
    (
      left: 254.0,
      top: 485.0,
      gradient: AppColors.nodePurpleGradient,
      icon: 'assets/images/icons/icon_moon_sleep.png',
    ),
  ];

  static const _nodeIcons = [
    'assets/images/icons/icon_security_check.png',
    'assets/images/icons/icon_brain.png',
    'assets/images/icons/icon_moon_sleep.png',
    'assets/images/icons/icon_star_broken.png',
  ];

  static const _nodeGradients = [
    AppColors.nodeBlueGradient,
    AppColors.nodeGreenGradient,
    AppColors.nodePurpleGradient,
    AppColors.nodeOrangeGradient,
  ];

  bool _loading = true;
  String? _error;
  RatingMe? _me;
  List<ContentTest> _tests = [];
  int _seenEpoch = -1;
  bool _showTutorial = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _maybeShowTutorial();
  }

  Future<void> _maybeShowTutorial() async {
    if (await HomePathTutorial.shouldShow()) {
      if (mounted) setState(() => _showTutorial = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        context.read<RatingRepository>().getMe(),
        context.read<ContentRepository>().getTests(),
      ]);
      if (!mounted) return;
      setState(() {
        _me = results[0] as RatingMe;
        _tests = results[1] as List<ContentTest>;
        _loading = false;
        _error = null;
        _seenEpoch = context.read<AppState>().contentEpoch;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent) {
          _error = e.message;
          _loading = false;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent) {
          _error = e.toString();
          _loading = false;
        }
      });
    }
  }

  void _openTest(ContentTest test) {
    final paid = context.read<AppState>().hasSubscription;
    context.push(AppRoutes.testFlow, extra: TestFlowArgs(testId: test.id, paid: paid));
  }

  void _openRecommendedTest() {
    final topics = groupTestsByTopic(_tests);
    if (topics.isEmpty) return;
    final next = topics.firstWhere((topic) => !topic.completed, orElse: () => topics.first);
    _openTest(next.nextTest);
  }

  List<({double left, double top, Gradient gradient, String icon})> _layoutsFor(int count) {
    return List.generate(count, (i) {
      if (i < _baseLayouts.length) return _baseLayouts[i];
      final extraIndex = i - _baseLayouts.length;
      final isLeft = i.isOdd;
      return (
        left: isLeft ? 33.0 : 220.0,
        top: _extraNodesStartTop + extraIndex * _nodeStep,
        gradient: _nodeGradients[i % _nodeGradients.length],
        icon: _nodeIcons[i % _nodeIcons.length],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final epoch = context.watch<AppState>().contentEpoch;
    if (_seenEpoch >= 0 && epoch != _seenEpoch && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(silent: true);
      });
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
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

    final isAdult = context.watch<AppState>().isAdult;
    final topSafe = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topSafe),
            if (isAdult) const QuitProgressCard(),
            Expanded(
              child: LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        // На планшете ограничиваем ширину карты, чтобы узлы не были огромными.
        final maxMapWidth = isTablet ? 520.0 : constraints.maxWidth;
        final scale = maxMapWidth / _designWidth;
        // Горизонтальный отступ для центрирования карты на iPad.
        final hInset = (constraints.maxWidth - maxMapWidth) / 2;

        final topics = groupTestsByTopic(_tests);
        final mapNodes = topics;
        final layouts = _layoutsFor(mapNodes.length);
        final firstIncomplete = mapNodes.indexWhere((topic) => !topic.completed);
        final unlockIndex = firstIncomplete < 0 ? mapNodes.length : firstIncomplete;

        final needsContinuation = mapNodes.length > _baseLayouts.length;
        final continuationTop = _continuationTop;
        final lastNodeBottom =
            layouts.isEmpty ? _baseHeight : layouts.last.top + 130;
        final totalHeight = needsContinuation
            ? math.max(_baseHeight, lastNodeBottom + _mentorBtnHeight + 12)
            : _baseHeight;
        final continuationHeight = needsContinuation
            ? math.max(0.0, totalHeight - continuationTop)
            : 0.0;
        final tileCount = needsContinuation
            ? (continuationHeight / _tileDesignHeight).ceil()
            : 0;

        final mentorBottom = MediaQuery.of(context).padding.bottom + 110;
        final statsTop = 8.0;
        final dpr = MediaQuery.of(context).devicePixelRatio;
        final pathCacheWidth = (constraints.maxWidth * dpr).round();

        final statsScale = isTablet ? 1.3 : 1.0;

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/illustrations/sky_clouds_background.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
                cacheWidth: pathCacheWidth,
              ),
            ),
            SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(bottom: mentorBottom + 64),
              child: SizedBox(
                width: constraints.maxWidth,
                height: totalHeight * scale,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Фоновые изображения тропинки — на всю ширину экрана.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: _baseHeight * scale,
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (bounds) {
                          final fadeStart = (continuationTop * scale) / bounds.height;
                          final fadeEnd = math.min(
                            1.0,
                            fadeStart + (56 * scale) / bounds.height,
                          );
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: const [
                              Color(0xFFFFFFFF),
                              Color(0xFFFFFFFF),
                              Color(0x00FFFFFF),
                            ],
                            stops: [
                              0.0,
                              fadeStart.clamp(0.5, 0.95),
                              fadeEnd.clamp(0.55, 1.0),
                            ],
                          ).createShader(bounds);
                        },
                        child: Image.asset(
                          'assets/images/illustrations/home_path_background.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          filterQuality: FilterQuality.high,
                          cacheWidth: pathCacheWidth,
                        ),
                      ),
                    ),
                    if (needsContinuation)
                      for (int i = 0; i < tileCount; i++)
                        Positioned(
                          top: (continuationTop + i * _tileDesignHeight) * scale,
                          left: 0,
                          right: 0,
                          height: _tileDesignHeight * scale,
                          child: ClipRect(
                            child: Image.asset(
                              'assets/images/illustrations/home_path_tile.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              filterQuality: FilterQuality.high,
                              cacheWidth: pathCacheWidth,
                            ),
                          ),
                        ),
                    // Узлы карты — центрированы с учётом hInset.
                    for (int i = 0; i < mapNodes.length; i++)
                      _node(
                        scale: scale,
                        left: layouts[i].left,
                        top: layouts[i].top,
                        hInset: hInset,
                        gradient: layouts[i].gradient,
                        iconAsset: layouts[i].icon,
                        label: mapNodes[i].title,
                        locked: i > unlockIndex,
                        stars: mapNodes[i].completed ? 3 : 0,
                        onTap: i > unlockIndex ? null : () => _openTest(mapNodes[i].nextTest),
                      ),
                  ],
                ),
              ),
            ),
            // Верхний рейтинг закреплён: всегда кликабелен, учитывает safe area.
            if (_me != null)
              Positioned(
                left: 16,
                right: 16,
                top: statsTop,
                child: TopStatsBar(
                  name: _me!.name,
                  percent: _me!.percent,
                  stars: _me!.stars,
                  coins: _me!.coins,
                  points: _me!.points,
                  pointsTotal: _me!.total,
                  rank: _me!.place,
                  avatarIndex: _me!.avatarIndex,
                  scale: statsScale,
                  onRatingTap: () => context.go('${AppRoutes.root}?tab=2'),
                  onTrophyTap: () => context.push(AppRoutes.rewards),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: mentorBottom,
              child: Center(
                child: _MentorRecommendationButton(
                  scale: scale,
                  onTap: _openRecommendedTest,
                ),
              ),
            ),
          ],
        );
      },
    ),
            ),
          ],
        ),
        if (_showTutorial)
          Positioned.fill(
            child: HomePathTutorial(
              onFinished: () => setState(() => _showTutorial = false),
            ),
          ),
      ],
    );
  }

  Widget _node({
    required double scale,
    required double left,
    required double top,
    required double hInset,
    required Gradient gradient,
    required String iconAsset,
    required String label,
    int stars = 0,
    bool locked = false,
    VoidCallback? onTap,
  }) {
    return Positioned(
      left: left * scale + hInset,
      top: top * scale,
      width: 100 * scale,
      child: GestureDetector(
        onTap: locked ? null : onTap,
        child: Column(
          children: [
            Opacity(
              opacity: locked ? 0.7 : 1.0,
              child: Container(
                width: 100 * scale,
                height: 100 * scale,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(30 * scale),
                  border: Border.all(color: Colors.white, width: 3 * scale),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      iconAsset,
                      width: 34 * scale,
                      height: 34 * scale,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4 * scale),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontFamily: AppTextStyles.interFamily,
                          fontWeight: FontWeight.w500,
                          fontSize: 12.5 * scale,
                          height: 16 / 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5 * scale),
            if (locked)
              Image.asset(
                'assets/images/icons/icon_lock.png',
                width: 22 * scale,
                height: 22 * scale,
              )
            else if (stars > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(3, (i) {
                  final bool big = i == 1;
                  final double size = (big ? 20 : 16) * scale;
                  return Opacity(
                    opacity: i < stars ? 1 : 0.35,
                    child: Image.asset(
                      'assets/images/icons/icon_star_filled.png',
                      width: size,
                      height: size,
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}

class _MentorRecommendationButton extends StatelessWidget {
  const _MentorRecommendationButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 6,
      shadowColor: const Color(0x44000000),
      borderRadius: BorderRadius.circular(30 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30 * scale),
        child: Ink(
          width: 176 * scale,
          height: 56 * scale,
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 10 * scale,
          ),
          decoration: BoxDecoration(
            gradient: AppColors.nodeOrangeGradient,
            borderRadius: BorderRadius.circular(30 * scale),
            border: Border.all(color: Colors.white, width: 3 * scale),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/icons/icon_star_broken.png',
                width: 32 * scale,
                height: 32 * scale,
                color: Colors.white,
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  'Рекомендация от наставника',
                  style: TextStyle(
                    fontFamily: AppTextStyles.interFamily,
                    fontWeight: FontWeight.w500,
                    fontSize: 13 * scale,
                    height: 16 / 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
