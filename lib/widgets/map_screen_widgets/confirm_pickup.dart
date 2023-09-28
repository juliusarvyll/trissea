import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trissea/constant.dart';
import 'package:trissea/models/map_action.dart';
import 'package:trissea/models/trip_model.dart';
import 'package:trissea/providers/map_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/database_service.dart';

class ConfirmPickup extends StatelessWidget {
  const ConfirmPickup({Key? key, this.mapProvider}) : super(key: key);

  final MapProvider? mapProvider;

  Future<String> calculateTravelTime(
    double originLatitude,
    double originLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    const apiKey = googleMapApi; // Replace with your own API key

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

  Future<void> _startTrip(BuildContext context) async {
    final DatabaseService dbService = DatabaseService();

    Trip newTrip = Trip(
      pickupAddress: mapProvider!.deviceAddress,
      destinationAddress: mapProvider!.remoteAddress,
      pickupLatitude: mapProvider!.deviceLocation!.latitude,
      pickupLongitude: mapProvider!.deviceLocation!.longitude,
      destinationLatitude: mapProvider!.remoteLocation!.latitude,
      destinationLongitude: mapProvider!.remoteLocation!.longitude,
      distance: mapProvider!.distance,
      cost: mapProvider!.cost,
      passengerId: FirebaseAuth.instance.currentUser!.uid,
      passengerName: FirebaseAuth.instance.currentUser!.displayName,
    );

    String tripId = await dbService.startTrip(newTrip);
    newTrip.id = tripId;
    mapProvider!.confirmTrip(newTrip);

    mapProvider!.triggerAutoCancelTrip(
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

  Future<String> getTravelTime() async {
    return await calculateTravelTime(
      mapProvider!.deviceLocation?.latitude ?? 0.0,
      mapProvider!.deviceLocation?.longitude ?? 0.0,
      mapProvider!.remoteLocation?.latitude ?? 0.0,
      mapProvider!.remoteLocation?.longitude ?? 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: mapProvider!.mapAction == MapAction.tripSelected &&
          mapProvider!.remoteMarker != null,
      child: Positioned.fill(
        top: 420,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              mapProvider!.remoteLocation != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (mapProvider!.remoteAddress != null)
                          Text(
                            mapProvider!.remoteAddress!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (mapProvider!.distance != null)
                          Text(
                            'Distance: ${mapProvider!.distance!.toStringAsFixed(2)} km',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        if (mapProvider!.cost != null)
                          Text(
                            'Trip will cost: P${mapProvider!.cost!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        FutureBuilder<String>(
                          future: getTravelTime(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                'Travel Time: Calculating...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return Text(
                                'Travel Time: Error calculating travel time: ${snapshot.error}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              );
                            } else {
                              final travelTime = snapshot.data;
                              return Text(
                                'Travel Time: $travelTime minutes',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    )
                  : const SizedBox
                      .shrink(), // Don't show anything if data is not loaded
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.black, // Use your desired color here
                        padding: const EdgeInsets.all(15),
                      ),
                      onPressed: () => _startTrip(context),
                      child: const Text(
                        'CONFIRM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.grey[300], // Use your desired color here
                        padding: const EdgeInsets.all(15),
                      ),
                      onPressed: () => mapProvider!.cancelTrip(),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
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
