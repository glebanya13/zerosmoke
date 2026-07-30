import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:zerosmoke/data/app_state.dart';
import 'package:zerosmoke/core/network/api_client.dart';
import 'package:zerosmoke/core/network/token_storage.dart';
import 'package:zerosmoke/core/notifications/push_notification_service.dart';
import 'package:zerosmoke/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    final tokenStorage = TokenStorage();
    await tokenStorage.load();
    final appState = AppState();
    final apiClient = ApiClient(tokenStorage, onSessionExpired: appState.handleSessionExpired);
    await tester.pumpWidget(
      AntismokeApp(
        appState: appState,
        tokenStorage: tokenStorage,
        apiClient: apiClient,
        pushService: PushNotificationService(apiClient),
      ),
    );
    await tester.pump();
    expect(find.text('Zero Smoke'), findsOneWidget);

    // Let the splash screen's bootstrap timer/microtask finish so no Timer
    // is left pending when the test tears down.
    await tester.pump(const Duration(milliseconds: 1300));
  });
}
