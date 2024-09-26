import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trissea/models/map_action.dart';
import 'package:trissea/providers/map_provider.dart';
import 'package:trissea/widgets/custom_side_drawer.dart';
import 'package:trissea/widgets/map_screen_widgets/floating_drawer_bar_button.dart';
import 'package:trissea/widgets/map_screen_widgets/confirm_pickup.dart';
import 'package:trissea/widgets/map_screen_widgets/search_driver.dart';
import 'package:trissea/widgets/map_screen_widgets/trip_started.dart';
import 'package:trissea/widgets/map_screen_widgets/reached_destination.dart';
import 'package:trissea/widgets/map_screen_widgets/feedback.dart';
import 'package:trissea/screens/search_bar.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  static const String route = '/mapscreen';

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _draggedLatlng = const LatLng(0.0, 0.0); // Initialized with a default value
  MapProvider? _mapProvider;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _mapProvider = Provider.of<MapProvider>(context, listen: false);
    _mapProvider!.setScaffoldKey(_scaffoldKey);
    _mapProvider!.initializeMap(scaffoldKey: _scaffoldKey);
    _mapProvider!.changeMapAction(MapAction.selectTrip);
  }

  void onButtonPressed() {
    _mapProvider!.changeMapAction(MapAction.tripSelected);
    _mapProvider!.onTap(_draggedLatlng);
  }

  void getMarkerPosition(CameraPosition cameraPosition) async {
    setState(() {
      _draggedLatlng = cameraPosition.target;
    });
  }

  void updateMarkerPosition() async {
    await _mapProvider!.setRemoteAddress(_draggedLatlng);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (BuildContext context, mapProvider, _) {
        _mapProvider = mapProvider;

        return Scaffold(
          key: _scaffoldKey,
          drawer: const CustomSideDrawer(),
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
                                  onMapCreated: (GoogleMapController controller) {
                                    mapProvider.onMapCreated(controller);
                                  },
                                  initialCameraPosition: mapProvider.cameraPos!,
                                  compassEnabled: true,
                                  onCameraMove: getMarkerPosition,
                                  onCameraIdle: updateMarkerPosition,
                                  markers: {
                                    ...mapProvider.markersPickup!,
                                    ...mapProvider.markersFinal!
                                  },
                                  polylines: mapProvider.polylines!,
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          const Center(
                            child: Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                          ConfirmPickup(mapProvider: mapProvider),
                          SearchDriver(mapProvider: mapProvider),
                          TripStarted(mapProvider: mapProvider),
                          ReachedDestination(mapProvider: mapProvider),
                          FeedbackPage(mapProvider: mapProvider),
                          if (mapProvider.mapAction == MapAction.selectTrip)
                            SearchLocationWidget(mapProvider: mapProvider),
                          FloatingDrawerBarButton(scaffoldKey: _scaffoldKey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (mapProvider.mapAction == MapAction.selectTrip)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                mapProvider.remoteAddress ?? 'Enter address',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: onButtonPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                ),
                                child: const Text(
                                  'Select Location',
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
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
