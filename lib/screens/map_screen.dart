import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trissea/providers/map_provider.dart';
import 'package:lottie/lottie.dart';

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
  bool pickup = false;
  bool destination = false;
  bool initialCameraLoad = true;
  late MapProvider _mapProvider;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapProvider = Provider.of<MapProvider>(context, listen: false);
      _mapProvider.initializeMap(scaffoldKey: scaffoldKey);
    });
  }

  void onButtonPressed() {
    if (_mapProvider.deviceLocation == null || _mapProvider.remoteLocation == null) {
      _mapProvider.onTap(_draggedLatlng);
    }
  }

  void updateMarkerPosition(CameraPosition cameraPosition) {
    setState(() {
      _draggedLatlng = cameraPosition.target;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: Consumer<MapProvider>(
        builder: (context, mapProvider, _) {
          return Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: mapProvider.cameraPos != null
                          ? Stack(
                              children: [
                                GoogleMap(
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: true,
                                  initialCameraPosition: mapProvider.cameraPos!,
                                  onMapCreated: mapProvider.onMapCreated,
                                  onCameraMove: updateMarkerPosition,
                                  markers: {...mapProvider.markers!, ...mapProvider.markersPickup!},
                                  polylines: mapProvider.polylines!,
                                  compassEnabled: true,
                                ),
                                IgnorePointer(
                                  child: Center(
                                    child: Lottie.asset(
                                      'images/pin.json',
                                      height: 400,
                                      width: 200,
                                      frameRate: FrameRate.max,
                                      alignment: Alignment.center,
                                    ),
                                  ),
                                ),
                                ConfirmPickup(mapProvider: mapProvider),
                                SearchDriver(mapProvider: mapProvider),
                                TripStarted(mapProvider: mapProvider),
                                ReachedDestination(mapProvider: mapProvider),
                              ],
                            )
                          : const Center(
                              child: CircularProgressIndicator(),
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
                    const SizedBox(height: 10),
                    const SearchLocationWidget(),
                    ElevatedButton(
                      onPressed: onButtonPressed,
                      child: const Text('Confirm Pickup'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
