import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trissea/models/map_action.dart';
import 'package:trissea/models/terminal_trips_model.dart';
import 'package:trissea/providers/map_provider.dart';
import 'package:trissea/screens/login_signup_screen.dart';
import 'package:trissea/widgets/terminal_screen_widgets/accepted_request.dart';
import 'package:trissea/widgets/terminal_screen_widgets/pay_driver_terminal.dart';
import 'package:trissea/widgets/terminal_screen_widgets/search_terminal.dart';
import 'package:trissea/widgets/terminal_screen_widgets/terminal_trip_start.dart';
import 'dart:async';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({Key? key}) : super(key: key);
  static const String route = '/terminal';

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> with AutomaticKeepAliveClientMixin {
  final List<StreamSubscription> _subscriptions = [];
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late MapProvider _mapProvider;
  String? _tripDocumentId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _mapProvider = Provider.of<MapProvider>(context, listen: false);
  }

  @override
  void dispose() {
    // Only reset MapAction if there's no active trip
    if (_tripDocumentId == null) {
      _mapProvider.changeMapAction(MapAction.selectTrip);
    }
    
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _setupTripListeners(String documentId) {
    final tripRef = FirebaseFirestore.instance.collection('TerminalTrips').doc(documentId);
    
    final subscription = tripRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) return;
      
      final data = snapshot.data();
      if (data == null) return;

      _handleTripStateChange(data);
    });

    _subscriptions.add(subscription);
  }

  void _handleTripStateChange(Map<String, dynamic> data) {
    if (data['paid'] == true) {
      _mapProvider.changeMapAction(MapAction.searchTerminal);
    } else if (data['ended'] == true) {
      _mapProvider.changeMapAction(MapAction.endedTerminalTrip);
    } else if (data['started'] == true) {
      _mapProvider.changeMapAction(MapAction.startTerminalTrip);
    } else if (data['accepted'] == true) {
      _mapProvider.changeMapAction(MapAction.acceptedRequest);
    }
  }

  Future<void> _processBooking(Map<String, dynamic> terminalData, int cost, User currentUser) async {
    final String documentId = FirebaseFirestore.instance.collection('TerminalTrips').doc().id;
    
    setState(() => _tripDocumentId = documentId);

    final terminalTrip = TerminalTrip(
      id: documentId,
      terminalName: terminalData['name'] ?? 'No Name',
      location: terminalData['location'] ?? 'No Location',
      passengerId: currentUser.uid,
      passengerName: currentUser.displayName ?? 'Anonymous',
      cost: cost,
      timestamp: Timestamp.now(),
      accepted: false,
      cancelled: false,
      ended: false,
    );

    try {
      await FirebaseFirestore.instance
          .collection('TerminalTrips')
          .doc(documentId)
          .set(terminalTrip.toMap());
      
      _setupTripListeners(documentId);
      _mapProvider.changeMapAction(MapAction.searchTerminal);
    } catch (e) {
      debugPrint('Error processing booking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<MapProvider>(
      builder: (BuildContext context, MapProvider mapProvider, _) {
        _mapProvider = mapProvider;

        return Scaffold(
          appBar: AppBar(
            title: Text('Terminals', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
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
                    return const Center(child: Text('No terminals found'));
                  }

                  return ListView.builder(
                    itemCount: terminals.length,
                    itemBuilder: (context, index) {
                      final terminal = terminals[index];
                      final data = terminal.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(
                            data['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(data['location'] ?? 'No Location'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () {
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
                bottom: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentWidget(mapProvider),
                ),
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
                child: Text('Pay for Whole Tricycle (₱110)'),
                onPressed: () {
                  _handleBooking(terminalData, 110);
                },
              ),
              TextButton(
                child: Text('Wait for Other Passengers (₱20)'),
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
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginSignupScreen()));
      return;
    }

    Navigator.of(context).pop(); // Close the booking options dialog
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Booking Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                terminalData['name'] ?? 'No Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      terminalData['location'] ?? 'No Location',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.payment, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Cost: ₱${cost.toString()}',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text('Confirm Booking', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                _processBooking(terminalData, cost, currentUser);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentWidget(MapProvider mapProvider) {
    if (_tripDocumentId == null) {
      return const SizedBox.shrink();
    }
    switch (mapProvider.mapAction) {
      case MapAction.searchTerminal:
        return SearchTerminal(
          mapProvider: mapProvider,
          tripDocumentId: _tripDocumentId!,
        );
      case MapAction.acceptedRequest:
        return AcceptedRequest(
          mapProvider: mapProvider,
          tripDocumentId: _tripDocumentId!,
        );
      case MapAction.startTerminalTrip:
        return TerminalTripStarted(
          mapProvider: mapProvider,
          tripDocumentId: _tripDocumentId!,
        );
      case MapAction.endedTerminalTrip:
        return PayDriverTerminal(
          mapProvider: mapProvider,
          tripDocumentId: _tripDocumentId!,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
