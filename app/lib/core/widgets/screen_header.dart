import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_system/app_text_styles.dart';
import 'back_icon_button.dart';

/// Шапка внутренних экранов из фигмы: белая квадратная back-кнопка 32×32
/// слева и синий заголовок Manrope SemiBold 24 по центру экрана.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: BackIconButton(onPressed: onBack ?? () => context.pop()),
          ),
          Text(
            title,
            style: AppTextStyles.headerTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
