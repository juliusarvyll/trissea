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
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  static const String route = '/mapscreen';

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin {
  LatLng _draggedLatlng = const LatLng(0.0, 0.0);
  Timer? _debounceTimer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MapProvider? _mapProvider;

  @override
  void initState() {
    super.initState();
    _mapProvider = Provider.of<MapProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapProvider?.setScaffoldKey(_scaffoldKey);
      _mapProvider?.initializeMap(scaffoldKey: _scaffoldKey);
    });
  }

  @override
  void dispose() {
    if (_mapProvider?.ongoingTrip == null) {
      _mapProvider?.changeMapAction(MapAction.selectTrip);
    }
    
    _debounceTimer?.cancel();
    super.dispose();
  }

  void onButtonPressed() {
    _mapProvider!.changeMapAction(MapAction.tripSelected);
    _mapProvider!.onTap(_draggedLatlng);
  }

  void getMarkerPosition(CameraPosition cameraPosition) {
    setState(() {
      _draggedLatlng = cameraPosition.target;
    });
  }

  void updateMarkerPosition() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_mapProvider?.mapAction == MapAction.selectTrip) {
        await _mapProvider?.setRemoteAddress(_draggedLatlng);
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<MapProvider>(
      builder: (BuildContext context, mapProvider, _) {
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
                                  onMapCreated: mapProvider.onMapCreated,
                                  initialCameraPosition: mapProvider.cameraPos!,
                                  compassEnabled: true,
                                  onCameraMove: getMarkerPosition,
                                  onCameraIdle: updateMarkerPosition,
                                  markers: {
                                    if (mapProvider.markers != null) ...mapProvider.markers!,
                                    ...mapProvider.markersPickup!,
                                    ...mapProvider.markersFinal!
                                  },
                                  polylines: mapProvider.polylines!,
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          if (mapProvider.mapAction == MapAction.selectTrip)
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
                            if (mapProvider.remoteAddress != null && mapProvider.remoteAddress!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  mapProvider.remoteAddress!,
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
