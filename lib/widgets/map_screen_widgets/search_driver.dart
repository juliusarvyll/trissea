import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    print('🔍 SearchDriver build - MapAction: ${mapProvider.mapAction}');
    Size screenSize = MediaQuery.of(context).size;
    
    return Visibility(
      visible: mapProvider.mapAction == MapAction.searchDriver,
      child: Positioned.fill(
        top: screenSize.height * 0.70,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultTextStyle(
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Searching for a Driver...',
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  totalRepeatCount: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Please wait while we connect you with a nearby driver",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => _cancelTrip(),
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text(
                  'Cancel Search',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cancelTrip() {
    print('❌ Canceling trip');
    final DatabaseService dbService = DatabaseService();
    if (mapProvider.ongoingTrip != null) {
      print('📝 Updating trip status to canceled');
      final Trip ongoingTrip = mapProvider.ongoingTrip!;
      ongoingTrip.canceled = true;
      dbService.updateTrip(ongoingTrip);
    }
    print('🔄 Resetting map state');
    mapProvider.cancelTrip();
  }
}
