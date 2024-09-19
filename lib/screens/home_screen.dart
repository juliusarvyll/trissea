import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trissea/screens/onboarding_screen.dart';
import 'package:trissea/screens/profile_screen.dart';
import 'package:trissea/screens/qr_scanner_screen.dart';
import 'package:trissea/screens/terminal_screen.dart';

class TrisseaHomeScreen extends StatelessWidget {
  const TrisseaHomeScreen({Key? key}) : super(key: key);
  static const String route = '/homepage';

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String userName = user != null ? user.displayName ?? 'User' : 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trissea', style: TextStyle(color: Colors.black)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme for background color
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $userName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 40, // horizontal space between buttons
              runSpacing: 20, // vertical space between rows
              children: [
                _buildButtonWithLabel(context, 'Ride', Theme.of(context).colorScheme.primary, OnboardingScreen.route, Icons.directions_car),
                _buildButtonWithLabel(context, 'Terminal', Theme.of(context).colorScheme.primary, TerminalScreen.route, Icons.business),
                _buildButtonWithLabel(context, 'QR Code', Theme.of(context).colorScheme.primary, QRScannerScreen.route, Icons.qr_code_scanner),
                if (user != null)
                  _buildButtonWithLabel(context, 'View Trips', Colors.blue, ProfileScreen.route, Icons.map),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, Color color, String route, IconData icon) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, route),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(40, 80), // Fixed size for all buttons
        backgroundColor: color, // Use theme color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Icon(icon, color: Colors.white, size: 36), // Only icon in the button
    );
  }

  Widget _buildButtonWithLabel(BuildContext context, String text, Color color, String route, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildButton(context, color, route, icon), // The button
        SizedBox(height: 8), // Space between button and text
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.black)), // Text below the button
      ],
    );
  }
}

