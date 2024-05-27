import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:trissea/models/map_action.dart';
import 'package:trissea/providers/map_provider.dart';
import 'package:trissea/screens/search_bar.dart';
import 'package:trissea/widgets/custom_side_drawer.dart';
import 'package:trissea/widgets/map_screen_widgets/floating_drawer_bar_button.dart';
import 'package:trissea/widgets/map_screen_widgets/confirm_pickup.dart';
import 'package:trissea/widgets/map_screen_widgets/search_driver.dart';
import 'package:trissea/widgets/map_screen_widgets/trip_started.dart';
import 'package:trissea/widgets/map_screen_widgets/reached_destination.dart';
import 'package:trissea/widgets/map_screen_widgets/feedback.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  static const String route = '/mapscreen';

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _draggedLatlng = const LatLng(0.0, 0.0);
  MapProvider? _mapProvider;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _mapProvider = Provider.of<MapProvider>(context, listen: false);
    _mapProvider!.initializeMap(
      scaffoldKey: scaffoldKey,
    );
    _mapProvider!.changeMapAction(MapAction.selectTrip);
  }

  void onButtonPressed() {
    if (_mapProvider!.remoteLocation == null) {
      showAddDestinationDialog();
    } else {
      addFinalDestination();
    }
  }

  void showAddDestinationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Another Destination?"),
          content: const Text("Do you want to add another destination location?"),
          actions: [
            TextButton(
              onPressed: () {
                _mapProvider!.changeMapAction(MapAction.tripSelected);
                if (_mapProvider!.remoteLocation == null) {
                  addRemoteDestination();
                } else {
                  addFinalDestination();
                }
                Navigator.pop(context);
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                if (_mapProvider!.remoteLocation == null) {
                  addRemoteDestination();
                } else {
                  addFinalDestination();
                }
                Navigator.pop(context);
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  void addRemoteDestination() {
    _mapProvider!.onTap(_draggedLatlng);
  }

  void addFinalDestination() {
    _mapProvider!.changeMapAction(MapAction.tripSelected);
    _mapProvider!.setFinalLocation(_draggedLatlng);
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
      builder: (BuildContext context, MapProvider mapProvider, _) {
        _mapProvider = mapProvider;

        return Scaffold(
          key: scaffoldKey,
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
                                    ...mapProvider.markers!,
                                    ...mapProvider.markersPickup!,
                                    ...mapProvider.markersFinal!
                                  },
                                  polylines: mapProvider.polylines!,
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          IgnorePointer(
                            child: Visibility(
                              visible: mapProvider.mapAction == MapAction.selectTrip,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Text(
                                        mapProvider.remoteAddress ?? '',
                                        style: const TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Ionicons.location,
                                      size: 50,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ConfirmPickup(mapProvider: mapProvider),
                          SearchDriver(mapProvider: mapProvider),
                          TripStarted(mapProvider: mapProvider),
                          ReachedDestination(mapProvider: mapProvider),
                          FeedbackPage(mapProvider: mapProvider,),
                          if(mapProvider.mapAction == MapAction.selectTrip)
                            SearchLocationWidget(mapProvider: mapProvider,),
                          FloatingDrawerBarButton(scaffoldKey: scaffoldKey,)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if(mapProvider.mapAction == MapAction.selectTrip)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: onButtonPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Modern color scheme
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0), // Rounded corners
                        ),
                      ),
                      child: const Text(
                        'Select Location',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
