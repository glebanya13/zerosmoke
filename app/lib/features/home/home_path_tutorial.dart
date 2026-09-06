import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/widgets/app_button.dart';

/// Пошаговая подсказка «Тропинка тестов» на Главной (фигма, 3 шага).
class HomePathTutorial extends StatefulWidget {
  const HomePathTutorial({super.key, required this.onFinished});

  final VoidCallback onFinished;

  static const _prefsKey = 'home_path_tutorial_done_v1';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefsKey) ?? false);
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  @override
  State<HomePathTutorial> createState() => _HomePathTutorialState();
}

class _HomePathTutorialState extends State<HomePathTutorial> {
  int _step = 0;

  static const _pages = [
    (
      title: 'Тропинка тестов',
      body: 'Проходите тесты по порядку — каждый узел открывает новую тему.',
    ),
    (
      title: 'Рекомендации',
      body: 'Оранжевая кнопка подскажет, с какого теста лучше начать сегодня.',
    ),
    (
      title: 'Прогресс',
      body: 'Звёзды, монеты и место в рейтинге обновляются после каждого теста.',
    ),
  ];

  Future<void> _finish() async {
    await HomePathTutorial.markDone();
    widget.onFinished();
  }

  void _next() {
    if (_step >= _pages.length - 1) {
      _finish();
      return;
    }
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_step];
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Material(
      color: const Color(0x99000000),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  page.body,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontSize: 16,
                    color: AppColors.textDark,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      '${_step + 1}/${_pages.length}',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textHeading,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Пропустить',
                        style: AppTextStyles.link.copyWith(fontSize: 16),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      child: AppButton(
                        label: _step == _pages.length - 1 ? 'Готово' : 'Далее',
                        expand: true,
                        onPressed: _next,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: bottomInset > 0 ? 4 : 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
