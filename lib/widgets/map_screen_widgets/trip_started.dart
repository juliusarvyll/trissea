import 'package:flutter/material.dart';
import '../../models/map_action.dart';
import '../../providers/map_provider.dart';

class TripStarted extends StatelessWidget {
  const TripStarted({Key? key, this.mapProvider}) : super(key: key);

  final MapProvider? mapProvider;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getDriverNameByIdFuture(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final driverName = snapshot.data ?? 'N/A';

          return Visibility(
            visible: mapProvider!.mapAction == MapAction.tripStarted ||
                mapProvider!.mapAction == MapAction.driverArriving ||
                mapProvider!.mapAction == MapAction.driverArrived,
            child: Positioned(
              bottom: 70,
              left: 15,
              right: 15,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car, // Add an icon here (car icon)
                            color: Colors.black,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            getTitleText(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      children: [
                        _buildInfoText('Driver Name: ', driverName),
                        if (mapProvider!.remoteAddress != null)
                          _buildInfoText(
                            'Heading Towards: ',
                            mapProvider!.remoteAddress!,
                          ),
                        const SizedBox(height: 2),
                      ],
                    ),
                    if (mapProvider!.distance != null)
                      _buildInfoText(
                        'Remaining Distance: ',
                        '${mapProvider!.distance!.toStringAsFixed(2)} Km',
                      )
                    else
                      _buildInfoText(
                        'Remaining Distance: ',
                        '--',
                      ),
                    if (mapProvider!.cost != null)
                      _buildInfoText(
                        'Cost: ',
                        '\$${mapProvider!.cost!.toStringAsFixed(2)}',
                      )
                    else
                      _buildInfoText(
                        'Cost: ',
                        '--',
                      ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  String getTitleText() {
    switch (mapProvider!.mapAction) {
      case MapAction.tripStarted:
        return 'Enjoy your ride!';
      case MapAction.driverArriving:
        return 'Driver is on their way to your location';
      case MapAction.driverArrived:
        return 'Driver has arrived at your location';
      default:
        return 'Trip Started';
    }
  }

  Widget _buildInfoText(String title, String info) {
    return RichText(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: info,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Future<String> getDriverNameByIdFuture() async {
    final driverName = await mapProvider?.getDriverNameById$().first ?? 'N/A';
    return driverName;
  }
}
