import 'package:flutter/material.dart';

class DriverColors {
  // Brand & Accents
  static const Color primaryOrange = Color(0xFFFF521B);
  static const Color primaryOrangeLight = Color(0xFFFF6D3E);
  
  // Status Colors
  static const Color onlineGreen = Color(0xFF10B981);
  static const Color onlineGreenGlow = Color(0x3310B981);
  static const Color offlineRed = Color(0xFFEF4444);
  static const Color enRouteAmber = Color(0xFFF59E0B);
  static const Color navBlue = Color(0xFF2563EB);

  // Backgrounds & Surfaces
  static const Color bgDark = Color(0xFF0B1320);
  static const Color cardDark = Color(0xFF152238);
  static const Color cardSurface = Color(0xFF1E293B);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardWhite = Colors.white;

  // Text & Borders
  static const Color textMain = Color(0xFF0F172A);
  static const Color textSub = Color(0xFF64748B);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Gradients
  static const LinearGradient driverGradient = LinearGradient(
    colors: [primaryOrange, primaryOrangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient onlineGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
