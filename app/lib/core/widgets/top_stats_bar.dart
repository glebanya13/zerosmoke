import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_text_styles.dart';
import 'app_avatar.dart';

/// Верхний стат-бар Главной (ребёнок) из фигмы: белая карточка r=20,
/// аватар 60 с процентом, имя Inter Medium 20, 5 звёзд, очки «86/102»
/// синим, монеты жёлтым с иконкой и жёлтый круг ранга справа.
class TopStatsBar extends StatelessWidget {
  const TopStatsBar({
    super.key,
    required this.name,
    required this.percent,
    required this.stars,
    required this.coins,
    this.points = 86,
    this.pointsTotal = 102,
    this.rank = 1,
    this.avatarIndex = 0,
    this.onRatingTap,
    this.onTrophyTap,
    this.scale = 1.0,
  });

  final String name;
  final int percent;
  final int stars;
  final int coins;
  final int points;
  final int pointsTotal;
  final int rank;
  final int avatarIndex;
  /// Тап по рейтинговой части (аватар, звёзды, очки, монеты).
  final VoidCallback? onRatingTap;
  /// Тап по кругу справа (награды / место).
  final VoidCallback? onTrophyTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80 * scale,
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onRatingTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  AppAvatar(index: avatarIndex, percent: percent, size: 60 * scale),
                  SizedBox(width: 16 * scale),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.interName.copyWith(fontSize: 20 * scale),
                        ),
                        SizedBox(height: 4 * scale),
                        StarsRow(count: stars, size: 20 * scale),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$points/$pointsTotal',
                        style: AppTextStyles.points.copyWith(
                          height: 1.1,
                          fontSize: 20 * scale,
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      CoinsRow(coins: coins, iconSize: 24 * scale),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          GestureDetector(
            onTap: onTrophyTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36 * scale,
              height: 36 * scale,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.rankYellow,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontFamily: AppTextStyles.interFamily,
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ряд жёлтых звёзд из фигмы (noto-стиль, из ассетов).
class StarsRow extends StatelessWidget {
  const StarsRow({super.key, required this.count, this.total = 5, this.size = 20});

  final int count;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          total,
          (i) => Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Opacity(
              opacity: i < count ? 1 : 0.3,
              child: Image.asset(
                'assets/images/icons/icon_star_filled.png',
                width: size,
                height: size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// «86 🪙» — жёлтые монеты Manrope Bold 24 с иконкой монеты.
class CoinsRow extends StatelessWidget {
  const CoinsRow({super.key, required this.coins, this.iconSize = 28});

  final int coins;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$coins', style: AppTextStyles.coins.copyWith(height: 1.0)),
        const SizedBox(width: 4),
        Image.asset(
          'assets/images/icons/icon_coin.png',
          width: iconSize,
          height: iconSize,
        ),
      ],
    );
  }
}
