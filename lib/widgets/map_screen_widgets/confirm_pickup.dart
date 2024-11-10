import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isLoading = false;

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

      return calculateTravelTime(
        widget.mapProvider!.deviceLocation?.latitude ?? 0.0,
        widget.mapProvider!.deviceLocation?.longitude ?? 0.0,
        widget.mapProvider!.remoteLocation?.latitude ?? 0.0,
        widget.mapProvider!.remoteLocation?.longitude ?? 0.0,
      );
  }

  Future<void> _startTrip(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final DatabaseService dbService = DatabaseService();

      final deviceLocation = widget.mapProvider?.deviceLocation;
      final remoteLocation = widget.mapProvider?.remoteLocation;


      if (remoteLocation != null) {
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
          pickupLatitude: deviceLocation!.latitude,
          pickupLongitude: deviceLocation.longitude,
          destinationLatitude: remoteLocation!.latitude,
          destinationLongitude: remoteLocation.longitude,
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start trip: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.mapProvider?.fetchSpecialPrice();
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
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                    ),
                    onPressed: _isLoading ? null : () => _startTrip(context),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
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