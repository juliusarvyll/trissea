import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trissea/constant.dart';
import 'package:trissea/models/map_action.dart';
import 'package:trissea/models/trip_model.dart';
import 'package:trissea/providers/map_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/database_service.dart';

class ConfirmPickup extends StatefulWidget {
  const ConfirmPickup({Key? key, this.mapProvider}) : super(key: key);

  final MapProvider? mapProvider;

  @override
  _ConfirmPickupState createState() => _ConfirmPickupState();
}

class _ConfirmPickupState extends State<ConfirmPickup> {
  int _selectedPassengerCount = 1;
  String? todaName;


  Future<String> calculateTravelTime(
    double originLatitude,
    double originLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    const apiKey = googleMapApi;
    final url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=$originLatitude,$originLongitude&destinations=$destinationLatitude,$destinationLongitude&key=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final rows = data['rows'] as List<dynamic>;
      if (rows.isNotEmpty) {
        final elements = rows[0]['elements'] as List<dynamic>;
        if (elements.isNotEmpty) {
          final duration = elements[0]['duration'] as Map<String, dynamic>;
          final durationInSeconds = duration['value'] as int;
          final durationInMinutes = (durationInSeconds / 60).ceil();

          return durationInMinutes.toString();
        }
      }
    }

    throw Exception('Failed to calculate travel time ${response.body}');
  }

  Future<String> calculateTravelTimeFinal(
    double originLatitude,
    double originLongitude,
    double destination1Latitude,
    double destination1Longitude,
    double destination2Latitude,
    double destination2Longitude,
  ) async {
    const apiKey = googleMapApi;

    final url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=$originLatitude,$originLongitude&destinations=$destination1Latitude,$destination1Longitude|$destination2Latitude,$destination2Longitude&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final rows = data['rows'] as List<dynamic>;
      if (rows.isNotEmpty) {
        print("Rows: $rows");
        final elements = rows[0]['elements'] as List<dynamic>;
        if (elements.isNotEmpty) {
          final duration = elements[0]['duration'] as Map<String, dynamic>;
          final duration1 = elements[1]['duration'] as Map<String, dynamic>;
          final durationInSeconds = duration['value'] as int;
          final duration1InSeconds = duration1['value'] as int;
          final totalDurationInSeconds =
              durationInSeconds + duration1InSeconds;
          final durationInMinutes = (totalDurationInSeconds / 60).ceil();
          return durationInMinutes.toString();
        }
      }
    }

    throw Exception('Failed to calculate travel time ${response.body}');
  }

  Future<String> getTravelTime() async {
    if (widget.mapProvider!.finalLocation != null) {
      return calculateTravelTimeFinal(
        widget.mapProvider!.deviceLocation?.latitude ?? 0.0,
        widget.mapProvider!.deviceLocation?.longitude ?? 0.0,
        widget.mapProvider!.remoteLocation?.latitude ?? 0.0,
        widget.mapProvider!.remoteLocation?.longitude ?? 0.0,
        widget.mapProvider!.finalLocation?.latitude ?? 0.0,
        widget.mapProvider!.finalLocation?.longitude ?? 0.0,
      );
    } else {
      return calculateTravelTime(
        widget.mapProvider!.deviceLocation?.latitude ?? 0.0,
        widget.mapProvider!.deviceLocation?.longitude ?? 0.0,
        widget.mapProvider!.remoteLocation?.latitude ?? 0.0,
        widget.mapProvider!.remoteLocation?.longitude ?? 0.0,
      );
    }
  }

  Future<void> _startTrip(BuildContext context) async {
    final DatabaseService dbService = DatabaseService();

    final deviceLocation = widget.mapProvider?.deviceLocation;
    final remoteLocation = widget.mapProvider?.remoteLocation;
    final finalLocation = widget.mapProvider?.finalLocation;

    print("final location $finalLocation");

    if (remoteLocation != null && finalLocation == null) {
      print("this");
      Trip newTrip = Trip(
        pickupAddress: widget.mapProvider?.deviceAddress ?? "",
        destinationAddress: widget.mapProvider?.remoteAddress ?? "",
        pickupLatitude: deviceLocation!.latitude,
        pickupLongitude: deviceLocation.longitude,
        destinationLatitude: remoteLocation.latitude,
        destinationLongitude: remoteLocation.longitude,
        distance: widget.mapProvider?.distance,
        cost: widget.mapProvider?.cost,
        passengerId: FirebaseAuth.instance.currentUser?.uid ?? "",
        passengerName: FirebaseAuth.instance.currentUser?.displayName ?? "",
        passengerCount: _selectedPassengerCount,
        feedback: 0,
      );

      String tripId = await dbService.startTrip(newTrip);
      newTrip.id = tripId;
      widget.mapProvider?.confirmTrip(newTrip);

      widget.mapProvider?.triggerAutoCancelTrip(
        tripDeleteHandler: () {
          newTrip.canceled = true;
          dbService.updateTrip(newTrip);
        },
        snackbarHandler: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip is not accepted by any driver'),
            ),
          );
        },
      );
    } else {
      print("that");
      Trip newTrip = Trip(
        pickupAddress: widget.mapProvider?.deviceAddress ?? "",
        destinationAddress: widget.mapProvider?.remoteAddress ?? "",
        finalDestinationAddress: widget.mapProvider?.finalAddress ?? "",
        pickupLatitude: deviceLocation!.latitude,
        pickupLongitude: deviceLocation.longitude,
        destinationLatitude: remoteLocation!.latitude,
        destinationLongitude: remoteLocation.longitude,
        finalDestinationLatitude: finalLocation!.latitude,
        finalDestinationLongitude: finalLocation.longitude,
        distance: widget.mapProvider?.distance,
        cost: widget.mapProvider?.cost,
        passengerId: FirebaseAuth.instance.currentUser?.uid ?? "",
        passengerName: FirebaseAuth.instance.currentUser?.displayName ?? "",
        passengerCount: _selectedPassengerCount,
      );

      String tripId = await dbService.startTrip(newTrip);
      newTrip.id = tripId;
      widget.mapProvider?.confirmTrip(newTrip);

      widget.mapProvider?.triggerAutoCancelTrip(
        tripDeleteHandler: () {
          newTrip.canceled = true;
          dbService.updateTrip(newTrip);
        },
        snackbarHandler: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip is not accepted by any driver'),
            ),
          );
        },
      );
    }
  }

  Future<void> _startTodaTrip(BuildContext context, String todaName, {required bool shareRide}) async {
    final DatabaseService dbService = DatabaseService();

    final deviceLocation = widget.mapProvider?.deviceLocation;
    

      print("toda");
      Trip newTrip = Trip(
        pickupAddress: widget.mapProvider?.deviceAddress ?? "",
        destinationAddress: widget.mapProvider?.remoteAddress ?? "",
        pickupLatitude: deviceLocation!.latitude,
        rideShare: shareRide,
        pickupLongitude: deviceLocation.longitude,
        distance: widget.mapProvider?.distance,
        cost: widget.mapProvider?.cost,
        passengerId: FirebaseAuth.instance.currentUser?.uid ?? "",
        passengerName: FirebaseAuth.instance.currentUser?.displayName ?? "",
        passengerCount: _selectedPassengerCount,
        feedback: 0,
        todaName: todaName,
      );

      String tripId = await dbService.startTodaTrip(newTrip);
      newTrip.id = tripId;
      widget.mapProvider?.confirmTrip(newTrip);

      widget.mapProvider?.triggerAutoCancelTrip(
        tripDeleteHandler: () {
          newTrip.canceled = true;
          dbService.updateTodaTrip(newTrip);
        },
        snackbarHandler: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip is not accepted by any driver'),
            ),
          );
        },
      );
  }
  void showTerminalListDialog(Function(String) terminalSelected) {
  showDialog(
    context: context,
    builder: (BuildContext   context) {
      return AlertDialog(
        title: const Text("Select Terminal"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Terminal 1'),
              onTap: () {
                String selectedTerminal = 'Terminal 1';
                terminalSelected(selectedTerminal);
                Navigator.of(context).pop();
                _showRideSharingDialog(context, selectedTerminal);
              },
            ),
            ListTile(
              title: const Text('Terminal 2'),
              onTap: () {
                String selectedTerminal = 'Terminal 2';
                terminalSelected(selectedTerminal);
                Navigator.of(context).pop();
                _showRideSharingDialog(context, selectedTerminal);
              },
            ),
            // Add more ListTiles for other terminals as needed
          ],
        ),
      );
    },
  );
}
void _showRideSharingDialog(BuildContext context, String terminalName) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Share Ride?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startTodaTrip(context, terminalName, shareRide: true);
              },
              child: const Text(
                "Yes",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startTodaTrip(context, terminalName, shareRide: false);
              },
              child: const Text("No", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    },
  );
}



  void chooseTricycle() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Select option"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                // Handle Roaming option
                _startTrip(context);
                Navigator.of(context).pop();
              },
              child: const Text(
                "Roaming",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Handle Terminal option
                // Show another dialog with terminal list
                Navigator.of(context).pop();
                showTerminalListDialog((terminalName) {
                  setState(() {
                    todaName = terminalName;
                  });
                   // Pass todaName
                });
              },
              child: const Text("Terminal", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    },
  );
}

  

  @override
