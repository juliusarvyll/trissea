import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/map_action.dart';
import '../../providers/map_provider.dart';

class TerminalTripStarted extends StatelessWidget {
  const TerminalTripStarted({
    Key? key,
    required this.mapProvider,
    required this.tripDocumentId,
  }) : super(key: key);

  final MapProvider mapProvider;
  final String tripDocumentId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('TerminalTrips').doc(tripDocumentId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No trip details found'));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          var terminalName = data['terminalName'] ?? 'Unknown Terminal';
          var location = data['location'] ?? 'Unknown Location';
          var driverName = data['driverName'] ?? 'Unknown Passenger';
          var cost = data['cost'] ?? 'Cost unavailable';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultTextStyle(
                style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Enjoy the ride!',
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  totalRepeatCount: 20,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Trip Details:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: const Text('Terminal'),
                        subtitle: Text(terminalName),
                      ),
                      ListTile(
                        leading: const Icon(Icons.map),
                        title: const Text('Location'),
                        subtitle: Text(location),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Driver'),
                        subtitle: Text(driverName),
                      ),
                      ListTile(
                        leading: const Icon(Icons.attach_money),
                        title: const Text('Cost'),
                        subtitle: Text('\₱${cost.toString()}'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
