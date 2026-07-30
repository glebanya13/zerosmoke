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

/// Главная (ребёнок/взрослый): карта-тропинка. Полноэкранная иллюстрация,
/// поверх — стат-бар и градиентные карточки-узлы, координаты 1:1 с фигмой
/// (эталонный канвас 393×852).
class HomeChildScreen extends StatefulWidget {
  const HomeChildScreen({super.key});

  @override
  State<HomeChildScreen> createState() => _HomeChildScreenState();
}

class _HomeChildScreenState extends State<HomeChildScreen> {
  static const double _designWidth = 393;
  static const double _designHeight = 852;

  static const _nodeLayouts = [
    (left: 196.0, top: 244.0, gradient: AppColors.nodeBlueGradient, icon: 'assets/images/icons/icon_security_check.png'),
    (left: 33.0, top: 395.0, gradient: AppColors.nodeGreenGradient, icon: 'assets/images/icons/icon_brain.png'),
    (left: 254.0, top: 485.0, gradient: AppColors.nodePurpleGradient, icon: 'assets/images/icons/icon_moon_sleep.png'),
  ];

  bool _loading = true;
  String? _error;
  RatingMe? _me;
  List<ContentTest> _tests = [];

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
      final results = await Future.wait([
        context.read<RatingRepository>().getMe(),
        context.read<ContentRepository>().getTests(),
      ]);
      if (!mounted) return;
      setState(() {
        _me = results[0] as RatingMe;
        _tests = results[1] as List<ContentTest>;
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

  void _openTest(ContentTest test) {
    final paid = context.read<AppState>().hasSubscription;
    context.push(AppRoutes.testFlow, extra: TestFlowArgs(testId: test.id, paid: paid));
  }

  /// First incomplete index — everything after it is locked (sequential unlock).
  int get _firstIncompleteIndex {
    final idx = _tests.indexWhere((t) => !t.progress.completed);
    return idx < 0 ? _tests.length : idx;
  }

  @override
  Widget build(BuildContext context) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / _designWidth;
        final incomplete = _tests.where((t) => !t.progress.completed).toList();
        final mapNodes = (incomplete.isNotEmpty ? incomplete : _tests).take(3).toList();
        final firstIncomplete = _firstIncompleteIndex;

        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: constraints.maxWidth,
                height: _designHeight * scale,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/illustrations/sky_clouds_background.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/illustrations/home_path_background.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (_me != null)
                      Positioned(
                        left: 16 * scale,
                        top: 64 * scale,
                        width: 361 * scale,
                        child: TopStatsBar(
                          name: _me!.name,
                          percent: _me!.percent,
                          stars: _me!.stars,
                          coins: _me!.coins,
                          points: _me!.points,
                          pointsTotal: _me!.total,
                          onTrophyTap: () => context.push(AppRoutes.rewards),
                        ),
                      ),
                    for (int i = 0; i < mapNodes.length; i++)
                      _node(
                        scale: scale,
                        left: _nodeLayouts[i].left,
                        top: _nodeLayouts[i].top,
                        gradient: _nodeLayouts[i].gradient,
                        iconAsset: _nodeLayouts[i].icon,
                        label: mapNodes[i].title,
                        locked: i > firstIncomplete,
                        stars: mapNodes[i].progress.completed ? 3 : 0,
                        onTap: i > firstIncomplete ? null : () => _openTest(mapNodes[i]),
                      ),
                    Positioned(
                      left: 111 * scale,
                      top: 652 * scale,
                      width: 176 * scale,
                      height: 56 * scale,
                      child: GestureDetector(
                        onTap: () {
                          if (_tests.isEmpty) return;
                          final next = _tests.firstWhere(
                            (t) => !t.progress.completed,
                            orElse: () => _tests.first,
                          );
                          _openTest(next);
                        },
                        child: Container(
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

  Widget _node({
    required double scale,
    required double left,
    required double top,
    required Gradient gradient,
    required String iconAsset,
    required String label,
    int stars = 0,
    bool locked = false,
    VoidCallback? onTap,
  }) {
    return Positioned(
      left: left * scale,
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
