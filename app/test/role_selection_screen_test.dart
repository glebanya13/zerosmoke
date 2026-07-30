import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:zerosmoke/core/router/route_args.dart';
import 'package:zerosmoke/core/widgets/app_button.dart';
import 'package:zerosmoke/data/app_state.dart';
import 'package:zerosmoke/features/auth/role_selection_screen.dart';

void main() {
  Widget buildScreen() {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        home: RoleSelectionScreen(
          args: const RegistrationArgs(email: 'a@a.com', registrationToken: 'tok'),
        ),
      ),
    );
  }

  testWidgets('Continue is disabled until a role is picked', (tester) async {
    await tester.pumpWidget(buildScreen());

    final buttonBefore = tester.widget<AppButton>(find.byType(AppButton));
    expect(buttonBefore.enabled, isFalse);
    expect(buttonBefore.onPressed, isNull);

    await tester.tap(find.text('Ребёнок'));
    await tester.pump();

    final buttonAfter = tester.widget<AppButton>(find.byType(AppButton));
    expect(buttonAfter.enabled, isTrue);
    expect(buttonAfter.onPressed, isNotNull);
  });
}
