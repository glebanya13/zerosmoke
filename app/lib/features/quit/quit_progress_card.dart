import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/quit_models.dart';
import '../../data/repositories/quit_repository.dart';

/// Adult quit-progress summary with onboarding and craving log.
class QuitProgressCard extends StatefulWidget {
  const QuitProgressCard({super.key});

  @override
  State<QuitProgressCard> createState() => _QuitProgressCardState();
}

class _QuitProgressCardState extends State<QuitProgressCard> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  QuitProfile? _profile;

  final _cigarettesController = TextEditingController(text: '10');
  final _packPriceController = TextEditingController(text: '250');

  @override
  void dispose() {
    _cigarettesController.dispose();
    _packPriceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await context.read<QuitRepository>().getMe();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        if (profile.cigarettesPerDay > 0) {
          _cigarettesController.text = '${profile.cigarettesPerDay}';
        }
        if (profile.packPriceCents > 0) {
          _packPriceController.text = '${profile.packPriceCents ~/ 100}';
        }
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

  Future<void> _startQuit() async {
    final cigarettes = int.tryParse(_cigarettesController.text.trim());
    final packRub = int.tryParse(_packPriceController.text.trim());
    if (cigarettes == null || cigarettes <= 0 || packRub == null || packRub <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите корректные значения')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Начать отказ?'),
        content: const Text(
          'Дата отказа будет установлена на сегодня. Позже её можно будет изменить в настройках.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Начать')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final profile = await context.read<QuitRepository>().updateMe(
        quitDate: DateTime.now().toUtc().toIso8601String(),
        cigarettesPerDay: cigarettes,
        packPriceCents: packRub * 100,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _saving = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _logCraving() async {
    final intensity = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Насколько сильная тяга?'),
        children: [
          for (final value in [1, 2, 3, 4, 5])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, value),
              child: Text('$value из 5'),
            ),
        ],
      ),
    );
    if (intensity == null || !mounted) return;

    try {
      await context.read<QuitRepository>().logCraving(intensity: intensity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тяга записана')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(_error!, style: AppTextStyles.body),
            TextButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }

    final profile = _profile!;
    if (profile.quitDate == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Отказ от курения', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            const Text(
              'Укажите привычки, чтобы мы могли считать прогресс и сэкономленные деньги.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cigarettesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Сигарет в день'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _packPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Цена пачки, ₽'),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: _saving ? 'Сохранение...' : 'Начать отказ с сегодня',
              onPressed: _saving ? null : _startQuit,
            ),
          ],
        ),
      );
    }

    final moneyRub = (profile.moneySavedCents / 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.progressCardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Прогресс отказа',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Stat(label: 'Дней без курения', value: '${profile.daysSmokeFree}')),
              Expanded(child: _Stat(label: 'Сигарет избежано', value: '${profile.cigarettesAvoided}')),
              Expanded(child: _Stat(label: 'Сэкономлено', value: '$moneyRub ₽')),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _logCraving,
              child: const Text('Записать тягу'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
