import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import 'app_avatar.dart';

/// Ячейка выбора аватара: круг 100×100. Картинки уже сами по себе круглые
/// (с рамкой), поэтому для них клип — просто круг, без доп. скругления
/// контейнера (иначе получается двойное скругление — квадрат вокруг круга).
/// Выбранная — зелёная круговая обводка и чек-бейдж; "+"-плейсхолдер —
/// пунктирный круг без картинки.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.size,
    this.avatarIndex,
    this.selected = false,
    this.onTap,
    this.child,
  });

  final double size;
  final int? avatarIndex;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final hasImage = child == null && avatarIndex != null;

    final avatarContent = hasImage
        ? ClipOval(
            child: Image.asset(
              avatarAssets[avatarIndex! % avatarAssets.length],
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          )
        : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.textHeading),
            ),
            child: child,
          );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (hasImage && selected)
              Container(
                width: size,
                height: size,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.success, width: 2),
                  ),
                ),
                child: avatarContent,
              )
            else
              avatarContent,
            if (selected)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 18, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
