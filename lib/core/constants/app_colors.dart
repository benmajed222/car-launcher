import 'package:flutter/material.dart';

/**
 * Automotive Dark Luxury Cockpit Palette.
 * Tailored for high-contrast visibility on the 10.1 inch 1280x720 IPS display.
 */
class AppColors {
  // Backgrounds & Surfaces
  static const Color background = Color(0xFF070B12);          // Deep cockpit midnight
  static const Color surfaceCard = Color(0xFF0C1322);          // Rich navy slate card
  static const Color surfaceCardElevated = Color(0xFF141F36);  // Elevated card
  static const Color cardBorder = Color(0xFF1B2A47);           // Neon subtle edge border
  static const Color cardBorderActive = Color(0xFF28406C);

  // Accents & Signals
  static const Color primaryCyan = Color(0xFF00E5FF);          // Vibrant Speedo Cyan
  static const Color primaryEmerald = Color(0xFF00E676);       // RPM & Operational Green
  static const Color accentGold = Color(0xFFFFB300);           // Islamic Prayer Amber/Gold
  static const Color warningAmber = Color(0xFFFF9100);         // Caution Amber
  static const Color dangerRed = Color(0xFFFF3D00);            // Redline / Critical Alert
  static const Color successGreen = Color(0xFF00E676);         // GPS fix / Status green
  static const Color carPlayBlue = Color(0xFF2979FF);          // CarPlay gradient blue
  static const Color carPlayGreen = Color(0xFF00E676);

  // Typography & Neutrals
  static const Color textPrimary = Color(0xFFF0F5FF);
  static const Color textSecondary = Color(0xFF8899B8);
  static const Color textMuted = Color(0xFF4C5D7D);
  static const Color divider = Color(0xFF16233B);

  // Glows
  static const Color overlayDark = Color(0xD9070B12);
  static const Color glowCyan = Color(0x3300E5FF);
  static const Color glowGreen = Color(0x3300E676);
  static const Color glowGold = Color(0x33FFB300);
}
