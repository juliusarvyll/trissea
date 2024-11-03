import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../providers/map_provider.dart';

class SearchTerminal extends StatefulWidget {
  const SearchTerminal({
    Key? key,
    required this.mapProvider,
    required this.tripDocumentId,
  }) : super(key: key);

  final MapProvider mapProvider;
  final String tripDocumentId;

  @override
  State<SearchTerminal> createState() => _SearchTerminalState();
}

class _SearchTerminalState extends State<SearchTerminal> {
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    // Start 60-second timer when widget initializes
    _searchTimer = Timer(const Duration(seconds: 10), () {
      _cancelTrip();
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();  // Cancel timer when widget is disposed
    super.dispose();
  }

  void _cancelTrip() async {
    await FirebaseFirestore.instance
        .collection('TerminalTrips')
        .doc(widget.tripDocumentId)
        .update({'accepted': false});
    widget.mapProvider.cancelTrip();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}
