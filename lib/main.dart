import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/map_provider.dart';
import 'providers/user_provider.dart';
import 'screens/map_screen.dart';
import 'screens/login_signup_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/trips_screen.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const TaxiApp());
}

class TaxiApp extends StatefulWidget {
  const TaxiApp({Key? key}) : super(key: key);
  static const String route = '/taxiapp';

  @override
  _TaxiAppState createState() => _TaxiAppState();
}

class _TaxiAppState extends State<TaxiApp> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    OnboardingScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    print("current user:$user");

    if (user != null) {
      // If logged in, set the initial screen to MapScreen
      const MapScreen();
    } else {
      // If not logged in, set the initial screen to LoginSignupScreen

      const LoginSignupScreen();
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: UserProvider.initialize()),
        ChangeNotifierProvider.value(value: MapProvider())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Taxi App',
        theme: theme,
        home: Scaffold(
          body: _screens.elementAt(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor:
                Colors.blue, // Set the color for the selected icon
            unselectedItemColor:
                Colors.grey, // Set the color for unselected icons
          ),
        ),
        routes: {
          TaxiApp.route: (_) => const TaxiApp(),
          MapScreen.route: (_) => const MapScreen(),
          LoginSignupScreen.route: (_) => const LoginSignupScreen(),
          TripsScreen.route: (_) => const TripsScreen(),
          ProfileScreen.route: (_) => const ProfileScreen(),
        },
      ),
    );
  }
}
