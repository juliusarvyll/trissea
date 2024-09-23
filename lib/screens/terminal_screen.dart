import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trissea/models/map_action.dart';
import 'package:trissea/models/terminal_trips_model.dart';
import 'package:trissea/providers/map_provider.dart';
import 'package:trissea/widgets/terminal_screen_widgets/accepted_request.dart';
import 'package:trissea/widgets/terminal_screen_widgets/pay_driver_terminal.dart';
import 'package:trissea/widgets/terminal_screen_widgets/search_terminal.dart';
import 'package:trissea/widgets/terminal_screen_widgets/terminal_trip_start.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({Key? key}) : super(key: key);
  static const String route = '/terminal';

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  MapProvider? _mapProvider;
  bool _showBookingDialog = false;
  String? _tripDocumentId; // Add this line

  @override
  void initState() {
    super.initState();
    _mapProvider = Provider.of<MapProvider>(context, listen: false);
    _mapProvider!.changeMapAction(MapAction.selectTerminal);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (BuildContext context, MapProvider mapProvider, _) {
        _mapProvider = mapProvider;
        
        print("whatttt${_mapProvider!.mapAction}");
        return Scaffold(
          key: scaffoldKey,
          body: Stack(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('terminals').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final terminals = snapshot.data?.docs ?? [];

                  if (terminals.isEmpty) {
                    return Center(child: Text('No terminals found'));
                  }

                  return ListView.builder(
                    itemCount: terminals.length,
                    itemBuilder: (context, index) {
                      final terminal = terminals[index];
                      final data = terminal.data() as Map<String, dynamic>;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(
                            data['name'] ?? 'No Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(data['location'] ?? 'No Location'),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            _showBookingDialog = true;
                            _showBookingOptionsDialog(data);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 100,
                child: SearchTerminal(mapProvider: mapProvider),
              ),
              if (_tripDocumentId != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 100,
                  child: AcceptedRequest(
                    mapProvider: mapProvider,
                    tripDocumentId: _tripDocumentId!,
                  ),
                ),
              if (_tripDocumentId != null && _mapProvider?.mapAction == MapAction.startTerminalTrip)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 100,
                  child: TerminalTripStarted(mapProvider: mapProvider, tripDocumentId: _tripDocumentId!),
                ),
                if (_tripDocumentId != null && _mapProvider?.mapAction == MapAction.endedTerminalTrip)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 100,
                  child: PayDriverTerminal(mapProvider: mapProvider, tripDocumentId: _tripDocumentId!),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showBookingOptionsDialog(Map<String, dynamic> terminalData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Booking Option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextButton(
                child: Text('Pay for Whole Tricycle (\$110)'),
                onPressed: () {
                  _handleBooking(terminalData, 110);
                },
              ),
              TextButton(
                child: Text('Wait for Other Passengers (\$20)'),
                onPressed: () {
                  _handleBooking(terminalData, 20);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleBooking(Map<String, dynamic> terminalData, int cost) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle user not signed in
      print("User is not signed in");
      return;
    }
    String passengerId = currentUser.uid;
    String passengerName = currentUser.displayName ?? 'Anonymous';

    print("Passenger ID: $passengerId");

    // Generate a unique ID for the document
    String documentId = FirebaseFirestore.instance.collection('TerminalTrips').doc().id;
    print("Generated document ID: $documentId");

    // Store the document ID in the state
    setState(() {
      _tripDocumentId = documentId;
    });

    // Create a TerminalTrip object with document ID
    TerminalTrip terminalTrip = TerminalTrip(
      id: documentId,
      terminalName: terminalData['name'] ?? 'No Name',
      location: terminalData['location'] ?? 'No Location',
      passengerId: passengerId,
      passengerName: passengerName,
      cost: cost,
      timestamp: Timestamp.now(),
      accepted: false, // Set initial status as Pending
      ended: false,
    );

    print("TerminalTrip object created: ${terminalTrip.toMap()}");

    // Add the TerminalTrip object to Firestore
    FirebaseFirestore.instance.collection('TerminalTrips').doc(documentId).set(terminalTrip.toMap()).then((value) {
      // Listen for acceptance for this specific document ID
      _listenForRequestAcceptance(documentId);
      _listenForTripStart(documentId);
      _listenForTripEnded(documentId);
      _listenForTripPaid(documentId);

      // After adding the details, change the map action if _mapProvider is not null
      if (_mapProvider != null) {
        _mapProvider!.changeMapAction(MapAction.searchTerminal);
        Navigator.of(context).pop();
        if (_showBookingDialog) {
          _showBookingDialog = false;
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Booking Details'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      terminalData['name'] ?? 'No Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Location: ${terminalData['location'] ?? 'No Location'}'),
                    Text('Cost: \$${cost.toString()}'),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    });
  }

  void _listenForRequestAcceptance(String documentId) {
    FirebaseFirestore.instance
        .collection('TerminalTrips')
        .doc(documentId)
        .snapshots()
        .listen((snapshot) {
      var data = snapshot.data();
      if (data != null && data['accepted'] == true) {
        setState(() {
          _mapProvider?.changeMapAction(MapAction.acceptedRequest);
          print('mapAction: ${_mapProvider?.mapAction}');
        });
      }
    });
  }

  void _listenForTripEnded(String documentId) {
    FirebaseFirestore.instance
        .collection('TerminalTrips')
        .doc(documentId)
        .snapshots()
        .listen((snapshot) {
      var data = snapshot.data();
      if (data != null && data['ended'] == true) {
        setState(() {
          _mapProvider?.changeMapAction(MapAction.endedTerminalTrip);
          print('mapAction: ${_mapProvider?.mapAction}');
        });
      }
    });
  }

  void _listenForTripPaid(String documentId) {
    FirebaseFirestore.instance
        .collection('TerminalTrips')
        .doc(documentId)
        .snapshots()
        .listen((snapshot) {
      var data = snapshot.data();
      if (data != null && data['paid'] == true) {
        setState(() {
          _mapProvider?.changeMapAction(MapAction.selectTerminal);
          print('mapAction: ${_mapProvider?.mapAction}');
        });
      }
    });
  }

  void _listenForTripStart(String documentId) {
    FirebaseFirestore.instance
        .collection('TerminalTrips')
        .doc(documentId)
        .snapshots()
        .listen((snapshot) {
      var data = snapshot.data();
      if (data != null && data['started'] == true) {
        setState(() {
          _mapProvider?.changeMapAction(MapAction.startTerminalTrip);
          print('mapAction: ${_mapProvider?.mapAction}');
        });
      } else {
        print('Trip has not started yet or document data is null.');
      }
    });
  }
}
