import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:trissea/screens/home_screen.dart';
import 'package:trissea/screens/profile_screen.dart';
import '../models/user_model.dart' as user;
import '../providers/map_provider.dart';
import '../providers/user_provider.dart';
import '../screens/login_signup_screen.dart';

class CustomSideDrawer extends StatelessWidget {
  const CustomSideDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MapProvider mapProvider = Provider.of<MapProvider>(
      context,
      listen: false,
    );
    final UserProvider userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    );
    final user.User? loggedUser = userProvider.loggedUser;

    return Drawer(
      child: Column(
        children: [
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
                      FirebaseAuth.instance.currentUser!.displayName.toString(),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    accountEmail: Text(loggedUser.email!),
                  )
                : Container(
                    height: 200,
                    color: Colors.green.shade800,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          // _buildButtonTile(
          //   context: context,
          //   title: 'Home',
          //   icon: Icons.home_rounded,
          //   onTap: () => Navigator.of(context).pushNamed(
          //     TrisseaHomeScreen.route,
          //   ),
          // ),
          _buildButtonTile(
            context: context,
            title: 'Logout',
            icon: Icons.exit_to_app,
            onTap: () {
              mapProvider.stopListenToPositionStream();
              userProvider.clearUser();
              Navigator.of(context).pushNamedAndRemoveUntil(
                LoginSignupScreen.route,
                (Route<dynamic> route) => false,
              );
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButtonTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Function() onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      leading: Icon(
        icon,
        color: Colors.green.shade800,
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
