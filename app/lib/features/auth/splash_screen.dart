import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/network/token_storage.dart';
import '../../core/router/app_router.dart';
import '../../data/app_state.dart';
import '../../data/repositories/users_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/notifications/push_notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Defer to a microtask so AppState.notifyListeners() (triggered inside
    // tryAutoLogin, possibly synchronously if there's no stored token) never
    // fires while this widget is still in its initial build phase.
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    final appState = context.read<AppState>();
    final tokenStorage = context.read<TokenStorage>();
    final usersRepository = context.read<UsersRepository>();
    final subscriptionRepository = context.read<SubscriptionRepository>();
    final settingsRepository = context.read<SettingsRepository>();
    final push = context.read<PushNotificationService>();

    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1200)),
      appState.tryAutoLogin(tokenStorage, usersRepository, subscriptionRepository),
    ]);

    if (appState.isAuthenticated) {
      try {
        final settings = await settingsRepository.getMine();
        appState.applySettings(settings);
      } catch (_) {
        // Settings are optional at boot; defaults remain.
      }
      try {
        await push.registerWithBackend();
      } catch (_) {
        // Push registration is best-effort.
      }
    }

    if (!mounted) return;
    context.go(appState.isAuthenticated ? AppRoutes.root : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: Center(
        child: Text(
          'Zero Smoke',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
