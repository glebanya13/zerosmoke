import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import 'route_args.dart';

RegistrationArgs? registrationArgs(GoRouterState state, BuildContext context) {
  final extra = state.extra;
  if (extra is RegistrationArgs) return extra;
  return context.read<AppState>().pendingRegistration;
}

CreateAccountArgs? createAccountArgs(GoRouterState state, BuildContext context) {
  final extra = state.extra;
  if (extra is CreateAccountArgs) return extra;
  return context.read<AppState>().pendingCreateAccount;
}

CodeVerifyArgs? codeVerifyArgs(GoRouterState state, BuildContext context) {
  final extra = state.extra;
  if (extra is CodeVerifyArgs) return extra;
  return context.read<AppState>().pendingCodeVerify;
}
