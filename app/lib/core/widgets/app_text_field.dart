import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_dimens.dart';
import '../design_system/app_text_styles.dart';

/// Поле ввода из фигмы: белое, r=20, текст слева SF Regular 20.
/// Пустое — рамка #8C969D, заполненное/в фокусе — рамка #26B5FF.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final hasText = controller != null && controller.text.isNotEmpty;
    final borderColor = hasText ? AppColors.primary : AppColors.border;

    return TextField(
      controller: controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      style: AppTextStyles.inputText,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: widget.hintText,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }
}
