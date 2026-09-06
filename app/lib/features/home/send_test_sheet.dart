import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/backend_user.dart';
import '../../data/models/content_models.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/links_repository.dart';

/// "Отправить новый тест" modal shown from the parent home screen.
class SendTestSheet extends StatefulWidget {
  const SendTestSheet({super.key, required this.test});

  final ContentTest test;

  @override
  State<SendTestSheet> createState() => _SendTestSheetState();
}

class _SendTestSheetState extends State<SendTestSheet> {
  bool _loading = true;
  String? _error;
  List<BackendUser> _children = [];
  int? _selectedChild;
  bool _sending = false;

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
      final children = await context.read<LinksRepository>().getChildren();
      if (!mounted) return;
      setState(() {
        _children = children;
        _selectedChild = children.isEmpty ? null : 0;
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

  Future<void> _send() async {
    if (_selectedChild == null || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<ContentRepository>().assignTest(
        testId: widget.test.id,
        assignedToId: _children[_selectedChild!].id,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тест отправлен')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Expanded(
                child: Text('Отправить новый тест', style: AppTextStyles.sectionTitle),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.dangerLight.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.danger),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(widget.test.title, style: AppTextStyles.cardTitle),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
          else if (_children.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Нет связанных детей', style: AppTextStyles.bodySecondary),
            )
          else
            for (int i = 0; i < _children.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedChild = i),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: _selectedChild == i ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(_children[i].name, style: AppTextStyles.cardTitle),
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: _sending ? 'Отправка...' : 'Отправить',
            onPressed: (_selectedChild == null || _sending || _loading) ? null : _send,
          ),
        ],
      ),
    );
  }
}
