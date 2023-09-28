import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import '../../models/map_action.dart';
import '../../models/trip_model.dart';
import '../../providers/map_provider.dart';
import '../../services/database_service.dart';

class SearchDriver extends StatelessWidget {
  const SearchDriver({
    Key? key,
    required this.mapProvider,
  }) : super(key: key);

  final MapProvider mapProvider;

  void _cancelTrip() {
    final DatabaseService dbService = DatabaseService();
    final Trip ongoingTrip = mapProvider.ongoingTrip!;
    ongoingTrip.canceled = true;
    dbService.updateTrip(ongoingTrip);
    mapProvider.cancelTrip();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: mapProvider.mapAction == MapAction.searchDriver,
      child: Positioned.fill(
        top: 620,
        child: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 255, 255, 255), // White background
          ),
          padding:
              const EdgeInsets.all(10), // Reduced padding for a sleeker look
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 15, // Adjust font size as needed
              fontWeight: FontWeight.bold,
              color:
                  Colors.black26, // Change text color to gray or another color
            ),
            child: AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText('Searching for a Driver...'),
              ],
              totalRepeatCount: 20, // Play animation once
            ),
          ),
        ),
      ),
    );
  }
}
