import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trissea/screens/map_screen.dart';
import 'package:trissea/screens/qr_scanner_screen.dart';
import 'package:trissea/screens/search_bar.dart';
import 'package:trissea/screens/terminal_screen.dart';
import 'providers/map_provider.dart';
import 'providers/user_provider.dart';
import 'screens/login_signup_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const TaxiApp());
}

class TaxiApp extends StatelessWidget {
  const TaxiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider.initialize()),
        ChangeNotifierProvider(create: (_) => MapProvider())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'Trissea App',
        theme: theme,
        home: const MapScreen(), // Set your default home screen here
        routes: {
          MapScreen.route: (_) => const MapScreen(),
          SearchLocationWidget.route: (_) => const SearchLocationWidget(),
          OnboardingScreen.route: (_) => const OnboardingScreen(),
          LoginSignupScreen.route: (_) => const LoginSignupScreen(),
          TripsScreen.route: (_) => const TripsScreen(),
          ProfileScreen.route: (_) => const ProfileScreen(),
          TerminalScreen.route: (_) => const TerminalScreen(),
          QRScannerScreen.route: (_) => const QRScannerScreen(),
        },
      ),
    );
  }
}
