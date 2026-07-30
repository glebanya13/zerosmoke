import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_args.dart';
import '../../data/app_state.dart';
import '../../data/models/content_models.dart';
import '../../data/repositories/content_repository.dart';
import 'new_tests_sheet.dart';
import 'start_test_sheet.dart';

/// Тесты (ребёнок): категории «На прохождении» и «Мой выбор»,
/// градиентные плитки 162×142 из фигмы.
class TestsListScreen extends StatefulWidget {
  const TestsListScreen({super.key});

  @override
  State<TestsListScreen> createState() => _TestsListScreenState();
}

class _TestsListScreenState extends State<TestsListScreen> {
  static const _gradients = [
    AppColors.nodeBlueGradient,
    AppColors.nodeGreenGradient,
    AppColors.nodeOrangeGradient,
  ];

  bool _loading = true;
  String? _error;
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
        content.getTests(),
        content.getAssignments(),
      ]);
      if (!mounted) return;
      setState(() {
        _tests = results[0] as List<ContentTest>;
        _assignments = results[1] as List<TestAssignment>;
        _loading = false;
      });
      // Pending assignments already surface via the mail badge; remote push
      // is sent by the API when a parent assigns a test.
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
    final topPad = MediaQuery.of(context).padding.top;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: AppTextStyles.body),
            TextButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }

    final inProgress = _tests.where((t) => t.progress.answeredCount > 0 && !t.progress.completed).toList();
    final myChoice = _tests.where((t) => t.progress.answeredCount == 0 || t.progress.completed).toList();
    final badgeCount = _assignments.where((a) => a.isIncomplete).length;

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, topPad + 8, AppSpacing.md, 130),
      children: [
        SizedBox(
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Text('Тесты', style: AppTextStyles.pageTitle),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => NewTestsSheet(assignments: _assignments),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.mail_outline, size: 28, color: AppColors.textPrimary),
                      if (badgeCount > 0)
                        Positioned(
                          right: -4,
                          bottom: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              badgeCount > 9 ? '9+' : '$badgeCount',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.interFamily,
                                fontSize: 10,
                                height: 1,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('На прохождении', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 16),
        SizedBox(
          height: 142,
          child: inProgress.isEmpty
              ? const Center(child: Text('Пока нет начатых тестов', style: AppTextStyles.caption))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: inProgress.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _TestTile(
                    test: inProgress[i],
                    gradient: _gradients[i % _gradients.length],
                    onTap: () => _openStartSheet(context, inProgress[i], isContinue: true),
                  ),
                ),
        ),
        const SizedBox(height: 28),
        const Text('Мой выбор', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 16),
        SizedBox(
          height: 142,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: myChoice.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _MyChoiceTile(
              test: myChoice[i],
              onTap: () => _openStartSheet(context, myChoice[i]),
            ),
          ),
        ),
      ],
    );
  }

  void _openStartSheet(BuildContext context, ContentTest test, {bool isContinue = false}) {
    final paid = context.read<AppState>().hasSubscription;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StartTestSheet(
        isContinue: isContinue,
        testTitle: test.title,
        onStart: () {
          Navigator.of(context).pop();
          context.push(AppRoutes.testFlow, extra: TestFlowArgs(testId: test.id, paid: paid));
        },
      ),
    );
  }
}

class _TestTile extends StatelessWidget {
  const _TestTile({required this.test, required this.gradient, required this.onTap});

  final ContentTest test;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = test.progress.totalCount == 0 ? 1 : test.progress.totalCount;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 162,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/images/icons/icon_security_check.png',
                width: 36,
                height: 36,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              test.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTextStyles.interFamily,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '${test.progress.answeredCount}/${test.progress.totalCount}',
                style: const TextStyle(
                  fontFamily: AppTextStyles.interFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: test.progress.answeredCount / total,
                backgroundColor: const Color(0xFFE3E8EF),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyChoiceTile extends StatelessWidget {
  const _MyChoiceTile({required this.test, required this.onTap});

  final ContentTest test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 162,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: AppColors.nodePurpleGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Image.asset(
                  'assets/images/icons/icon_bed.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  test.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.interFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
