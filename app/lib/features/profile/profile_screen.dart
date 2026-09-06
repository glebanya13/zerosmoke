import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/app_avatar.dart';
import '../../data/app_state.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/links_repository.dart';

/// Профиль (ребёнок/родитель): menu list to achievements, linking,
/// subscription, settings, logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _subscriptionPromoSeenKey = 'subscription_promo_seen_ymd';

  LinkInfo? _link;
  /// Подсветка «Подписка»: раз в день, пока нет оплаты и сегодня ещё не заходили.
  bool _showSubscriptionPromo = false;

  @override
  void initState() {
    super.initState();
    _loadLink();
    _loadSubscriptionPromo();
  }

  String _todayYmd() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  Future<void> _loadSubscriptionPromo() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getString(_subscriptionPromoSeenKey);
    final hasSub = context.read<AppState>().hasSubscription;
    if (!mounted) return;
    setState(() {
      _showSubscriptionPromo = !hasSub && seen != _todayYmd();
    });
  }

  Future<void> _openSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subscriptionPromoSeenKey, _todayYmd());
    if (!mounted) return;
    setState(() => _showSubscriptionPromo = false);
    context.push(AppRoutes.subscription);
  }

  Future<void> _loadLink() async {
    try {
      final link = await context.read<LinksRepository>().getMyLink();
      if (mounted) setState(() => _link = link);
    } catch (_) {
      // Best-effort — leave the linked-account UI in its "not linked" state.
    }
  }

  Future<void> _logout() async {
    final authRepository = context.read<AuthRepository>();
    final appState = context.read<AppState>();
    await appState.logout(authRepository);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.isParent ? state.parentUser : state.childUser;
    final highlightSubscription =
        !state.hasSubscription && _showSubscriptionPromo;

    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.md, topPad + 8, AppSpacing.md, 130),
        children: [
          // Шапка профиля: карточка r=30, аватар 72 с синей рамкой.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAvatar(index: user.avatarIndex, size: 72),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.phone,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.isParent
                            ? user.email
                            : (_link != null
                                ? 'Наставник: ${_link!.counterpart.name}'
                                : 'Наставник не подключен'),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.push(AppRoutes.editProfile),
                  icon: const Icon(Icons.edit, color: AppColors.textHeading),
                ),
              ],
            ),
          ),
          if (state.isParent && _link != null) ...[
            const SizedBox(height: 10),
            _LinkedChildRow(
              name: _link!.counterpart.name,
              phone: _link!.counterpart.phone ?? _link!.counterpart.email,
              avatarIndex: _link!.counterpart.avatarIndex,
              onEdit: () => context.push(AppRoutes.accountLinking),
            ),
          ],
          const SizedBox(height: 24),
          // Карточка меню: пилюли по фигме + «Выйти из аккаунта».
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MenuPill(
                  label: state.isParent ? 'Статистика' : 'Достижения',
                  onTap: () {
                    if (state.isParent) {
                      context.push(AppRoutes.ratingStatistics);
                    } else {
                      context.push(AppRoutes.rewards);
                    }
                  },
                ),
                const SizedBox(height: 10),
                _MenuPill(
                  label: 'Связка аккаунтов',
                  onTap: () => context.push(AppRoutes.accountLinking),
                ),
                const SizedBox(height: 10),
                _MenuPill(
                  label: 'Подписка',
                  gradientBorder: highlightSubscription,
                  showBadge: highlightSubscription,
                  onTap: _openSubscription,
                ),
                const SizedBox(height: 10),
                _MenuPill(
                  label: 'Настройки',
                  onTap: () => context.push(AppRoutes.settings),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _logout,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Выйти из аккаунта',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.dangerLight,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Пункт меню профиля из фигмы: пилюля 60px r=20 с центрированным текстом.
/// У «Подписки» без оплаты — градиентная рамка и красный бейдж (раз в день).
class _MenuPill extends StatelessWidget {
  const _MenuPill({
    required this.label,
    required this.onTap,
    this.gradientBorder = false,
    this.showBadge = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool gradientBorder;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      height: gradientBorder ? 56 : 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(gradientBorder ? 18 : 20),
        border: gradientBorder ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
      ),
    );

    final pill = gradientBorder
        ? Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: inner,
          )
        : inner;

    return GestureDetector(
      onTap: onTap,
      child: showBadge
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                pill,
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            )
          : pill,
    );
  }
}

/// Мини-карточка привязанного ребёнка/наставника из фигмы: аватар 40px,
/// имя + телефон, карандаш редактирования справа.
class _LinkedChildRow extends StatelessWidget {
  const _LinkedChildRow({
    required this.name,
    required this.phone,
    required this.avatarIndex,
    required this.onEdit,
  });

  final String name;
  final String phone;
  final int avatarIndex;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          AppAvatar(index: avatarIndex, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.cardTitle),
                Text(phone, style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 20, color: AppColors.textHeading),
          ),
        ],
      ),
    );
  }
}
