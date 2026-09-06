import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/widgets/screen_header.dart';

/// «Как заработать» — объяснение звёзд, очков, монет и наград (фигма).
class HowToEarnScreen extends StatelessWidget {
  const HowToEarnScreen({super.key});

  static const _items = [
    _EarnItem(
      iconAsset: 'assets/images/icons/icon_star_filled.png',
      iconColor: AppColors.starYellow,
      title: 'Звёзды',
      description:
          'За каждые 20% пройденных тестов вы получаете 1 звезду (максимум 5).',
    ),
    _EarnItem(
      iconAsset: 'assets/images/icons/icon_graph.png',
      iconColor: AppColors.success,
      title: 'Очки',
      description:
          'За каждый правильный ответ в тесте начисляются очки. Они отображаются в рейтинге.',
    ),
    _EarnItem(
      iconAsset: 'assets/images/icons/icon_coin.png',
      iconColor: AppColors.warning,
      title: 'Монеты',
      description:
          'Монеты начисляются за прохождение тестов. Их можно тратить на награды в разделе «Достижения».',
    ),
    _EarnItem(
      iconAsset: 'assets/images/icons/icon_heart_support.png',
      iconColor: AppColors.dangerLight,
      title: 'Награды',
      description:
          'Открывайте достижения за прогресс в тестах и активность в приложении.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          children: [
            const SizedBox(height: 16),
            const ScreenHeader(title: 'Как заработать'),
            const SizedBox(height: 12),
            Text(
              'Проходите тесты, отвечайте правильно и следите за прогрессом в рейтинге.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(
                fontSize: 16,
                color: AppColors.textGrey,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            for (final item in _items) ...[
              _EarnCard(item: item),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _EarnItem {
  const _EarnItem({
    required this.iconAsset,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final String iconAsset;
  final Color iconColor;
  final String title;
  final String description;
}

class _EarnCard extends StatelessWidget {
  const _EarnCard({required this.item});

  final _EarnItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(item.iconAsset, color: item.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontSize: 14,
                    color: AppColors.textGrey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
