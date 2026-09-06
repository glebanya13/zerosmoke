import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/network/token_storage.dart';
import '../core/router/route_args.dart';
import '../models/models.dart';
import 'models/backend_user.dart';
import 'models/settings_model.dart';
import 'repositories/auth_repository.dart';
import 'repositories/users_repository.dart';
import 'repositories/subscription_repository.dart';

/// Global mutable session state: current role, subscription flag, and the
/// authenticated user's profile once real backend auth is wired in.
class AppState extends ChangeNotifier {
  UserRole role = UserRole.child;
  bool hasSubscription = false;
  bool isAuthenticated = false;
  bool isBootstrapping = true;

  /// Survives go_router rebuilds when [GoRouterState.extra] is lost.
  CodeVerifyArgs? pendingCodeVerify;
  RegistrationArgs? pendingRegistration;
  CreateAccountArgs? pendingCreateAccount;

  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool hintsEnabled = true;

  final AppUser childUser = AppUser(
    name: '',
    age: 0,
    isFemale: false,
    avatarIndex: 0,
    phone: '',
    email: '',
  );

  final AppUser parentUser = AppUser(
    name: '',
    age: 0,
    isFemale: true,
    avatarIndex: 0,
    phone: '',
    email: '',
  );

  bool get isParent => role == UserRole.parent;
  bool get isAdult => role == UserRole.adult;

  /// Active bottom-nav tab inside [RootShell]. Survives test-flow pop.
  int shellTab = 0;

  /// Bumped when content (tests/progress) changes and tabs should soft-reload.
  int contentEpoch = 0;

  void setShellTab(int tab) {
    final next = tab.clamp(0, 3);
    if (shellTab == next) return;
    shellTab = next;
    notifyListeners();
  }

  void bumpContentEpoch() {
    contentEpoch++;
    notifyListeners();
  }

  void setPendingCodeVerify(CodeVerifyArgs args) {
    pendingCodeVerify = args;
  }

  void setPendingRegistration(RegistrationArgs args) {
    pendingRegistration = args;
  }

  void setPendingCreateAccount(CreateAccountArgs args) {
    pendingCreateAccount = args;
  }

  void clearRegistrationFlow() {
    pendingCodeVerify = null;
    pendingRegistration = null;
    pendingCreateAccount = null;
  }

  void setRole(UserRole newRole) {
    role = newRole;
    notifyListeners();
  }

  void setSubscription(bool value) {
    hasSubscription = value;
    notifyListeners();
  }

  void applySettings(UserSettingsModel settings) {
    soundEnabled = settings.soundEnabled;
    vibrationEnabled = settings.vibrationEnabled;
    hintsEnabled = settings.hintsEnabled;
    notifyListeners();
  }

  /// Applies a freshly authenticated backend profile: sets [role] and
  /// overwrites the matching user slot (`childUser`/`parentUser`).
  void applyAuthenticatedUser(BackendUser user) {
    role = user.role;
    final target = user.role == UserRole.parent ? parentUser : childUser;
    target
      ..id = user.id
      ..name = user.name
      ..age = user.age
      ..isFemale = user.isFemale
      ..avatarIndex = user.avatarIndex
      ..phone = user.phone ?? target.phone
      ..email = user.email;
    isAuthenticated = true;
    notifyListeners();
  }

  Future<void> tryAutoLogin(
    TokenStorage tokenStorage,
    UsersRepository usersRepository, [
    SubscriptionRepository? subscriptionRepository,
  ]) async {
    if (tokenStorage.accessToken != null) {
      try {
        final user = await usersRepository.getMe();
        applyAuthenticatedUser(user);
        if (subscriptionRepository != null) {
          await refreshSubscriptionStatus(subscriptionRepository);
        }
      } catch (_) {
        isAuthenticated = false;
      }
    }
    isBootstrapping = false;
    notifyListeners();
  }

  Future<void> refreshSubscriptionStatus(SubscriptionRepository subscriptionRepository) async {
    try {
      final status = await subscriptionRepository.getMine();
      hasSubscription = status?.isActive ?? false;
      notifyListeners();
    } catch (_) {
      // Subscription status is optional; keep the previous value.
    }
  }

  void handleSessionExpired() {
    if (!isAuthenticated) return;
    clearRegistrationFlow();
    isAuthenticated = false;
    hasSubscription = false;
    shellTab = 0;
    contentEpoch = 0;
    soundEnabled = true;
    vibrationEnabled = true;
    hintsEnabled = true;
    _resetUser(childUser);
    _resetUser(parentUser);
    notifyListeners();
  }

  void _resetUser(AppUser user) {
    user
      ..id = null
      ..name = ''
      ..age = 0
      ..avatarIndex = 0
      ..phone = ''
      ..email = '';
  }

  Future<void> logout(AuthRepository authRepository) async {
    await authRepository.logout();
    clearRegistrationFlow();
    isAuthenticated = false;
    hasSubscription = false;
    shellTab = 0;
    contentEpoch = 0;
    soundEnabled = true;
    vibrationEnabled = true;
    hintsEnabled = true;
    _resetUser(childUser);
    _resetUser(parentUser);
    notifyListeners();
  }
}
