import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart' as user;
import '../providers/map_provider.dart';
import '../providers/user_provider.dart';
import '../screens/login_signup_screen.dart';
import '../screens/profile_screen.dart';
import '../routes/routes.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSideDrawer extends StatelessWidget {
  const CustomSideDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MapProvider mapProvider = Provider.of<MapProvider>(context, listen: false);
    final UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    final user.User? loggedUser = userProvider.loggedUser;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            GestureDetector(
              onTap: () {
                if (loggedUser != null) {
                  Navigator.of(context).pushNamed(ProfileScreen.route);
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  bottom: 20,
                  left: 16,
                ),
                color: Colors.green.shade800,
                child: loggedUser != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            loggedUser.email ?? 'Email not available',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
              ),
            ),
            // Buttons Section
            Expanded(
              child: Container(
                child: ListView(
                  children: [
                    _buildButtonTile(
                      context: context,
                      title: 'Home',
                      icon: Icons.home_rounded,
                      onTap: () {
                        mapProvider.stopListenToPositionStream();
                        if (ModalRoute.of(context)?.settings.name != Routes.onboarding) {
                          Navigator.of(context).pushReplacementNamed(Routes.onboarding);
                        }
                      },
                    ),
                    _buildButtonTile(
                      context: context,
                      title: 'History',
                      icon: Icons.history_rounded,
                      onTap: () {
                        Navigator.of(context).pushNamed(Routes.history);
                      },
                    ),
                    _buildButtonTile(
                      context: context,
                      title: 'Terminals',
                      customIcon: SvgPicture.asset(
                        'images/tricycle.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          Colors.green.shade800,
                          BlendMode.srcIn,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pushNamed(Routes.terminal);
                      },
                    ),
                    _buildButtonTile(
                      context: context,
                      title: 'Scan QR',
                      icon: Icons.qr_code_scanner,
                      onTap: () {
                        Navigator.of(context).pushNamed('/qr-scanner');
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Logout Button
            Container(
              padding: const EdgeInsets.all(20),
              child: _buildButtonTile(
                context: context,
                title: 'Logout',
                icon: Icons.exit_to_app_rounded,
                onTap: () async {
                  mapProvider.stopListenToPositionStream();
                  userProvider.clearUser();
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    LoginSignupScreen.route,
                    (Route<dynamic> route) => false,
                  );
                },
                isLogout: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonTile({
    required BuildContext context,
    required String title,
    IconData? icon,
    Widget? customIcon,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: customIcon ?? Icon(
        icon,
        color: isLogout ? Colors.red : Colors.green.shade800,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : Colors.black87,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
