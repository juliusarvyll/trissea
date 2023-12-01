import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trissea/models/map_action.dart';
import 'package:trissea/providers/map_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:trissea/widgets/map_screen_widgets/nearest_drivers.dart';

import '../widgets/map_screen_widgets/confirm_pickup.dart';
import '../widgets/map_screen_widgets/reached_destination.dart';
import '../widgets/map_screen_widgets/search_driver.dart';
import '../widgets/map_screen_widgets/trip_started.dart';
import 'search_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  static const String route = '/home';

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  CameraPosition? _cameraPosition;
  LatLng _draggedLatlng = const LatLng(0.0, 0.0);
  bool destination = false;
  bool initialCameraLoad = true;
  MapProvider?
      _mapProvider; // Declare a class-level variable // Track whether to show or hide the map

  // Getter methods for the variables
  CameraPosition? get cameraPosition => _cameraPosition;
  LatLng get draggedLatLng => _draggedLatlng;
  bool get isDestination => destination;
  bool get isInitialCameraLoad => initialCameraLoad;

  // Create a function that you want to run when the button is pressed.
  void onButtonPressed() {
    if (_mapProvider!.remoteLocation == null) {
      _mapProvider!.onTap(_draggedLatlng);
    }
  }

  // Function to update the marker's position based on the map's center
  void updateMarkerPosition(CameraPosition cameraPosition) {
    setState(() {
      _draggedLatlng = cameraPosition.target;
    });
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    Provider.of<MapProvider>(context, listen: false).initializeMap(
      scaffoldKey: scaffoldKey,
    );

    return Consumer<MapProvider>(
      builder: (BuildContext context, MapProvider mapProvider, _) {
        // Store a reference to mapProvider in the class-level variable
        _mapProvider = mapProvider;

        return Scaffold(
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          mapProvider.cameraPos != null
                              ? GoogleMap(
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: true,
                                  onMapCreated:
                                      (GoogleMapController controller) {
                                    mapProvider.onMapCreated(controller);
                                  },
                                  initialCameraPosition: mapProvider.cameraPos!,
                                  compassEnabled: true,
                                  onCameraMove: updateMarkerPosition,
                                  markers: {
                                    ...mapProvider.markers!,
                                  },
                                  polylines: mapProvider.polylines!,
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          IgnorePointer(
                            child: Center(
                              child: Lottie.asset('images/pin.json',
                                  height: 400,
                                  width: 200,
                                  frameRate: FrameRate.max,
                                  animate: true,
                                  alignment: const Alignment(0.0, 0.0)),
                            ),
                          ),
                          ConfirmPickup(mapProvider: mapProvider),
                          NearestDriver(mapProvider: mapProvider),
                          SearchDriver(mapProvider: mapProvider),
                          TripStarted(mapProvider: mapProvider),
                          ReachedDestination(mapProvider: mapProvider),
                          SearchLocationWidget(
                            mapProvider: mapProvider,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    if (mapProvider.mapAction == MapAction.selectTrip)
                      Container(
                        color: Colors.white,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: ElevatedButton(
                            onPressed: onButtonPressed,
                            child: const Text('Select Location'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
