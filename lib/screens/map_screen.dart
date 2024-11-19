import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trissea/models/map_action.dart';
import 'package:trissea/models/trip_model.dart';
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
import 'package:trissea/providers/user_provider.dart';

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
  bool _hasCheckedBooking = false;

  @override
  void initState() {
    super.initState();
    print('🎬 MapScreen initState called');
    _mapProvider = Provider.of<MapProvider>(context, listen: false);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Basic map initialization
      _mapProvider?.setScaffoldKey(_scaffoldKey);
      _mapProvider?.initializeMap(scaffoldKey: _scaffoldKey);
      
      if (!_hasCheckedBooking) {
        await _checkActiveBooking();
        _hasCheckedBooking = true;
      }
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
    print('📍 Location selected at: $_draggedLatlng');
    _mapProvider!.changeMapAction(MapAction.tripSelected);
    _mapProvider!.onTap(_draggedLatlng);
    print('🎯 MapAction after selection: ${_mapProvider!.mapAction}');
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
    return Consumer2<MapProvider, UserProvider>(
      builder: (BuildContext context, mapProvider, userProvider, _) {
        print('🎯 Current MapAction: ${mapProvider.mapAction}');
        print('📦 Active Booking: ${userProvider.activeBooking != null}');
        
        // Schedule the state updates for the next frame
        if (userProvider.activeBooking != null && mapProvider.ongoingTrip == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleActiveBooking(mapProvider, userProvider.activeBooking!);
          });
        }
        
        final bool showSelectionUI = mapProvider.mapAction == MapAction.selectTrip && 
                                   userProvider.activeBooking == null;
        
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
                          if (showSelectionUI)
                            SearchLocationWidget(mapProvider: mapProvider),
                          FloatingDrawerBarButton(scaffoldKey: _scaffoldKey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (showSelectionUI)
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

  Future<void> _checkActiveBooking() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    print('⏳ Waiting for user data to load...');
    while (userProvider.loggedUser == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('👤 User ID: ${userProvider.loggedUser?.id}');
    await userProvider.checkActiveBooking(userProvider.loggedUser!.id!);
    
    if (userProvider.activeBooking != null) {
      print('📦 Active booking found:');
      print('   - ID: ${userProvider.activeBooking?.id}');
      
      final trip = userProvider.activeBooking!;
      _mapProvider?.setOngoingTrip(trip);
      _mapProvider?.startListeningToTrip();
      
      // Update map action based on trip status
      if (trip.tripCompleted == true) {
        _mapProvider?.triggerFeedback();
      } else if (trip.reachedFinalDestination == true) {
        _mapProvider?.changeMapAction(MapAction.reachedFinalDestination);
      } else if (trip.started == true) {
        _mapProvider?.changeMapAction(MapAction.tripStarted);
      } else if (trip.arrived == true) {
        _mapProvider?.changeMapAction(MapAction.driverArrived);
      } else if (trip.accepted == true) {
        _mapProvider?.changeMapAction(MapAction.driverArriving);
        _mapProvider?.startListeningToDriver();  // Start listening to driver updates
      } else {
        _mapProvider?.changeMapAction(MapAction.searchDriver);
      }

      // Force a rebuild to reflect the new state
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Add this method to handle active booking updates
  void _handleActiveBooking(MapProvider mapProvider, Trip trip) {
    mapProvider.setOngoingTrip(trip);
    mapProvider.startListeningToTrip();
    
    if (trip.tripCompleted == true) {
      mapProvider.changeMapAction(MapAction.feedbackPage);
    } else if (trip.reachedFinalDestination == true) {
      mapProvider.changeMapAction(MapAction.reachedFinalDestination);
    } else if (trip.started == true) {
      mapProvider.changeMapAction(MapAction.tripStarted);
    } else if (trip.arrived == true) {
      mapProvider.changeMapAction(MapAction.driverArrived);
    } else if (trip.accepted == true) {
      mapProvider.changeMapAction(MapAction.driverArriving);
    } else {
      mapProvider.changeMapAction(MapAction.searchDriver);
    }
  }
}
