import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/app_state.dart';
import '../../data/models/rating_models.dart';
import '../../data/repositories/rating_repository.dart';

/// Статистика по разделам с главной: раздел → тестовые вопросы.
/// Без подписки — состав раздела; с подпиской — ещё и статус ответов.
class RatingStatisticsScreen extends StatefulWidget {
  const RatingStatisticsScreen({super.key});

  @override
  State<RatingStatisticsScreen> createState() => _RatingStatisticsScreenState();
}

class _RatingStatisticsScreenState extends State<RatingStatisticsScreen> {
  bool _loading = true;
  String? _error;
  List<RatingSectionStat> _sections = [];
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await context.read<RatingRepository>().getMe();
      if (!mounted) return;
      setState(() {
        _sections = me.sections;
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

  void _toggle(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSub = context.watch<AppState>().hasSubscription;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: AppTextStyles.body))
          : ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                MediaQuery.of(context).padding.top + 16,
                AppSpacing.md,
                AppSpacing.md,
              ),
              children: [
                const ScreenHeader(title: 'Статистика'),
                const SizedBox(height: 20),
                if (!hasSub) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Подписка',
                          style: AppTextStyles.headerTitle.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Сейчас виден состав раздела: тестовые вопросы. '
                          'С подпиской откроется подробный разбор ответов.',
                          style: AppTextStyles.bodySecondary.copyWith(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Оформить подписку',
                          expand: true,
                          onPressed: () => context.push(AppRoutes.subscription),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _sections.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Пока нет данных по разделам',
                            style: AppTextStyles.bodySecondary,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < _sections.length; i++) ...[
                              if (i > 0)
                                const Divider(height: 17, thickness: 1, color: AppColors.divider),
                              _SectionStatTile(
                                section: _sections[i],
                                expanded: _expanded.contains(_sections[i].id),
                                showAnswerStatus: hasSub,
                                onToggle: () => _toggle(_sections[i].id),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}

class _SectionStatTile extends StatelessWidget {
  const _SectionStatTile({
    required this.section,
    required this.expanded,
    required this.showAnswerStatus,
    required this.onToggle,
  });

  final RatingSectionStat section;
  final bool expanded;
  final bool showAnswerStatus;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final byTest = <String, List<RatingSectionQuestionStat>>{};
    for (final q in section.questions) {
      byTest.putIfAbsent(q.testTitle, () => []).add(q);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: section.questions.isEmpty ? null : onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.interFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${section.progress}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dangerLight,
                        ),
                      ),
                      TextSpan(
                        text: '/${section.total}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHeading,
                        ),
                      ),
                    ],
                  ),
                ),
                if (section.questions.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textHeading,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (expanded && section.questions.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final entry in byTest.entries) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6, top: 4),
              child: Text(
                entry.key,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHeading,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (int i = 0; i < entry.value.length; i++)
              _QuestionRow(
                index: i + 1,
                question: entry.value[i],
                showAnswerStatus: showAnswerStatus,
              ),
          ],
        ],
      ],
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.index,
    required this.question,
    required this.showAnswerStatus,
  });

  final int index;
  final RatingSectionQuestionStat question;
  final bool showAnswerStatus;

  @override
  Widget build(BuildContext context) {
    Widget? status;
    if (showAnswerStatus) {
      if (question.correct == true) {
        status = const Icon(Icons.check_circle, size: 18, color: AppColors.success);
      } else if (question.correct == false) {
        status = const Icon(Icons.cancel, size: 18, color: AppColors.dangerLight);
      } else {
        status = const Icon(Icons.radio_button_unchecked, size: 18, color: AppColors.textMuted);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '$index. ${question.text}',
              style: AppTextStyles.bodySecondary.copyWith(
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (status != null) ...[
            const SizedBox(width: 8),
            status,
          ],
        ],
      ),
    );
  }
}
