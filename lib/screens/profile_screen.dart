import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trissea/providers/user_provider.dart'; // Import UserProvider
import 'package:trissea/screens/login_signup_screen.dart';
import 'package:trissea/models/user_model.dart' as user;
import 'trips_screen.dart'; // Import the TripsScreen widget

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  static const String route = '/profile';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider.initialize(), // Initialize UserProvider
      child:
          _ProfileScreen(), // Create a separate widget for the screen content
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  void _logout(BuildContext context) {
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);

    userProvider.clearUser();

    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginSignupScreen.route,
      (Route<dynamic> route) => false,
    );

    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(
      context,
      listen: true, // Listen for changes
    );

    final user.User? loggedUser = userProvider.loggedUser;
    print('user: $loggedUser');
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 65,
                  backgroundImage: AssetImage("assets/6195145.jpg"),
                ),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  loggedUser?.passengerName ?? 'N/A',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 26),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  loggedUser?.email ?? 'N/A',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'Trip History',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const SizedBox(
                  height: 200, // Set a specific height for the trip history
                  child: TripsScreen(), // Use the TripsScreen widget here
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () {
                    _logout(context);
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
