import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/localization/driver_language_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/driver_login_screen.dart';
import 'features/auth/services/driver_auth_service.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/navigation/screens/driver_main_shell.dart';
import 'features/splash/screens/splash_screen.dart';

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

  // Initialize auth and language state
  await DriverAuthService().init();
  await DriverLanguageService().init();

  runApp(const TowingDriverApp());
}

class TowingDriverApp extends StatelessWidget {
  const TowingDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: DriverLanguageService().languageNotifier,
      builder: (context, currentLang, _) {
        return MaterialApp(
          key: ValueKey(currentLang),
          title: 'Roacs Towing - Driver Partner',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(context),
          darkTheme: AppTheme.lightTheme(context),
          themeMode: ThemeMode.light,
          routes: {
            '/dashboard': (_) => const DriverMainShell(),
            '/login': (_) => const DriverLoginScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/dashboard') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const DriverMainShell(),
              );
            }
            if (settings.name == '/login') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const DriverLoginScreen(),
              );
            }
            return null;
          },
          home: ValueListenableBuilder<bool>(
            valueListenable: DriverAuthService().isLoggedInNotifier,
            builder: (context, isLoggedIn, _) {
              return SplashScreen(
                nextScreen: isLoggedIn ? const DriverMainShell() : const DriverLoginScreen(),
              );
            },
          ),
        );
      },
    );
  }
}
