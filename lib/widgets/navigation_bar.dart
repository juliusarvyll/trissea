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
  int currentPageIndex = 4; // Start with index 0 as the default selected button

  void _navigateToMap(BuildContext context) {
    Navigator.of(context).pushNamed(MapScreen.route);
    setState(() {
      currentPageIndex = 0; // Set index to 0 when "Home" is selected
    });
  }

  void _navigateToTrips(BuildContext context) {
    Navigator.of(context).pushNamed(TripsScreen.route);
    setState(() {
      currentPageIndex = 1; // Set index to 1 when "Trips" is selected
    });
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).pushNamed(ProfileScreen.route);
    setState(() {
      currentPageIndex = 2; // Set index to 2 when "Profile" is selected
    });
  }

  TextStyle _labelTextStyle(int index) {
    return TextStyle(
      fontSize: 12,
      color: currentPageIndex == index ? Colors.blue : Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          buildNavItem(0, Icons.home, 'Home', _navigateToMap),
          buildNavItem(1, Icons.navigation_rounded, 'Trips', _navigateToTrips),
          buildNavItem(2, Icons.person, 'Profile', _navigateToProfile),
        ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: currentPageIndex == index ? Colors.blue : Colors.grey,
          ),
          Text(
            label,
            style: _labelTextStyle(index),
          ),
        ],
      ),
    );
  }
}
