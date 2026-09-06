import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/router/route_args.dart';
import '../../core/widgets/screen_header.dart';
import 'tip_colors.dart';

/// Полный просмотр совета (одна секция памятки).
class TipDetailScreen extends StatelessWidget {
  const TipDetailScreen({super.key, required this.args});

  final TipDetailArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, 16, AppSpacing.md, 0),
              child: ScreenHeader(title: 'Совет'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: tipColors[args.colorIndex % tipColors.length],
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(args.section.title, style: AppTextStyles.screenTitle),
                  const SizedBox(height: AppSpacing.md),
                  Text(args.section.text, style: AppTextStyles.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
