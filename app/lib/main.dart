import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/design_system/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/network/token_storage.dart';
import 'core/router/app_router.dart';
import 'data/app_state.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/links_repository.dart';
import 'data/repositories/referrals_repository.dart';
import 'data/repositories/users_repository.dart';
import 'data/repositories/content_repository.dart';
import 'data/repositories/rating_repository.dart';
import 'data/repositories/achievements_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/subscription_repository.dart';
import 'data/repositories/quit_repository.dart';
import 'core/notifications/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokenStorage = TokenStorage();
  await tokenStorage.load();
  final appState = AppState();
  final apiClient = ApiClient(
    tokenStorage,
    onSessionExpired: appState.handleSessionExpired,
  );
  final push = PushNotificationService(apiClient);
  await push.init();

  runApp(AntismokeApp(
    appState: appState,
    tokenStorage: tokenStorage,
    apiClient: apiClient,
    pushService: push,
  ));
}

class AntismokeApp extends StatefulWidget {
  const AntismokeApp({
    super.key,
    required this.appState,
    required this.tokenStorage,
    required this.apiClient,
    required this.pushService,
  });

  final AppState appState;
  final TokenStorage tokenStorage;
  final ApiClient apiClient;
  final PushNotificationService pushService;

  @override
  State<AntismokeApp> createState() => _AntismokeAppState();
}

class _AntismokeAppState extends State<AntismokeApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(widget.appState);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: widget.tokenStorage),
        Provider.value(value: widget.apiClient),
        Provider(create: (_) => AuthRepository(widget.apiClient, widget.tokenStorage)),
        Provider(create: (_) => UsersRepository(widget.apiClient)),
        Provider(create: (_) => LinksRepository(widget.apiClient)),
        Provider(create: (_) => ReferralsRepository(widget.apiClient)),
        Provider(create: (_) => ContentRepository(widget.apiClient)),
        Provider(create: (_) => RatingRepository(widget.apiClient)),
        Provider(create: (_) => AchievementsRepository(widget.apiClient)),
        Provider(create: (_) => SettingsRepository(widget.apiClient)),
        Provider(create: (_) => SubscriptionRepository(widget.apiClient)),
        Provider(create: (_) => QuitRepository(widget.apiClient)),
        Provider.value(value: widget.pushService),
        ChangeNotifierProvider.value(value: widget.appState),
      ],
      child: MaterialApp.router(
        title: 'ZeroSmoke',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
