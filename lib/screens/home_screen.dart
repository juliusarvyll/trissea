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
        backgroundColor: Colors.white,
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
              spacing: 10, // horizontal space between buttons
              runSpacing: 10, // vertical space between buttons
              children: [
                _buildButton(context, 'Book a Ride', Colors.green, OnboardingScreen.route),
                _buildButton(context, 'Book a Terminal', Colors.green, TerminalScreen.route),
                _buildButton(context, 'Scan QR Code', Colors.orange, QRScannerScreen.route),
                if (user != null)
                  _buildButton(context, 'View Trips', Colors.blue, ProfileScreen.route),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Color color, String route) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, route),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(150, 60),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 20, color: Colors.white)),
    );
  }
}

