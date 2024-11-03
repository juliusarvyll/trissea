import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/database_service.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({Key? key}) : super(key: key);

  static const String route = '/trips';

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FutureBuilder(
        future: DatabaseService().getCompletedTrips(),
        builder: (BuildContext context, AsyncSnapshot<List<Trip>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)),
            );
          }

          List<Trip> trips = snapshot.data as List<Trip>;

          return trips.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  itemCount: trips.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildTripItem(trips[index]);
                  },
                )
              : const Center(
                  child: Text('Empty Ride History', style: TextStyle(fontSize: 18, color: Colors.grey)),
                );
        },
      ),
    );
  }

  Widget _buildTripItem(Trip trip) => Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoText('Pickup:', trip.pickupAddress!),
              const SizedBox(height: 10),
              _buildInfoText('Destination:', trip.destinationAddress!),
              const SizedBox(height: 10),
              _buildInfoText('Distance:', '${trip.distance!.toStringAsFixed(2)} Km'),
              const SizedBox(height: 10),
              _buildInfoText('Cost:', '₱${trip.cost!.toStringAsFixed(2)}'),
            ],
          ),
        ),
      );

  Widget _buildInfoText(String title, String info) {
    return RichText(
      text: TextSpan(
        text: '$title ',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        children: [
          TextSpan(
            text: info,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
