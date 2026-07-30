import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';

/// Индикатор шагов регистрации из фигмы: круги 16px c интервалом 24px.
/// Пройденные шаги залиты #26B5FF, текущий — синий контур,
/// будущие — контур #D9D9D9.
class StepDots extends StatelessWidget {
  const StepDots({
    super.key,
    required this.total,
    required this.activeStep,
    this.currentCompleted = false,
  });

  final int total;

  /// 0-based индекс текущего шага.
  final int activeStep;

  /// true — выбор на текущем шаге сделан, его точка заливается.
  final bool currentCompleted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final bool completed = i < activeStep || (i == activeStep && currentCompleted);
        final bool current = i == activeStep;
        return Padding(
          padding: EdgeInsets.only(right: i == total - 1 ? 0 : 24),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? AppColors.primary : null,
              border: Border.all(
                color: completed || current
                    ? AppColors.primary
                    : AppColors.borderLight,
                width: 1,
              ),
            ),
          ),
        );
      }),
    );
  }
}
