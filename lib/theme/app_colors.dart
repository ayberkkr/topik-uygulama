import 'package:flutter/material.dart';

class AppColors {
  // Gece modu yeşil yerlerin rengi: #800000
  static const Color darkAccent = Color(0xFF800000);
  static const Color darkOnAccent = Colors.white;

  // Gündüz modu yeşil yerlerin rengi: #FFDEAD
  static const Color lightAccent = Color(0xFFFFDEAD);
  static const Color lightOnAccent = Color(0xFF2D1810);

  static Color accent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkAccent
        : lightAccent;
  }

  static Color onAccent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkOnAccent
        : lightOnAccent;
  }

  static Color soft(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4A1010)
        : const Color(0xFFFFF3E3);
  }

  static Color card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF242424)
        : Colors.white;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3D3D3D)
        : const Color(0xFFE2E2E2);
  }

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF141414)
        : const Color(0xFFF9F9FB);
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1F1F1F)
        : const Color(0xFFFFFFFF);
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1E1E1E);
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFAAAAAA)
        : const Color(0xFF6B6B6B);
  }
}
