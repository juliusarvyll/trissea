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
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey[800],
      ),
      drawer: const CustomSideDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 65,
                    backgroundImage: AssetImage("assets/6195145.jpg"),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(height: 10),

                  // User Info
                  Text(
                    firebaseUser?.displayName ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    firebaseUser?.email ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Menu Options
            Expanded(
              child: ListView(
                children: [
                  _buildMenuOption(
                    context,
                    'Edit Profile',
                    Icons.edit,
                    () => _editProfile(context),
                  ),
                  const SizedBox(height: 10),
                  _buildMenuOption(
                    context,
                    'Trip History',
                    Icons.history,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const TripsScreen()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMenuOption(
                    context,
                    'Logout',
                    Icons.logout,
                    () => _logout(context),
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Menu Option Widget
  Widget _buildMenuOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.black54,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }
}
