import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_args.dart';
import '../../core/widgets/avatar_circle.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_icon_button.dart';
import '../../core/widgets/step_dots.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/segmented_toggle.dart';
import '../../data/app_state.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import 'avatar_picker_sheet.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key, required this.args});

  final CreateAccountArgs args;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isMale = true;
  int _selectedAvatar = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final suggested = widget.args.suggestedAge;
    if (suggested != null) {
      _ageController.text = '$suggested';
    }
  }

  Future<void> _pickAvatar() async {
    final index = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AvatarPickerSheet(),
    );
    if (index != null && mounted) {
      setState(() => _selectedAvatar = index);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    if (name.isEmpty || age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните имя и возраст')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await context.read<AuthRepository>().completeRegistration(
        registrationToken: widget.args.registrationToken,
        role: widget.args.role,
        name: name,
        age: age,
        isFemale: !_isMale,
        avatarIndex: _selectedAvatar,
      );
      if (!mounted) return;
      final appState = context.read<AppState>();
      appState.clearRegistrationFlow();
      appState.applyAuthenticatedUser(user);
      await appState.refreshSubscriptionStatus(context.read<SubscriptionRepository>());
      if (!mounted) return;
      context.push(AppRoutes.welcome);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackIconButton(onPressed: () => context.pop()),
                  ),
                  const StepDots(total: 6, activeStep: 2),
                ],
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: double.infinity,
                child: Text(
                  'Расскажи о себе',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.screenTitle,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Как тебя зовут?', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.xs),
                      AppTextField(controller: _nameController, hintText: 'Имя'),
                      const SizedBox(height: AppSpacing.md),
                      const Text('Сколько тебе лет?', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.xs),
                      AppTextField(
                        controller: _ageController,
                        hintText: 'Возраст',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('Выбери пол', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.xs),
                      SegmentedToggle(
                        leftLabel: 'Ж',
                        rightLabel: 'М',
                        isRightSelected: _isMale,
                        onChanged: (v) => setState(() => _isMale = v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('Выбери аватар', style: AppTextStyles.label),
                      const SizedBox(height: AppSpacing.sm),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cell =
                              (constraints.maxWidth - 2 * 8) / 3;
                          final size = cell.clamp(80.0, 100.0);
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AvatarCircle(
                                size: size,
                                child: const Center(
                                  child: Text(
                                    '+',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w200,
                                      height: 1,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                onTap: _pickAvatar,
                              ),
                              for (int i = 0; i < 12; i++)
                                AvatarCircle(
                                  size: size,
                                  avatarIndex: i,
                                  selected: _selectedAvatar == i,
                                  onTap: () => setState(() => _selectedAvatar = i),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: _isLoading ? 'Сохранение...' : 'Сохранить',
                onPressed: _isLoading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
