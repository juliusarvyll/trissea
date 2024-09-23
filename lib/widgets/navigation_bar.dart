import 'package:flutter/material.dart';
import '../screens/map_screen.dart';
import '../screens/trips_screen.dart';
import '../screens/profile_screen.dart';

class NavigationExample extends StatefulWidget {
  const NavigationExample({Key? key}) : super(key: key);

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0; // Default selected button index

  void _navigateToMap(BuildContext context) {
    Navigator.of(context).pushNamed(MapScreen.route);
    setState(() {
      currentPageIndex = 0;
    });
  }

  void _navigateToTrips(BuildContext context) {
    Navigator.of(context).pushNamed(TripsScreen.route);
    setState(() {
      currentPageIndex = 1;
    });
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).pushNamed(ProfileScreen.route);
    setState(() {
      currentPageIndex = 2;
    });
  }

  TextStyle _labelTextStyle(int index) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: currentPageIndex == index ? Colors.green : Colors.grey[700],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, -1), // Shadow position
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            buildNavItem(0, Icons.home, 'Home', _navigateToMap),
            buildNavItem(1, Icons.navigation_rounded, 'Trips', _navigateToTrips),
            buildNavItem(2, Icons.person, 'Profile', _navigateToProfile),
          ],
        ),
      ),
    );
  }

  Widget buildNavItem(int index, IconData icon, String label, Function onTap) {
    return InkWell(
      onTap: () {
        if (currentPageIndex != index) {
          onTap(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: currentPageIndex == index ? Colors.green : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: _labelTextStyle(index),
            ),
          ],
        ),
      ),
    );
  }
}
