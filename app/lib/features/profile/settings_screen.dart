import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/app_state.dart';
import '../../data/models/settings_model.dart';
import '../../data/repositories/settings_repository.dart';

/// Настройки: учебный процесс, уведомления, конфиденциальность — по фигме
/// (белые карточки r=20, строки Inter 16 #777, тогглы 48×28), сохраняются на бэкенде.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  String? _error;
  UserSettingsModel? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await context.read<SettingsRepository>().getMine();
      if (!mounted) return;
      context.read<AppState>().applySettings(settings);
      setState(() {
        _settings = settings;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _set(String field, bool value) async {
    final previous = _settings!;
    setState(() => _settings = _applyField(previous, field, value));
    try {
      final updated = await context.read<SettingsRepository>().updateMine({field: value});
      if (!mounted) return;
      context.read<AppState>().applySettings(updated);
      setState(() => _settings = updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _settings = previous);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  UserSettingsModel _applyField(UserSettingsModel s, String field, bool value) {
    switch (field) {
      case 'soundEnabled':
        return s.copyWith(soundEnabled: value);
      case 'vibrationEnabled':
        return s.copyWith(vibrationEnabled: value);
      case 'hintsEnabled':
        return s.copyWith(hintsEnabled: value);
      case 'notifyTests':
        return s.copyWith(notifyTests: value);
      case 'notifyRankChanges':
        return s.copyWith(notifyRankChanges: value);
      case 'dataCollection':
        return s.copyWith(dataCollection: value);
      case 'showActivity':
        return s.copyWith(showActivity: value);
      default:
        return s;
    }
  }

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
              child: ScreenHeader(title: 'Настройки'),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!, style: AppTextStyles.body))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        40,
                      ),
                      children: [
                        _supportCard(),
                        const SizedBox(height: 10),
                        _group('Учебный процесс', [
                          ('Звуковые эффекты', 'soundEnabled', _settings!.soundEnabled, null),
                          ('Вибрация', 'vibrationEnabled', _settings!.vibrationEnabled, null),
                          ('Подсказки', 'hintsEnabled', _settings!.hintsEnabled, null),
                        ]),
                        const SizedBox(height: 10),
                        _group('Уведомления', [
                          ('Звуковое оповещение', 'soundEnabled', _settings!.soundEnabled, null),
                          ('Вибрация', 'vibrationEnabled', _settings!.vibrationEnabled, null),
                          ('Новые тесты', 'notifyTests', _settings!.notifyTests, null),
                          (
                            'Место в рейтинге',
                            'notifyRankChanges',
                            _settings!.notifyRankChanges,
                            null,
                          ),
                        ]),
                        const SizedBox(height: 10),
                        _group('Конфиденциальность', [
                          (
                            'Сбор данных',
                            'dataCollection',
                            _settings!.dataCollection,
                            'Отслеживание действий и персонализация для рекламы',
                          ),
                          (
                            'Показывать активность всем',
                            'showActivity',
                            _settings!.showActivity,
                            'Трансляция ваших достижений в общем рейтинге всех пользователей',
                          ),
                        ]),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _supportCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(AppRoutes.promoOnboarding),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Image.asset(
                'assets/images/icons/icon_heart_support.png',
                width: 36,
                height: 34,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Поддержите развитие проекта',
                      style: TextStyle(
                        fontFamily: AppTextStyles.interFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Узнать о возможностях подписки и помочь развитию приложения',
                      style: TextStyle(
                        fontFamily: AppTextStyles.interFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _group(String title, List<(String, String, bool, String?)> rows) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTextStyles.interFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 17, thickness: 1, color: AppColors.divider),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rows[i].$1,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.interFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textGrey,
                        ),
                      ),
                      if (rows[i].$4 != null)
                        Text(rows[i].$4!, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                _MiniToggle(
                  value: rows[i].$3,
                  onChanged: (v) => _set(rows[i].$2, v),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Тоггл из фигмы: 48×28, включён — #26B5FF, выключен — #ACA6A6.
class _MiniToggle extends StatelessWidget {
  const _MiniToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.toggleOff,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
