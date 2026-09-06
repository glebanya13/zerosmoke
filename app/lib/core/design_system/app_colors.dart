import 'package:flutter/material.dart';

/// Colors extracted directly from the Figma file (node fills/text styles).
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color screenBackground = Color(0xFFF3F3F3);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color skyBackgroundTop = Color(0xFFCAE7FF);
  static const Color skyBackgroundBottom = Color(0xFFEAF6FD);
  static const Color parentGradientBottom = Color(0xFFD1E2FF);

  // Primary blue family
  static const Color primaryLight = Color(0xFF7CD1F8);
  static const Color primary = Color(0xFF26B5FF);
  static const Color primaryDark = Color(0xFF26B5FF);
  static const Color primaryDeep = Color(0xFF1183D6);

  // Purple accent
  static const Color accentPurpleLight = Color(0xFFB1B1FF);
  static const Color accentPurple = Color(0xFF8B8FF0);
  static const Color pricePurple = Color(0xFF6969BD);

  // Status / semantic
  static const Color success = Color(0xFF33AE67);
  static const Color successLight = Color(0xFFCEF5C7);
  static const Color inviteGreen = Color(0xFF24C86A);
  static const Color danger = Color(0xFFE74C3C);
  static const Color dangerLight = Color(0xFFFF8A7A);
  static const Color warning = Color(0xFFF4B400);
  static const Color warningLight = Color(0xFFF8CE55);
  static const Color starYellow = Color(0xFFFDD835);
  static const Color rankYellow = Color(0xFFFFFF8D);
  static const Color goldStroke = Color(0xFFFAD23F);
  static const Color selectedAnswerFill = Color(0xFFEAF8FF);

  // Text
  static const Color textPrimary = Color(0xFF0C0D0D);
  static const Color textSecondary = Color(0xFF8C969D);
  static const Color textGrey = Color(0xFF777777);
  static const Color textDark = Color(0xFF444444);
  static const Color textMuted = Color(0xFFA09EAE);
  static const Color textHeading = Color(0xFF3FB5F2);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Borders / dividers
  static const Color border = Color(0xFF8C969D);
  static const Color borderLight = Color(0xFFD9D9D9);
  static const Color divider = Color(0xFFF0F0F0);
  static const Color disabled = Color(0xFFCCCCCC);
  static const Color toggleOff = Color(0xFFACA6A6);
  static const Color toggleTrack = Color(0xFFD1E2FF);

  // Bottom navigation tab colors
  static const Color navHome = Color(0xFF88E9B1);
  static const Color navTests = Color(0xFFFF8A7A);
  static const Color navRating = Color(0xFFFAD23F);
  static const Color navProfile = Color(0xFF3FB5F2);

  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFFA3A3FF), Color(0xFF26B5FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Node / test tile gradients from Figma
  static const Gradient nodeBlueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF62CAFF), Color(0xFF38A0D5)],
  );
  static const Gradient nodeGreenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF73FCAE), Color(0xFF33AE67)],
  );
  static const Gradient nodePurpleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFA3A3FF), Color(0xFF6969BD)],
  );
  static const Gradient nodeOrangeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFBB764), Color(0xFFF38B4A)],
  );
  static const Gradient progressCardGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFBFE2FE), Color(0xFFD7E1D1)],
  );
  static const Gradient parentHomeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFD1E2FF)],
  );
  static const Gradient ratingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFCAE7FF), Color(0xFFFFFFFF)],
  );

  // Legacy aliases still referenced by mock data / older widgets.
  static const Color nodeGreen = Color(0xFF33AE67);
  static const Color nodeBlue = Color(0xFF62CAFF);
  static const Color nodePurple = Color(0xFF6969BD);
  static const Color nodeOrange = Color(0xFFF38B4A);
}
