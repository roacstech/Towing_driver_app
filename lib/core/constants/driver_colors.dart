import 'package:flutter/material.dart';

/// Premium mobility design tokens for the Towing Driver application.
/// Strictly crafted around modern, minimal, light-theme aesthetics:
/// - Crisp white and soft off-white surfaces
/// - Deep navy typography for maximum legibility in direct sunlight
/// - Electric blue for navigation polylines and map indicators
/// - Vibrant emerald green for job acceptance & online state
/// - Signal red for rejections and urgent road hazard alerts
/// - Multi-layered realistic shadows with soft ambient falloff
class DriverColors {
  DriverColors._();

  // Backgrounds & Surfaces (Light Theme)
  static const Color scaffoldBg = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF1F5F9);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceBorder = Color(0xFFE2E8F0);
  static const Color surfaceBorderLight = Color(0xFFF1F5F9);

  // Typography - Deep Navy Hierarchy
  static const Color navy900 = Color(0xFF0B1527);
  static const Color textNavy = Color(0xFF0B1527);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Electric Blue - Map routes, focus markers, and selected states
  static const Color electricBlue = Color(0xFF2563EB);
  static const Color electricBlueLight = Color(0xFF3B82F6);
  static const Color electricBlueDark = Color(0xFF1D4ED8);
  static const Color blueTint = Color(0xFFEFF6FF);
  static const Color blueBorder = Color(0xFFBFDBFE);

  // Vibrant Emerald Green - Acceptance, online beacon, earnings
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color greenTint = Color(0xFFECFDF5);
  static const Color greenBorder = Color(0xFFA7F3D0);

  // Alert Red - Rejection, urgent priority hazards, highway shoulder
  static const Color alertRed = Color(0xFFEF4444);
  static const Color alertRedDark = Color(0xFFDC2626);
  static const Color redTint = Color(0xFFFEF2F2);
  static const Color redBorder = Color(0xFFFECACA);

  // Amber / Warm Accents - Ratings, warnings, medium urgency
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color amberTint = Color(0xFFFFFBEB);
  static const Color amberBorder = Color(0xFFFDE68A);

  // UI Design Mockup Tokens
  static const Color statusOnlineBg = Color(0xFFDCFCE7);
  static const Color statusOnlineText = Color(0xFF15803D);
  static const Color statusOnlineDot = Color(0xFF22C55E);
  static const Color passBtnBg = Color(0xFFFEE2E2);
  static const Color passBtnText = Color(0xFFEF4444);
  static const Color acceptBtnGreen = Color(0xFF10B981);
  static const Color acceptBtnGreenDark = Color(0xFF059669);
  static const Color highPayPurple = Color(0xFF8B5CF6);
  static const Color tagLavenderBg = Color(0xFFF3E8FF);
  static const Color tagLavenderText = Color(0xFF7C3AED);
  static const Color tagSlateBg = Color(0xFFF1F5F9);
  static const Color tagSlateText = Color(0xFF475569);

  // Backward compatibility aliases
  static const Color primaryOrange = Color(0xFF2563EB);
  static const Color primaryOrangeLight = Color(0xFF3B82F6);
  static const Color onlineGreen = Color(0xFF10B981);
  static const Color onlineGreenGlow = Color(0x3310B981);
  static const Color offlineRed = Color(0xFFEF4444);
  static const Color enRouteAmber = Color(0xFFF59E0B);
  static const Color navBlue = Color(0xFF2563EB);
  static const Color bgDark = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFF1F5F9);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardWhite = Colors.white;
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSub = Color(0xFF475569);
  static const Color borderDark = Color(0xFFE2E8F0);

  // Realistic Soft Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0C0B1527),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x060B1527),
      blurRadius: 6,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> activeCardShadow = [
    BoxShadow(
      color: Color(0x160B1527),
      blurRadius: 28,
      offset: Offset(0, 12),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x080B1527),
      blurRadius: 10,
      offset: Offset(0, 3),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> floatingControlShadow = [
    BoxShadow(
      color: Color(0x140B1527),
      blurRadius: 18,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> bottomSheetShadow = [
    BoxShadow(
      color: Color(0x140B1527),
      blurRadius: 32,
      offset: Offset(0, -8),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> greenAcceptGlow = [
    BoxShadow(
      color: Color(0x4010B981),
      blurRadius: 24,
      offset: Offset(0, 6),
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> redRejectGlow = [
    BoxShadow(
      color: Color(0x40EF4444),
      blurRadius: 24,
      offset: Offset(0, 6),
      spreadRadius: 2,
    ),
  ];
}
