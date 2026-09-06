import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/content_models.dart';
import '../../data/repositories/content_repository.dart';

/// Просмотр теста родителем: описание и список вопросов, без прохождения.
class ViewTestSheet extends StatefulWidget {
  const ViewTestSheet({
    super.key,
    required this.test,
    required this.onSend,
  });

  final ContentTest test;
  final VoidCallback onSend;

  @override
  State<ViewTestSheet> createState() => _ViewTestSheetState();
}

class _ViewTestSheetState extends State<ViewTestSheet> {
  bool _loading = true;
  String? _error;
  ContentTestDetail? _detail;

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
      final detail = await context.read<ContentRepository>().getTest(widget.test.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
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
              const Expanded(
                child: Text('Просмотр теста', style: AppTextStyles.sectionTitle),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(widget.test.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          Text(
            widget.test.description ??
                'Количество вопросов: ${widget.test.questionCount}',
            style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
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
          else if (_detail != null) ...[
            Text(
              'Вопросы (${_detail!.questions.length})',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHeading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _detail!.questions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final q = _detail!.questions[i];
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.screenBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${i + 1}. ${q.text}',
                      style: AppTextStyles.body.copyWith(fontSize: 14),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Отправить',
            expand: true,
            onPressed: () {
              Navigator.of(context).pop();
              widget.onSend();
            },
          ),
        ],
      ),
    );
  }
}
