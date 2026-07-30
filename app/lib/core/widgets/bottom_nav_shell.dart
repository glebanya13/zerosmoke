import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_state.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_text_styles.dart';

/// Нижняя навигация из фигмы: белая панель со скруглением 30 сверху,
/// активная вкладка — цветной круг 52px, неактивные — 44px с
/// прозрачностью 70%, подписи Inter Medium 12. На «Тестах» — жёлтый
/// бейдж с числом новых тестов.
class BottomNavShell extends StatelessWidget {
  const BottomNavShell({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.child,
    this.testsBadgeCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget child;
  final int testsBadgeCount;

  @override
  Widget build(BuildContext context) {
    final isParent = context.watch<AppState>().isParent;

    final items = [
      const _NavItem('Главная', 'assets/images/icons/icon_nav_home.png', AppColors.navHome),
      // У ребёнка бейдж «3» вшит в ассет (джойстик); у родителя по фигме —
      // своя иконка mage:message-check-round-fill (галочка-сообщение).
      _NavItem(
        isParent ? 'Советы' : 'Тесты',
        isParent ? null : 'assets/images/icons/icon_nav_tests.png',
        AppColors.navTests,
        glyphAsset: 'assets/images/icons/icon_message_check.png',
        badgeCount: isParent ? 0 : testsBadgeCount,
      ),
      const _NavItem('Рейтинг', 'assets/images/icons/icon_nav_rating.png', AppColors.navRating),
      _NavItem(
        'Профиль',
        'assets/images/icons/icon_nav_profile.png',
        AppColors.navProfile,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          left: 40,
          right: 40,
          bottom: MediaQuery.of(context).padding.bottom > 0 ? 0 : 12,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 82,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final selected = i == currentIndex;
                final double circle = selected ? 52 : 44;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Opacity(
                    opacity: selected ? 1.0 : 0.7,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              if (item.iconAsset != null)
                                Image.asset(
                                  item.iconAsset!,
                                  width: circle,
                                  height: circle,
                                )
                              else
                                Container(
                                  width: circle,
                                  height: circle,
                                  decoration: BoxDecoration(
                                    color: item.color,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Image.asset(item.glyphAsset!, width: circle * 0.55),
                                ),
                              if (item.badgeCount > 0)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.dangerLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: Text(
                                      item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(item.label, style: AppTextStyles.navLabel),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(
    this.label,
    this.iconAsset,
    this.color, {
    this.glyphAsset,
    this.badgeCount = 0,
  });
  final String label;
  final String? iconAsset;
  final Color color;
  final String? glyphAsset;
  final int badgeCount;
}