Widget build(BuildContext context) {
  return Visibility(
    visible: widget.mapProvider!.mapAction == MapAction.tripSelected &&
        widget.mapProvider!.remoteMarker != null,
    child: Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 100, horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 3,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.mapProvider!.remoteLocation != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.mapProvider!.remoteAddress != null)
                        Row(
                          children: [
                            const Icon(Icons.location_pin),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.mapProvider!.remoteAddress!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (widget.mapProvider!.finalAddress != null)
                        Row(
                          children: [
                            const Icon(Icons.location_pin),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.mapProvider!.finalAddress!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      if (widget.mapProvider!.distance != null)
                        Row(
                          children: [
                            const Icon(Icons.directions),
                            const SizedBox(width: 8),
                            Text(
                              'Distance: ${widget.mapProvider!.distance!.toStringAsFixed(2)} km',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      if (widget.mapProvider!.cost != null)
                        Row(
                          children: [
                            const Icon(Icons.money),
                            const SizedBox(width: 8),
                            Text(
                              'Trip will cost: P${widget.mapProvider!.cost!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      FutureBuilder<String>(
                        future: getTravelTime(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Row(
                              children: [
                                Icon(Icons.access_time),
                                SizedBox(width: 8),
                                Text(
                                  'Travel Time: Calculating...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            );
                          } else if (snapshot.hasError) {
                            return Row(
                              children: [
                                const Icon(Icons.error),
                                const SizedBox(width: 8),
                                Text(
                                  'Travel Time: Error calculating travel time: ${snapshot.error}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            final travelTime = snapshot.data;
                            return Row(
                              children: [
                                const Icon(Icons.timer),
                                const SizedBox(width: 8),
                                Text(
                                  'Travel Time: $travelTime minutes',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedPassengerCount,
                  items: List.generate(5, (index) {
                    return DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text('${index + 1} Passenger'),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPassengerCount = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [   
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                  ),
                  onPressed: () => chooseTricycle(),
                  child: const Text(
                    'CONFIRM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                  ),
                  onPressed: () => widget.mapProvider!.cancelTrip(),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}