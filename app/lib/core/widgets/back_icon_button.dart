import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';

/// Rounded-square back button matching the onboarding/registration header
/// (white box, small corner radius) used across role/age/create-account.
class BackIconButton extends StatelessWidget {
  const BackIconButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: const Icon(Icons.chevron_left, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}
