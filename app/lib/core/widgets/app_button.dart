import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_text_styles.dart';

enum AppButtonStyle { primary, white, success, invite, gradient }

/// CTA-кнопка из фигмы: 48px высотой, r=16, заливка #26B5FF,
/// текст SF (системный) Medium 20. По умолчанию 300px по центру —
/// как «Войти»/«Продолжить»; [expand] растягивает на всю ширину
/// (варианты 361px и полуширинные в ряд).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.enabled = true,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool enabled;

  /// true — на всю доступную ширину; false — фиксированные 300px по центру.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = enabled && onPressed != null;

    Color background = AppColors.primary;
    Color textColor = AppColors.textOnPrimary;
    Gradient? gradient;

    switch (style) {
      case AppButtonStyle.primary:
        background = AppColors.primary;
        break;
      case AppButtonStyle.white:
        background = Colors.white;
        textColor = AppColors.textPrimary;
        break;
      case AppButtonStyle.success:
        background = AppColors.success;
        break;
      case AppButtonStyle.invite:
        background = AppColors.inviteGreen;
        break;
      case AppButtonStyle.gradient:
        gradient = AppColors.primaryGradient;
        break;
    }

    final button = Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: expand ? double.infinity : 300,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gradient == null ? background : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: AppTextStyles.buttonText.copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );

    return expand ? button : Center(child: button);
  }
}
