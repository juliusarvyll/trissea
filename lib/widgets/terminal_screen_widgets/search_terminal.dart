import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/map_action.dart';
import '../../models/trip_model.dart';
import '../../providers/map_provider.dart';
import '../../services/database_service.dart';

class SearchTerminal extends StatelessWidget {
  const SearchTerminal({
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
    Size screenSize = MediaQuery.of(context).size;
    return Visibility(
      visible: mapProvider.mapAction == MapAction.searchTerminal,
      child: Positioned.fill(
        top: screenSize.height * 0.80,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [ // Loading spinner
              DefaultTextStyle(
                style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Searching for a Driver...',
                      speed: Duration(milliseconds: 100),
                    ),
                  ],
                  totalRepeatCount: 20,
                ),
              ),
              SizedBox(height: 10,),
              Text("Give drivers time to accept booking")
            ],
          ),
        ),
      ),
    );
  }
}
