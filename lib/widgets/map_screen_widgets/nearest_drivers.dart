import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trissea/models/map_action.dart';
import '../../providers/map_provider.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import 'package:trissea/models/trip_model.dart';

class DriverWithDistance {
  final String name;
  final String id;
  final double distance;

  DriverWithDistance(this.name, this.id, this.distance);

  @override
  String toString() {
    return '$name - ${distance.toStringAsFixed(2)} meters';
  }
}

class NearestDriver extends StatelessWidget {
  final MapProvider? mapProvider;

  const NearestDriver({
    Key? key,
    required this.mapProvider,
  }) : super(key: key);

  Future<List<DriverWithDistance>> fetchDriverNames() async {
    return await fetchDriversWithDistances();
  }

  Future<List<DriverWithDistance>> fetchDriversWithDistances() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle the case when the user is not authenticated
      return [];
    }

    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('passengers')
          .doc(user.uid)
          .get();

      double userLatitude = userSnapshot['passengerLatitude'] ?? 0.0;
      double userLongitude = userSnapshot['passengerLongitude'] ?? 0.0;

      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('drivers').get();
      final List<QueryDocumentSnapshot> driverDocs = snapshot.docs;

      List<DriverWithDistance> driversWithDistances = [];

      for (QueryDocumentSnapshot driverDoc in driverDocs) {
        double driverLatitude = driverDoc['driverLatitude'] ?? 0.0;
        double driverLongitude = driverDoc['driverLongitude'] ?? 0.0;

        double distanceInMeters = await _calculateDistance(
          userLatitude,
          userLongitude,
          driverLatitude,
          driverLongitude,
        );

        String driverName = driverDoc['driverName'] ?? 'Unknown';
        String driverId = driverDoc['id'] ?? 'Unknown';

        driversWithDistances.add(
          DriverWithDistance(driverName, driverId, distanceInMeters),
        );
      }

      return driversWithDistances;
    } catch (e) {
      print('Error fetching driver names: $e');
      return [];
    }
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

  Future<double> _calculateDistance(double userLatitude, double userLongitude,
      double driverLatitude, double driverLongitude) async {
    double distanceInMeters = Geolocator.distanceBetween(
      userLatitude,
      userLongitude,
      driverLatitude,
      driverLongitude,
    );
    return distanceInMeters;
  }

  void sendRequestToAllDrivers() {
    // mapProvider!.changeMapActiontoSelectTrip();
  }

  void bookDriver(DriverWithDistance selectedDriver) {
    // Print the details of the selected driver
    print('Booking driver:');
    print('Name: ${selectedDriver.name}');
    print('ID: ${selectedDriver.id}');
    print('Distance: ${selectedDriver.distance.toStringAsFixed(2)} meters');

    // Add your additional logic for booking the driver here
    // For example, navigate to a booking confirmation screen:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => BookingConfirmationScreen(selectedDriver),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, _) {
        return Visibility(
          visible: mapProvider.mapAction == MapAction.selectDriver,
          child: Positioned.fill(
            top: 420,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Expanded(
                    child: FutureBuilder<List<DriverWithDistance>>(
                      future: fetchDriverNames(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          final driversWithDistances = snapshot.data;

                          if (driversWithDistances!.isEmpty) {
                            return Text('No drivers found.');
                          }

                          return ListView.builder(
                            itemCount: driversWithDistances.length,
                            itemBuilder: (context, index) {
                              final driver = driversWithDistances[index];

                              return ListTile(
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${driver.name} - ${driver.distance.toStringAsFixed(2)} meters',
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Call your function to handle booking
                                        bookDriver(driver);
                                      },
                                      child: Text('Book'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Call your function to send requests to all drivers
                      sendRequestToAllDrivers();
                    },
                    child: Text('Send Request to All'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
