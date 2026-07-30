import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography scale extracted directly from the Figma file.
/// Headings use Manrope, home-screen/nav labels use Inter and controls
/// (buttons, inputs) use the platform SF font (no explicit family).
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Manrope';
  static const String interFamily = 'Inter';

  /// Большой синий заголовок экранов онбординга («Привет», «Выбери роль»).
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textHeading,
  );

  /// Синий заголовок внутренних экранов рядом с back-кнопкой.
  static const TextStyle headerTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textHeading,
  );

  /// Чёрный заголовок таба («Тесты»).
  static const TextStyle pageTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Заголовок секции списка («Новые тесты», «Советы») — Manrope Bold 18.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Заголовок карточки — Manrope SemiBold 16.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Подпись поля анкеты — Manrope Regular 20.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  /// Текст CTA-кнопок — SF (системный) Medium 20.
  static const TextStyle buttonText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.textOnPrimary,
  );

  /// Текст в полях ввода — SF (системный) Regular 20.
  static const TextStyle inputText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.textHeading,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Подписи на Главной/навигации — Inter Medium 12.
  static const TextStyle navLabel = TextStyle(
    fontFamily: interFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  /// Имя в стат-баре — Inter Medium 20.
  static const TextStyle interName = TextStyle(
    fontFamily: interFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  /// Синие очки «86/102» — Manrope SemiBold 20.
  static const TextStyle points = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textHeading,
  );

  /// Жёлтые монеты «86» — Manrope Bold 24.
  static const TextStyle coins = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.warning,
  );

  static const TextStyle statNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
}
