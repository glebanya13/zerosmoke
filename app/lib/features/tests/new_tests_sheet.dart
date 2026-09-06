import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_args.dart';
import '../../core/widgets/app_button.dart';
import '../../data/app_state.dart';
import '../../data/models/content_models.dart';
import '../../data/repositories/content_repository.dart';

/// "Новые тесты" modal shown from the child Тесты screen mail icon.
class NewTestsSheet extends StatefulWidget {
  const NewTestsSheet({super.key, this.assignments});

  final List<TestAssignment>? assignments;

  @override
  State<NewTestsSheet> createState() => _NewTestsSheetState();
}

class _NewTestsSheetState extends State<NewTestsSheet> {
  bool _loading = true;
  String? _error;
  List<TestAssignment> _assignments = [];
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    if (widget.assignments != null) {
      _assignments = widget.assignments!;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<ContentRepository>().getAssignments();
      if (!mounted) return;
      setState(() {
        _assignments = list;
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

  void _startSelected() {
    if (_assignments.isEmpty) return;
    final assignment = _assignments[_selected.clamp(0, _assignments.length - 1)];
    final paid = context.read<AppState>().hasSubscription;
    Navigator.of(context).pop();
    context.push(
      AppRoutes.testFlow,
      extra: TestFlowArgs(testId: assignment.testId, paid: paid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _loading
        ? 'Новые тесты'
        : '${_assignments.length} ${_assignmentWord(_assignments.length)}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline, color: AppColors.primaryDark),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(title, style: AppTextStyles.sectionTitle),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(_error!, style: AppTextStyles.body),
                  TextButton(onPressed: _load, child: const Text('Повторить')),
                ],
              ),
            )
          else if (_assignments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Нет новых тестов', style: AppTextStyles.bodySecondary),
            )
          else ...[
            for (int i = 0; i < _assignments.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: i == _selected
                          ? AppColors.dangerLight.withValues(alpha: 0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.danger),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _assignments[i].testTitle,
                            style: AppTextStyles.cardTitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _assignments[_selected.clamp(0, _assignments.length - 1)].message ??
                  'Пройди этот тест как можно скорее!',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'На прохождение', onPressed: _startSelected),
          ],
        ],
      ),
    );
  }

  String _assignmentWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) return 'новый тест';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'новых теста';
    return 'новых тестов';
  }
}
