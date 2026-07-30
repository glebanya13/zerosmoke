import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/app_state.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_args.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_icon_button.dart';
import '../../core/widgets/step_dots.dart';
import 'role_selection_screen.dart';

class AgeSelectionScreen extends StatefulWidget {
  const AgeSelectionScreen({super.key, required this.args});

  final CreateAccountArgs args;

  @override
  State<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen> {
  String? _selected;

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
                  StepDots(total: 6, activeStep: 1, currentCompleted: _selected != null),
                ],
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: double.infinity,
                child: Text(
                  'Выбери возраст',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.screenTitle,
                ),
              ),
              const SizedBox(height: 176),
              for (final age in ['6+', '12+', '18+']) ...[
                SelectOptionTile(
                  label: age,
                  selected: _selected == age,
                  onTap: () => setState(() => _selected = age),
                ),
                const SizedBox(height: 20),
              ],
              const Spacer(),
              AppButton(
                label: 'Продолжить',
                enabled: _selected != null,
                onPressed: _selected == null
                    ? null
                    : () {
                        final suggestedAge = switch (_selected!) {
                          '6+' => 10,
                          '12+' => 14,
                          '18+' => 18,
                          _ => null,
                        };
                        final createAccountArgs =
                            widget.args.copyWith(suggestedAge: suggestedAge);
                        context.read<AppState>().setPendingCreateAccount(createAccountArgs);
                        context.push(AppRoutes.createAccount, extra: createAccountArgs);
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
