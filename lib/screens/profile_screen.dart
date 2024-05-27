import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trissea/providers/user_provider.dart';
import 'package:trissea/screens/login_signup_screen.dart';
import 'package:trissea/screens/profile_screen_edit.dart';
import 'package:trissea/screens/trips_screen.dart';
import 'package:trissea/widgets/custom_side_drawer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  static const String route = '/profile';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider.initialize(),
      child: _ProfileScreen(),
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

  void _editProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const ProfileEditScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {

    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Color.fromARGB(255, 83, 83, 83)),),
        backgroundColor: Colors.black,
      ),
      drawer: const CustomSideDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 65,
              backgroundImage: AssetImage("assets/6195145.jpg"),
            ),
            const SizedBox(height: 20),
            Text(
              firebaseUser?.displayName ?? 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              firebaseUser?.email ?? 'N/A',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Trip History',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            const Expanded(
              child: TripsScreen(), // Custom trip history widget
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _editProfile(context);
              },
              child: const Text('Edit Profile', style: TextStyle(color: Colors.white),),
            ),
            ElevatedButton(
              onPressed: () {
                _logout(context);
              },
              child: const Text('Logout', style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}
