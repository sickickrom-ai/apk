import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constants/app_constants.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/browser_screen.dart';
import 'presentation/screens/offline_screen.dart';
import 'presentation/screens/error_screen.dart';

/// ═══════════════════════════════════════════════════════════════════
/// REDE CANAIS BROWSER - Main Entry Point
/// ═══════════════════════════════════════════════════════════════════
/// A lightweight browser app that loads https://redecanais.win
/// Built with Flutter + flutter_inappwebview
/// 
/// This app acts solely as a browser wrapper and does not modify
/// or copy the website's content in any way.
/// ═══════════════════════════════════════════════════════════════════

void main() {
  // Ensure Flutter plugins are initialized before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (both portrait and landscape)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    const RedeCanaisBrowser(),
  );
}

class RedeCanaisBrowser extends StatelessWidget {
  const RedeCanaisBrowser({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      // Dark theme to match the website aesthetic
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: AppConstants.primaryColor,
          secondary: AppConstants.accentColor,
          surface: AppConstants.backgroundColor,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppConstants.accentColor,
        ),
      ),
      // App routes
      initialRoute: AppConstants.routeSplash,
      routes: {
        AppConstants.routeSplash: (context) => const SplashScreen(),
        AppConstants.routeBrowser: (context) => const BrowserScreen(),
        AppConstants.routeOffline: (context) => const OfflineScreen(),
        AppConstants.routeError: (context) => const ErrorScreen(),
      },
    );
  }
}
