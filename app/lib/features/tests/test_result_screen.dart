import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_args.dart';
import '../../core/widgets/app_button.dart';

/// «Тест пройден!» — экран результата с реальным счётом попытки.
class TestResultScreen extends StatelessWidget {
  const TestResultScreen({super.key, required this.args});

  final TestResultArgs args;

  @override
  Widget build(BuildContext context) {
    final total = args.totalCount == 0 ? 1 : args.totalCount;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: const [
                        Icon(Icons.chevron_left, size: 24, color: AppColors.textPrimary),
                        Text(
                          'назад',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${args.correctCount} из ${args.totalCount}',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: args.correctCount / total,
                  minHeight: 8,
                  backgroundColor: AppColors.primaryDeep,
                  valueColor: const AlwaysStoppedAnimation(AppColors.textHeading),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                args.testTitle,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 28 / 24,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Тест пройден!',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 58),
                      const Text(
                        'Правильных ответов:',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${args.correctCount}/${args.totalCount}',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (!args.paid)
                        Center(
                          child: GestureDetector(
                            onTap: () => context.push(AppRoutes.subscription),
                            child: Container(
                              width: 242,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.textHeading),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'С подпиской доступно больше возможностей и статистики',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 18 / 14,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Оформить подписку',
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textHeading,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: TextButton(
                            onPressed: () => context.push(AppRoutes.ratingStatistics),
                            child: const Text(
                              'Подробнее',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+${args.correctCount}',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Image.asset(
                              'assets/images/icons/icon_coin.png',
                              width: 44,
                              height: 44,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      style: AppButtonStyle.white,
                      expand: true,
                      label: 'На главную',
                      onPressed: () => context.go(AppRoutes.root),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: AppButton(
                      expand: true,
                      label: 'К тестам',
                      onPressed: () => context.go('${AppRoutes.root}?tab=1'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
