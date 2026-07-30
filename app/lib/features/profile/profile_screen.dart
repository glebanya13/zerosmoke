import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
  LinkInfo? _link;

  @override
  void initState() {
    super.initState();
    _loadLink();
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
                  gradientBorder: true,
                  showBadge: true,
                  onTap: () => context.push(AppRoutes.subscription),
                ),
                const SizedBox(height: 10),
                _MenuPill(
                  label: 'Настройки',
                  onTap: () => context.push(AppRoutes.settings),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _logout,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Выйти из аккаунта',
                        textAlign: TextAlign.center,
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

/// Пункт меню профиля из фигмы: пилюля 60px r=20 с центрированным текстом
/// SF Regular 20; у «Подписки» — градиентная рамка и красный бейдж.
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
