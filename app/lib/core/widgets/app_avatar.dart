import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';

/// Illustrated character avatars from the design file. Each asset is
/// already a circular crop with its own coloured ring baked in — do NOT
/// wrap these in another rounded shape/border (double-rounding); just
/// clip to a plain circle matching the artwork's own edge.
const List<String> avatarAssets = [
  'assets/images/avatars/00_boy_green.png',
  'assets/images/avatars/01_girl_pigtails_pink.png',
  'assets/images/avatars/02_boy_glasses_blue.png',
  'assets/images/avatars/03_girl_blonde_lavender.png',
  'assets/images/avatars/04_boy_cap_red.png',
  'assets/images/avatars/05_girl_ponytail_purple.png',
  'assets/images/avatars/06_boy_curly_green.png',
  'assets/images/avatars/07_girl_black_yellow.png',
  'assets/images/avatars/08_dragon_green.png',
  'assets/images/avatars/09_robot_purple.png',
  'assets/images/avatars/10_star_yellow.png',
  'assets/images/avatars/11_monster_blue.png',
];

/// Круглый аватар (картинка уже сама по себе круг с рамкой) с опциональной
/// подписью процента прогресса снизу.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.index = 0,
    this.size = 48,
    this.percent,
  });

  final int index;
  final double size;
  final int? percent;

  @override
  Widget build(BuildContext context) {
    final asset = avatarAssets[index % avatarAssets.length];
    final avatar = ClipOval(
      child: Image.asset(asset, width: size, height: size, fit: BoxFit.cover),
    );

    if (percent == null) return avatar;

    return SizedBox(
      width: size,
      height: size + 14,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.textHeading,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '$percent%',
                style: TextStyle(
                  fontSize: size >= 72 ? 13 : 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
