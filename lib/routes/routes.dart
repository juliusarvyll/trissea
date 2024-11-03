import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';
import '../screens/login_signup_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/terminal_screen.dart';
import '../screens/trips_screen.dart';
import '../screens/map_screen.dart';
class Routes {
  static const String onboarding = '/onboarding';
  static const String loginSignup = '/login-signup';
  static const String main = '/main';
  static const String qrScanner = '/qr-scanner';
  static const String profile = '/profile';
  static const String history = '/history';
  static const String terminal = '/terminal';
  static const String mapscreen = '/mapscreen';
  
  static Map<String, Widget Function(BuildContext)> getRoutes() {
    return {
      onboarding: (_) => const OnboardingScreen(),
      loginSignup: (_) => const LoginSignupScreen(),
      qrScanner: (_) => const QRScannerScreen(),
      profile: (_) => const ProfileScreen(),
      terminal: (_) => const TerminalScreen(),
      history: (_) => const TripsScreen(),
      mapscreen: (_) => const MapScreen(),
    };
  }
} 