import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_text_styles.dart';

/// Переключатель Ж/М из фигмы: трек #D1E2FF r=16 высотой 40,
/// выбранный сегмент — белая пилюля с тонкой рамкой,
/// невыбранный текст #777.
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.isRightSelected,
    required this.onChanged,
  });

  final String leftLabel;
  final String rightLabel;
  final bool isRightSelected;
  final ValueChanged<bool> onChanged;

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? Border.all(color: Colors.black.withValues(alpha: 0.15), width: 0.5)
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.textPrimary : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.toggleTrack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _segment(leftLabel, !isRightSelected, () => onChanged(false)),
          _segment(rightLabel, isRightSelected, () => onChanged(true)),
        ],
      ),
    );
  }
}
