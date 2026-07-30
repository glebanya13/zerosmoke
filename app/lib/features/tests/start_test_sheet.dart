import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/widgets/app_button.dart';

/// "Начнём? / Продолжим?" confirmation modal before a test starts.
class StartTestSheet extends StatelessWidget {
  const StartTestSheet({
    super.key,
    required this.onStart,
    required this.testTitle,
    this.isContinue = false,
  });

  final VoidCallback onStart;
  final String testTitle;
  final bool isContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isContinue ? 'Продолжим?' : 'Начнём?', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 120,
            height: 120,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                const SizedBox(height: 4),
                Text(
                  testTitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: isContinue ? 'Продолжить' : 'Начать', onPressed: onStart),
          if (!isContinue) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отложить', style: AppTextStyles.link),
            ),
          ],
        ],
      ),
    );
  }
}
