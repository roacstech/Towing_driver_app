import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/driver_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme(BuildContext context) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      Theme.of(context).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: DriverColors.bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DriverColors.primaryOrange,
        primary: DriverColors.primaryOrange,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DriverColors.bgDark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: DriverColors.primaryOrange,
        primary: DriverColors.primaryOrange,
        surface: DriverColors.cardDark,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: DriverColors.bgDark,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
