import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trissea/screens/terminal_screen.dart';
import '../models/user_model.dart' as user;
import '../providers/map_provider.dart';
import '../providers/user_provider.dart';
import '../screens/login_signup_screen.dart';
import '../screens/map_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/trips_screen.dart';

class CustomSideDrawer extends StatelessWidget {
  const CustomSideDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MapProvider mapProvider = Provider.of<MapProvider>(context, listen: false);
    final UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    final user.User? loggedUser = userProvider.loggedUser;

    return Drawer(
      child: Column(
        children: [
          // Header Section
          GestureDetector(
            onTap: () {
              if (loggedUser != null) {
                Navigator.of(context).pushNamed(ProfileScreen.route);
              }
            },
            child: loggedUser != null
                ? UserAccountsDrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.green.shade800,
                    ),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.green.shade800,
                      ),
                    ),
                    accountName: Text(
                      FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    accountEmail: Text(
                      loggedUser.email ?? 'Email not available',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  )
                : Container(
                    height: 200,
                    color: Colors.green.shade800,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          // Buttons Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildButtonTile(
                  context: context,
                  title: 'Home',
                  icon: Icons.home,
                  onTap: () async {
                    mapProvider.stopListenToPositionStream();
                    Navigator.of(context).pushReplacementNamed(MapScreen.route);
                  },
                ),
                const SizedBox(height: 10),
                _buildButtonTile(
                  context: context,
                  title: 'History',
                  icon: Icons.history,
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed(TripsScreen.route);
                  },
                ),
                const SizedBox(height: 10),
                _buildButtonTile(
                  context: context,
                  title: 'Terminals',
                  icon: Icons.build,
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed(TerminalScreen.route);
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildButtonTile(
              context: context,
              title: 'Logout',
              icon: Icons.exit_to_app,
              onTap: () async {
                mapProvider.stopListenToPositionStream();
                userProvider.clearUser();
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginSignupScreen.route,
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.green.shade800,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
