import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_args.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/code_input_boxes.dart';
import '../../data/app_state.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../core/notifications/push_notification_service.dart';

class RegisterCodeScreen extends StatefulWidget {
  const RegisterCodeScreen({super.key, required this.args});

  final CodeVerifyArgs args;

  @override
  State<RegisterCodeScreen> createState() => _RegisterCodeScreenState();
}

class _RegisterCodeScreenState extends State<RegisterCodeScreen> {
  String? _lastCode;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verify(String code) async {
    setState(() {
      _lastCode = code;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await context.read<AuthRepository>().verifyOtp(
        widget.args.email,
        code,
        widget.args.purpose,
      );
      if (!mounted) return;

      switch (result) {
        case OtpVerifyLoginResult(:final user):
          final appState = context.read<AppState>();
          final subscriptions = context.read<SubscriptionRepository>();
          final push = context.read<PushNotificationService>();
          appState.applyAuthenticatedUser(user);
          await appState.refreshSubscriptionStatus(subscriptions);
          await push.registerWithBackend();
          if (!mounted) return;
          context.go(AppRoutes.root);
        case OtpVerifyRegisterResult(:final registrationToken):
          final registrationArgs = RegistrationArgs(
            email: widget.args.email,
            registrationToken: registrationToken,
          );
          context.read<AppState>().setPendingRegistration(registrationArgs);
          context.push(AppRoutes.roleSelection, extra: registrationArgs);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
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
              const SizedBox(height: 252),
              const Text(
                'Регистрация',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CodeInputBoxes(length: 4, onCompleted: _isLoading ? null : _verify),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage ?? 'Введите код для подтверждения регистрации',
                textAlign: TextAlign.center,
                style: _errorMessage != null
                    ? AppTextStyles.bodySecondary.copyWith(color: Colors.red)
                    : AppTextStyles.bodySecondary,
              ),
              const Spacer(),
              AppButton(
                label: _isLoading ? 'Проверка...' : 'Подтвердить',
                onPressed: (_lastCode == null || _isLoading) ? null : () => _verify(_lastCode!),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
