import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_args.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _controller.text.trim();
    if (email.isEmpty) return;
    if (!isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректный e-mail')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthRepository>().requestOtp(email, OtpPurpose.login);
      if (!mounted) return;
      final args = CodeVerifyArgs(email: email, purpose: OtpPurpose.login);
      context.read<AppState>().setPendingCodeVerify(args);
      context.push(AppRoutes.registerCode, extra: args);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const Text('Привет', style: AppTextStyles.screenTitle),
              const SizedBox(height: 140),
              const Align(
                alignment: Alignment.center,
                child: Text(
                  'Вход',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _controller,
                hintText: 'Логин',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextButton(
                onPressed: () => context.push(AppRoutes.registerEmail),
                child: const Text('Создать аккаунт', style: AppTextStyles.link),
              ),
              const Spacer(),
              AppButton(
                label: _isLoading ? 'Отправка...' : 'Войти',
                onPressed: _isLoading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
