import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/screens/driver_main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Premium Light Theme system bars: crisp white navigation and dark status icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const TowingDriverApp());
}

class TowingDriverApp extends StatelessWidget {
  const TowingDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roacs Towing - Driver Partner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.lightTheme(context), // Enforces premium light theme as instructed
      themeMode: ThemeMode.light,
      home: const DriverMainShell(),
    );
  }
}
