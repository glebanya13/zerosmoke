import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_system/app_text_styles.dart';
import '../router/app_router.dart';
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
          // Отступ слева/справа, чтобы длинный title не накрывал кнопку назад.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              title,
              style: AppTextStyles.headerTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          // Кнопка поверх текста — иначе overflow title перехватывает тапы.
          Align(
            alignment: Alignment.centerLeft,
            child: BackIconButton(
              onPressed: onBack ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.root);
                    }
                  },
            ),
          ),
        ],
      ),
    );
  }
}
