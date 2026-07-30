import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_args.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_icon_button.dart';
import '../../core/widgets/step_dots.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key, required this.args});

  final RegistrationArgs args;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackIconButton(onPressed: () => context.pop()),
                  ),
                  StepDots(total: 6, activeStep: 0, currentCompleted: _selected != null),
                ],
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: double.infinity,
                child: Text(
                  'Выбери роль',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.screenTitle,
                ),
              ),
              const SizedBox(height: 176),
              SelectOptionTile(
                label: 'Родитель',
                selected: _selected == UserRole.parent,
                onTap: () => setState(() => _selected = UserRole.parent),
              ),
              const SizedBox(height: 20),
              SelectOptionTile(
                label: 'Ребёнок',
                selected: _selected == UserRole.child,
                onTap: () => setState(() => _selected = UserRole.child),
              ),
              const SizedBox(height: 20),
              SelectOptionTile(
                label: 'Взрослый',
                selected: _selected == UserRole.adult,
                onTap: () => setState(() => _selected = UserRole.adult),
              ),
              const Spacer(),
              AppButton(
                label: 'Продолжить',
                enabled: _selected != null,
                onPressed: _selected == null
                    ? null
                    : () {
                        final selected = _selected!;
                        final createAccountArgs = CreateAccountArgs(
                          email: widget.args.email,
                          registrationToken: widget.args.registrationToken,
                          role: selected,
                        );
                        final appState = context.read<AppState>();
                        appState.setPendingCreateAccount(createAccountArgs);
                        if (selected == UserRole.parent) {
                          context.push(AppRoutes.createAccount, extra: createAccountArgs);
                        } else {
                          context.push(AppRoutes.ageSelection, extra: createAccountArgs);
                        }
                        appState.setRole(selected);
                      },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Опция выбора из фигмы: 300×60, r=20; невыбранная — белая с рамкой
/// #8C969D, выбранная — заливка #B1B1FF с белым жирным текстом.
class SelectOptionTile extends StatelessWidget {
  const SelectOptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 300,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accentPurpleLight : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: selected ? null : Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
