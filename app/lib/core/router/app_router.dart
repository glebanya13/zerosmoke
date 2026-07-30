import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_args.dart';
import 'route_extra.dart';
import '../../data/app_state.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/welcome_onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_email_screen.dart';
import '../../features/auth/register_code_screen.dart';
import '../../features/auth/role_selection_screen.dart';
import '../../features/auth/age_selection_screen.dart';
import '../../features/auth/create_account_screen.dart';
import '../../features/home/root_shell.dart';
import '../../features/tests/test_flow_screen.dart';
import '../../features/tests/test_result_screen.dart';
import '../../features/rating/rating_statistics_screen.dart';
import '../../features/tips/tip_detail_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/rewards/rewards_screen.dart';
import '../../features/subscription/subscription_screen.dart';
import '../../features/subscription/promo_onboarding_screen.dart';
import '../../features/linking/account_linking_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const registerEmail = '/register-email';
  static const registerCode = '/register-code';
  static const roleSelection = '/role-selection';
  static const ageSelection = '/age-selection';
  static const createAccount = '/create-account';
  static const root = '/root';
  static const testFlow = '/test-flow';
  static const testResult = '/test-result';
  static const ratingStatistics = '/rating-statistics';
  static const tipDetail = '/tip-detail';
  static const editProfile = '/edit-profile';
  static const settings = '/settings';
  static const rewards = '/rewards';
  static const subscription = '/subscription';
  static const promoOnboarding = '/promo-onboarding';
  static const accountLinking = '/account-linking';
}

const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.registerEmail,
  AppRoutes.registerCode,
  AppRoutes.roleSelection,
  AppRoutes.ageSelection,
  AppRoutes.createAccount,
  AppRoutes.welcome,
  AppRoutes.promoOnboarding,
};

GoRouter createAppRouter(AppState appState) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: appState,
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);

      if (appState.isBootstrapping) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (!appState.isAuthenticated && !isPublic) {
        return AppRoutes.login;
      }

      if (appState.isAuthenticated &&
          (location == AppRoutes.login ||
              location == AppRoutes.registerEmail ||
              location == AppRoutes.splash)) {
        return AppRoutes.root;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (c, s) => const SplashScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (c, s) => const WelcomeOnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (c, s) => const LoginScreen()),
      GoRoute(path: AppRoutes.registerEmail, builder: (c, s) => const RegisterEmailScreen()),
      GoRoute(
        path: AppRoutes.registerCode,
        builder: (c, s) {
          final args = codeVerifyArgs(s, c);
          if (args == null) return const RegisterEmailScreen();
          return RegisterCodeScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (c, s) {
          final args = registrationArgs(s, c);
          if (args == null) return const RegisterEmailScreen();
          return RoleSelectionScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.ageSelection,
        builder: (c, s) {
          final args = createAccountArgs(s, c);
          if (args == null) return const RegisterEmailScreen();
          return AgeSelectionScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.createAccount,
        builder: (c, s) {
          final args = createAccountArgs(s, c);
          if (args == null) return const RegisterEmailScreen();
          return CreateAccountScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.root,
        builder: (c, s) {
          final tab = int.tryParse(s.uri.queryParameters['tab'] ?? '') ?? 0;
          return RootShell(initialTab: tab.clamp(0, 3));
        },
      ),
      GoRoute(
        path: AppRoutes.testFlow,
        builder: (c, s) => TestFlowScreen(args: s.extra as TestFlowArgs),
      ),
      GoRoute(
        path: AppRoutes.testResult,
        builder: (c, s) => TestResultScreen(args: s.extra as TestResultArgs),
      ),
      GoRoute(path: AppRoutes.ratingStatistics, builder: (c, s) => const RatingStatisticsScreen()),
      GoRoute(
        path: AppRoutes.tipDetail,
        builder: (c, s) => TipDetailScreen(args: s.extra as TipDetailArgs),
      ),
      GoRoute(path: AppRoutes.editProfile, builder: (c, s) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.settings, builder: (c, s) => const SettingsScreen()),
      GoRoute(path: AppRoutes.rewards, builder: (c, s) => const RewardsScreen()),
      GoRoute(path: AppRoutes.subscription, builder: (c, s) => const SubscriptionScreen()),
      GoRoute(path: AppRoutes.promoOnboarding, builder: (c, s) => const PromoOnboardingScreen()),
      GoRoute(path: AppRoutes.accountLinking, builder: (c, s) => const AccountLinkingScreen()),
    ],
  );
}
