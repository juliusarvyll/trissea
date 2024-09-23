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
    // Get device width and height for responsiveness
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate padding and sizing based on screen width
    final double padding = MediaQuery.of(context).size.width * 0.05;
    final double iconSize = MediaQuery.of(context).size.width * 0.07; // Scales icon size to 7% of screen width
    final double textFontSize = MediaQuery.of(context).size.width * 0.04; // Font size 4% of screen width

    User? user = FirebaseAuth.instance.currentUser;
    String userName = user != null ? user.displayName ?? 'User' : 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trissea', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green, // Set the AppBar background to green
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic greeting text with responsive padding
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.02, bottom: screenHeight * 0.01),
              child: Text(
                'Hello, $userName', 
                style: TextStyle(fontSize: textFontSize * 1.5, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),

            // Navigation buttons fitted across the screen
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavIconButton(context, 'Map', Icons.directions_car, OnboardingScreen.route, iconSize, textFontSize),
                _buildNavIconButton(context, 'QR Code', Icons.qr_code_scanner, QRScannerScreen.route, iconSize, textFontSize),
                if (user != null) 
                  _buildNavIconButton(context, 'View Trips', Icons.map, ProfileScreen.route, iconSize, textFontSize),
              ],
            ),
            Divider(thickness: 1),

            // Title above TerminalScreen
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
              child: Text(
                'Available Terminals',
                style: TextStyle(fontSize: textFontSize * 1.2, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),

            // TerminalScreen content adjusted for responsive height
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.01),
                child: const TerminalScreen(), // Terminal functionality
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Responsive Navigation Icon Button
  Widget _buildNavIconButton(BuildContext context, String label, IconData icon, String route, double iconSize, double fontSize) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: Colors.green), // Icon color set to green
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: fontSize, color: Colors.green), // Text color set to green
            ),
          ],
        ),
      ),
    );
  }
}
