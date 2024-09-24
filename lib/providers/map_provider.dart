import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_geocoding_api/google_geocoding_api.dart';
import 'package:map_location_picker/map_location_picker.dart';

import 'package:uuid/uuid.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constant.dart';
import '../models/map_action.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

class MapProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();
  final LocationService _locationService = LocationService();
  GlobalKey<ScaffoldState>? _scaffoldKey;
  Future<GoogleMapController>? mapController;
  GoogleMapController? _controller;
  Set<Marker>? _markers;
  Set<Marker>? _markersFinal;
  Set<Marker>? _markersPickup;
  MapAction? _mapAction;
  Marker? _pickupMarker;
  Marker? _remoteMarker;
  Marker? _finalMarker;
  BitmapDescriptor? _selectionPin;
  BitmapDescriptor? _carPin;
  BitmapDescriptor? _personPin;
  Set<Polyline>? _polylines;
  double? _cost;
  String? _remoteAddress;
  String? _finalAddress;
  String? _deviceAddress;
  String? _draggedAddress;
  double? _distance;
  LatLng? _draggedLatlng;
  LatLng? _remoteLocation;
  LatLng? _finalLocation;
  Position? _deviceLocation;
  CameraPosition? _cameraPos;
  Trip? _ongoingTrip;
  Timer? _tripCancelTimer;
  StreamSubscription<Trip>? _tripStream;
  StreamSubscription<User>? _driverStream;
  StreamSubscription<Position>? _positionStream;
  bool _driverArrivingInit = false;

  GlobalKey<ScaffoldState>? get scaffoldKey => _scaffoldKey;
  CameraPosition? get cameraPos => _cameraPos;
  GoogleMapController? get controller => _controller;
  Set<Marker>? get markers => _markers;
  Set<Marker>? get markersFinal => _markersFinal;
  Set<Marker>? get markersPickup => _markersPickup;
  Marker? get pickupMarker => _pickupMarker!;
  Marker? get remoteMarker => _remoteMarker!;
  Marker? get finalMarker => _finalMarker!;
  MapAction? get mapAction => _mapAction;
  BitmapDescriptor? get selectionPin => _selectionPin;
  BitmapDescriptor? get personPin => _personPin;
  BitmapDescriptor? get carPin => _carPin;
  LatLng? get draggedLatlng => _draggedLatlng;
  Position? get deviceLocation => _deviceLocation;
  LatLng? get remoteLocation => _remoteLocation;
  LatLng? get finalLocation => _finalLocation;
  String? get remoteAddress => _remoteAddress;
  String? get finalAddress => _finalAddress;
  String? get deviceAddress => _deviceAddress;
  String? get draggedAddress => _draggedAddress;
  Set<Polyline>? get polylines => _polylines;
  double? get cost => _cost;
  double? get distance => _distance;
  Trip? get ongoingTrip => _ongoingTrip;
  Timer? get tripCancelTimer => _tripCancelTimer;
  StreamSubscription<Trip>? get tripStream => _tripStream;
  StreamSubscription<User>? get driverStream => _driverStream;
  StreamSubscription<Position>? get positionStream => _positionStream;

  MapProvider() {
    _scaffoldKey = null;
    _mapAction = MapAction.selectTrip;
    _deviceLocation = null;
    _remoteLocation = null;
    _finalLocation = null;
    _remoteAddress = null;
    _finalAddress = null;
    _draggedLatlng = null;
    _draggedAddress = null;
    _deviceAddress = null;
    _cost = null;
    _distance = null;
    _cameraPos = null;
    _markers = {};
    _markersFinal = {};
    _markersPickup = {};
    _polylines = {};
    _ongoingTrip = null;
    _tripCancelTimer = null;
    _tripStream = null;
    _driverStream = null;
    _positionStream = null;
    setCustomPin();
  }

  Future<void> setCustomPin() async {
    _selectionPin = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 1, size: Size(20, 20)),
      'images/pin.png',
    );
    _carPin = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2.5),
      'images/car.png',
    );
    _personPin = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(
        devicePixelRatio: 2.5,
      ),
      'images/map-person.png',
    );
  }

  void setScaffoldKey(GlobalKey<ScaffoldState> scaffoldKey) {
    _scaffoldKey = scaffoldKey;
  }

  Future<void> initializeMap({GlobalKey<ScaffoldState>? scaffoldKey}) async {
  Position? deviceLocation;
  LatLng? cameraLatLng;

  // Ensure scaffoldKey is not null before using it
  if (scaffoldKey != null) {
    setScaffoldKey(scaffoldKey);

    if (kDebugMode) {
      print('scaffold: $scaffoldKey');
    }

    if (await _locationService.checkLocationIfPermanentlyDisabled()) {
      // Use the scaffoldKey safely
      showDialog(
        context: scaffoldKey.currentContext!,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text(
              'Location permission is permanently disabled. Enable it from app settings',
            ),
            actions: [
              TextButton(
                onPressed: () => Geolocator.openAppSettings(),
                child: const Text('Open App Settings'),
              ),
            ],
          );
        },
      );
    } else {
      if (await _locationService.checkLocationPermission()) {
        try {
          deviceLocation = await _locationService.getLocation();
          cameraLatLng = LatLng(
            deviceLocation.latitude,
            deviceLocation.longitude,
          );
          setDeviceLocation(deviceLocation);
          setDeviceLocationAddress(
            deviceLocation.latitude,
            deviceLocation.longitude,
          );
          addMarkerPickup(cameraLatLng, _personPin!);

          // Cancel the position stream if it exists
          _positionStream?.cancel();
          // Listen to position stream after cancelation
          listenToPositionStream();
        } catch (error) {
          // Specific error handling can be added here
          if (kDebugMode) {
            print('Unable to get device location: $error');
          }
        }
      }
    }
  }

  // Use default LatLng if deviceLocation is null
  cameraLatLng ??= const LatLng(37.42227936982647, -122.08611108362673);

  // Set camera position
  setCameraPosition(cameraLatLng);

  // Notify listeners after all necessary state updates
  notifyListeners();
}


  void setDeviceLocation(Position location) {
    _deviceLocation = location;
  }

Future<void> setDeviceLocationAddress(double latitude, double longitude) async {
  const bool isDebugMode = true;
  final api = GoogleGeocodingApi(googleMapApi, isLogged: isDebugMode);
  try {
    final reversedSearchResults  = await api.reverse(
      '$latitude,$longitude',
    );

      final formattedAddress = reversedSearchResults.results.firstOrNull?.mapToPretty();

      if (kDebugMode) {
        print('formattedAddress: ${formattedAddress?.streetName}, ${formattedAddress?.city}');
      }
      notifyListeners();
  } catch (e) {
    if (kDebugMode) {
      print('Error: $e');
    }
  }
}




  void onMapCreated(GoogleMapController controller) {
    _controller = controller;
    mapController = Future.value(controller);
  }

  void moveCameraToDestination(
    LatLng latLng,
  ) {
    animateCameraToPos(
      LatLng(latLng.latitude, latLng.longitude),
      15,
    );
    if (kDebugMode) {
      print('moving Latitude: ${latLng.latitude}');
    }
    if (kDebugMode) {
      print('moving Longitude: ${latLng.longitude}');
    }

    onTap(latLng);
  }

  void setCameraPosition(LatLng latLng, {double zoom = 15}) {
    _cameraPos = CameraPosition(
      target: LatLng(latLng.latitude, latLng.longitude),
      zoom: zoom,
    );
  }


  void onTap(LatLng pos) async {
    if (mapAction == MapAction.selectTrip ||
        mapAction == MapAction.tripSelected) {
          
      if (kDebugMode) {
        print(mapAction);
      }
      addMarker(pos, _selectionPin!);
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 500), () async {

        if (_deviceLocation != null || _finalLocation == null) {
          PolylineResult polylineResult = await setPolyline(pos);
          calculateDistance(polylineResult.points);
          calculateCost();
        }

        notifyListeners();
      });
    }
  }
  void setFinalLocation(LatLng pos) async {
    if (mapAction == MapAction.selectTrip ||
        mapAction == MapAction.tripSelected) {
      if (kDebugMode) {
        print(mapAction);
      }
      addFinalMarker(pos, _selectionPin!);
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 500), () async {
        await setFinalAddress(pos);

        if (_remoteLocation != null || _finalLocation != null) {
          List<PolylineResult> polylineResult = await setPolylineFinal();
           calculateDistanceFinal(polylineResult);
          calculateCost();
        }

        notifyListeners();
      });
    }
  }


  void listenToPositionStream() {
    _positionStream = LocationService().getRealtimeDeviceLocation().listen(
      (Position pos) {
        setDeviceLocationAddress(
          pos.latitude,
          pos.longitude,
        );

        if ((mapAction == MapAction.tripSelected ||
                mapAction == MapAction.searchDriver ||
                mapAction == MapAction.tripStarted) &&
            _remoteLocation != null) updateRoutes();
      },
    );
  }

  void stopListenToPositionStream() {
    _positionStream!.cancel();
    _positionStream = null;
  }

  void addMarkerPickup(
    LatLng latLng,
    BitmapDescriptor pin, {
    bool isDraggable = true,
    double? heading,
  }) {
    final String markerId = const Uuid().v4();
    final Marker newMarker = Marker(
      markerId: MarkerId(markerId),
      position: latLng,
      draggable: isDraggable,
      onDrag: (v) {},
      onDragStart: (v) {},
      rotation: heading ?? 0.0,
      icon: pin,
      zIndex: 3,
    );

    _markersPickup!.add(newMarker);
    _pickupMarker = newMarker;
  }

  // Other functions with null safety checks and error handling...

  void addMarker(
    LatLng latLng,
    BitmapDescriptor pin, {
    bool isDraggable = true,
    double? heading,
  }) {
    final String markerId = const Uuid().v4();
    final Marker newMarker = Marker(
      markerId: MarkerId(markerId),
      position: latLng,
      draggable: isDraggable,
      onDrag: (v) {},
      onDragStart: (v) {},
      rotation: heading ?? 0.0,
      icon: pin,
      zIndex: 3,
    );
    _markers!.clear();
    _markers!.add(newMarker);
    _remoteMarker = newMarker;
  }

  void addFinalMarker(
    LatLng latLng,
    BitmapDescriptor pin, {
    bool isDraggable = true,
    double? heading,
  }) {
    final String markerId = const Uuid().v4();
    final Marker newMarker = Marker(
      markerId: MarkerId(markerId),
      position: latLng,
      draggable: isDraggable,
      onDrag: (v) {},
      onDragStart: (v) {},
      rotation: heading ?? 0.0,
      icon: pin,
      zIndex: 3,
    );

    _markersFinal!.add(newMarker);
    _finalMarker = newMarker;
  }

  void toggleMarkerDraggable() {
    _markers!.remove(_remoteMarker);
    _remoteMarker = _remoteMarker!.copyWith(
      draggableParam: false,
    );
    _markers!.add(_remoteMarker!);
  }

  Future<PolylineResult> setPolyline(
    LatLng remotePoint,
  ) async {
    _polylines!.clear();

    PolylineResult result = await PolylinePoints().getRouteBetweenCoordinates(
      googleMapApi,
      PointLatLng(remotePoint.latitude, remotePoint.longitude),
      PointLatLng(_deviceLocation!.latitude, _deviceLocation!.longitude),
    );

    if (result.points.isNotEmpty) {
      final String polylineId = const Uuid().v4();

      _polylines!.add(
        Polyline(
          polylineId: PolylineId(polylineId),
          color: const Color.fromARGB(255, 255, 255, 255),
          points: result.points
              .map((PointLatLng point) =>
                  LatLng(point.latitude, point.longitude))
              .toList(),
          width: 4,
        ),
      );
    }

    return result;
  }

  Future<List<PolylineResult>> setPolylineFinal() async {
  _polylines!.clear();

  // Add polylines for device to remote and remote to final locations
  PolylineResult result1 = await PolylinePoints().getRouteBetweenCoordinates(
    googleMapApi,
    PointLatLng(_deviceLocation!.latitude, _deviceLocation!.longitude),
    PointLatLng(_remoteLocation!.latitude, _remoteLocation!.longitude),
  );

  PolylineResult result2 = await PolylinePoints().getRouteBetweenCoordinates(
    googleMapApi,
    PointLatLng(_remoteLocation!.latitude, _remoteLocation!.longitude),
    PointLatLng(_finalLocation!.latitude, _finalLocation!.longitude),
  );

  // Add polyline for device to remote location
  if (result1.points.isNotEmpty) {
    final String polylineId1 = const Uuid().v4();
    _polylines!.add(
      Polyline(
        polylineId: PolylineId(polylineId1),
        color: Colors.black,
        points: result1.points
            .map((PointLatLng point) => LatLng(point.latitude, point.longitude))
            .toList(),
        width: 4,
      ),
    );
  }

  // Add polyline for remote to final location
  if (result2.points.isNotEmpty) {
    final String polylineId2 = const Uuid().v4();
    _polylines!.add(
      Polyline(
        polylineId: PolylineId(polylineId2),
        color: Colors.black,
        points: result2.points
            .map((PointLatLng point) => LatLng(point.latitude, point.longitude))
            .toList(),
        width: 4,
      ),
    );
  }
  if (kDebugMode) {
    print("polylines: $_polylines");
  }
  return [result1, result2];
}



  Future<void> updateRoutes() async {
    if(_finalLocation == null){
    PolylineResult result = await setPolyline(_remoteLocation!);
    if (_remoteLocation != null) {
      calculateDistance(result.points);
      notifyListeners();
    }
    }else{
      List<PolylineResult> polylineResult = await setPolylineFinal();
           calculateDistanceFinal(polylineResult);
          calculateCost();

    }
  }

  Future<void> setRemoteAddress(LatLng pos) async {
  _remoteLocation = pos;

  const bool isDebugMode = true;
  final api = GoogleGeocodingApi(googleMapApi, isLogged: isDebugMode);
  addMarker(pos, _selectionPin!);
  
  try {
    final reversedSearchResults = await api.reverse(
      '${pos.latitude},${pos.longitude}',
    );

    final remoteFormattedAddress = reversedSearchResults.results.firstOrNull?.mapToPretty();
    
    // Check if street name is null
    if (remoteFormattedAddress?.streetName == null) {
      LatLng adjustedPos = pos;
      bool foundStreet = false;
      
      // Loop to adjust coordinates and find the nearest street
      while (!foundStreet) { // Limiting iterations to prevent infinite loop
        // Adjust coordinates
        adjustedPos = LatLng(adjustedPos.latitude + 0.001, adjustedPos.longitude + 0.001);
        
        // Make a reverse geocoding request with adjusted coordinates
        final adjustedReversedSearchResults = await api.reverse(
          '${adjustedPos.latitude},${adjustedPos.longitude}',
        );
        
        // Get formatted address from the adjusted results
        final adjustedRemoteFormattedAddress = adjustedReversedSearchResults.results.firstOrNull?.mapToPretty();

        // Check if street name is found
        if (adjustedRemoteFormattedAddress?.streetName != null) {
          _remoteAddress = "Near ${adjustedRemoteFormattedAddress?.streetName}";
          foundStreet = true;
        }
      }
    } else {
      // Street name is found in the original results
      _remoteAddress = remoteFormattedAddress?.streetName ?? '';
    }

    // Concatenate street number and city
    String streetNumber = remoteFormattedAddress?.streetNumber ?? '';
    String city = remoteFormattedAddress?.city ?? '';

    _remoteAddress = '$streetNumber $_remoteAddress, $city';

    if (kDebugMode) {
      print('remoteFormattedAddress: ${remoteFormattedAddress?.streetName}, ${remoteFormattedAddress?.city}');
    }
    notifyListeners();
  } catch (e) {
    if (kDebugMode) {
      print('Error: $e');
    }
  }
}


  
  Future<void> setFinalAddress(LatLng pos) async {
    _finalLocation = pos;

    const bool isDebugMode = true;
  final api = GoogleGeocodingApi(googleMapApi, isLogged: isDebugMode);
  
  try {
    final reversedSearchResults = await api.reverse(
      '${pos.latitude},${pos.longitude}',
    );

    final remoteFormattedAddress = reversedSearchResults.results.firstOrNull?.mapToPretty();
    
    // Check if street name is null
    if (remoteFormattedAddress?.streetName == null) {
      LatLng adjustedPos = pos;
      bool foundStreet = false;
      
      // Loop to adjust coordinates and find the nearest street
      while (!foundStreet) {
        // Adjust coordinates
        adjustedPos = LatLng(adjustedPos.latitude + 0.011, adjustedPos.longitude + 0.011);
        
        // Make a reverse geocoding request with adjusted coordinates
        final adjustedReversedSearchResults = await api.reverse(
          '${adjustedPos.latitude},${adjustedPos.longitude}',
        );
        
        // Get formatted address from the adjusted results
        final adjustedRemoteFormattedAddress = adjustedReversedSearchResults.results.firstOrNull?.mapToPretty();

        // Check if street name is found
        if (adjustedRemoteFormattedAddress?.streetName != null) {
          _remoteAddress = adjustedRemoteFormattedAddress?.streetName ?? '';
          foundStreet = true;
        }
      }
    } else {
      // Street name is found in the original results
      _remoteAddress = remoteFormattedAddress?.streetName ?? '';
    }

    // Concatenate street number and city
    String streetNumber = remoteFormattedAddress?.streetNumber ?? '';
    String city = remoteFormattedAddress?.city ?? '';

    _remoteAddress = '$streetNumber $_remoteAddress, $city';

    if (kDebugMode) {
      print('remoteFormattedAddress: ${remoteFormattedAddress?.streetName}, ${remoteFormattedAddress?.city}');
    }
    notifyListeners();
  } catch (e) {
    if (kDebugMode) {
      print('Error: $e');
    }
  }
  }

  void calculateDistance(List<PointLatLng> points) {
    double distance = 0;

    for (int i = 0; i < points.length - 1; i++) {
      distance += Geolocator.distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }

    _distance = distance / 1000;
  }

  void calculateDistanceFinal(List<PolylineResult> polylineResults) {
  double distance = 0;

  for (PolylineResult result in polylineResults) {
    if (result.points.isNotEmpty) {
      for (int i = 0; i < result.points.length - 1; i++) {
        distance += Geolocator.distanceBetween(
          result.points[i].latitude,
          result.points[i].longitude,
          result.points[i + 1].latitude,
          result.points[i + 1].longitude,
        );
      }
    }
  }

  _distance = distance / 1000;
}

  void calculateCost() {
    double calculatedCost = _distance! * 20;
    _cost = calculatedCost.clamp(20, 100);
}

  void clearRoutes([bool shouldClearDistanceCost = true]) {
    _markers!.clear();
    _markersFinal!.clear();
    _polylines!.clear();
    _remoteMarker = null;
    _finalMarker = null;
    if (shouldClearDistanceCost) {
      _distance = null;
      _cost = null;
    }
    clearRemoteAddress();
  }

  void clearRemoteAddress() {
    _remoteAddress = null;
    _remoteLocation = null;
  }
  void clearFinalAddress() {
    _finalAddress = null;
    _finalLocation = null;
  }

  void resetMapAction() {
    _mapAction = MapAction.selectTrip;
  }

  void changeMapAction(MapAction mapAction) {
    _mapAction = mapAction;
    notifyListeners();
  }

  void setOngoingTrip(Trip trip) {
    _ongoingTrip = trip;
  }

  void setFeedback(double feedback, String comment) async {
    if (_ongoingTrip != null) {
      _ongoingTrip!.rate = feedback;

      // Update Firestore document with the new feedback
      await _firestore
          .collection('trips')
          .doc(_ongoingTrip!.id)
          .update({'feedback': feedback, 'comment': comment,});

      // Notify listeners if necessary
      notifyListeners();
    }
  }

  void setReport(String report) async {
    if (_ongoingTrip != null) {
      _ongoingTrip!.report = report;

      // Update Firestore document with the new feedback
      await _firestore
          .collection('trips')
          .doc(_ongoingTrip!.id)
          .update({'report': report});

      // Notify listeners if necessary
      notifyListeners();
    }
  }

  void startListeningToDriver() {
    _driverStream = _dbService.getDriver$(_ongoingTrip!.driverId!).listen(
      (User driver) async {
        if (driver.userLatitude != null && driver.userLongitude != null) {
          if (mapAction == MapAction.driverArriving && !_driverArrivingInit) {
            animateCameraToBounds(
              firstPoint: LatLng(
                _deviceLocation!.latitude,
                _deviceLocation!.longitude,
              ),
              secondPoint: LatLng(driver.userLatitude!, driver.userLongitude!),
              padding: 120,
            );
            _driverArrivingInit = true;
          }

          clearRoutes(false);
          addMarker(
            LatLng(driver.userLatitude!, driver.userLongitude!),
            _carPin!,
            isDraggable: false,
            heading: driver.heading,
          );
          notifyListeners();

          PolylineResult polylineResult = await setPolyline(
            LatLng(
              driver.userLatitude!,
              driver.userLongitude!,
            ),
          );
          calculateDistance(polylineResult.points);

          notifyListeners();
        }
      },
    );
  }

  Stream<String> getDriverNameById$() {
    return _firestore
        .collection('drivers')
        .doc(_ongoingTrip!.driverId!)
        .snapshots()
        .map((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        final driverData = snapshot.data() as Map<String, dynamic>;
        final driverName = driverData['driverName'] as String;
        return driverName;
      } else {
        // Handle the case where no driver with the specified ID is found
        throw Exception('Driver not found');
      }
    });
  }

  void stopListeningToDriver() {
    _driverStream!.cancel();
    _driverStream = null;
  }

  void triggerDriverArriving() {
    changeMapAction(MapAction.driverArriving);
    stopAutoCancelTimer();
    startListeningToDriver();

    notifyListeners();
  }

  void triggerDriverArrived() {
    changeMapAction(MapAction.driverArrived);
    stopListeningToDriver();
    _polylines!.clear();

    notifyListeners();

    animateCameraToPos(
      LatLng(_deviceLocation!.latitude, _deviceLocation!.longitude),
      17,
    );
  }

  Future<void> triggerTripStarted() async {
    clearRoutes(false);
    changeMapAction(MapAction.tripStarted);
    addMarker(
      LatLng(
        _ongoingTrip!.destinationLatitude!,
        _ongoingTrip!.destinationLongitude!,
      ),
      _selectionPin!,
      isDraggable: false,
    );

    await setRemoteAddress(
      LatLng(
        _ongoingTrip!.destinationLatitude!,
        _ongoingTrip!.destinationLongitude!,
      ),
    );

    if (_deviceLocation != null) {
      PolylineResult polylineResult = await setPolyline(
        LatLng(
          _ongoingTrip!.destinationLatitude!,
          _ongoingTrip!.destinationLongitude!,
        ),
      );
      calculateDistance(polylineResult.points);
    }

    notifyListeners();

    animateCameraToBounds(
      firstPoint: LatLng(
        _deviceLocation!.latitude,
        _deviceLocation!.longitude,
      ),
      secondPoint: LatLng(
        _ongoingTrip!.destinationLatitude!,
        _ongoingTrip!.destinationLongitude!,
      ),
      padding: 150,
    );
  }

  Future<void> triggerTripToFinalStarted() async {
    clearRoutes(false);
    changeMapAction(MapAction.tripStarted);
    addMarker(
      LatLng(
        _ongoingTrip!.finalDestinationLatitude!,
        _ongoingTrip!.finalDestinationLongitude!,
      ),
      _selectionPin!,
      isDraggable: false,
    );

    await setRemoteAddress(
      LatLng(
        _ongoingTrip!.finalDestinationLatitude!,
        _ongoingTrip!.finalDestinationLongitude!,
      ),
    );

    if (_deviceLocation != null) {
      PolylineResult polylineResult = await setPolyline(
        LatLng(
          _ongoingTrip!.finalDestinationLatitude!,
          _ongoingTrip!.finalDestinationLongitude!,
        ),
      );
      calculateDistance(polylineResult.points);
    }

    notifyListeners();

    animateCameraToBounds(
      firstPoint: LatLng(
        _deviceLocation!.latitude,
        _deviceLocation!.longitude,
      ),
      secondPoint: LatLng(
        _ongoingTrip!.finalDestinationLatitude!,
        _ongoingTrip!.finalDestinationLongitude!,
      ),
      padding: 150,
    );
  }

  void triggerReachedDestination() {
    changeMapAction(MapAction.reachedDestination);
    clearRoutes(false);

    notifyListeners();
    animateCameraToPos(
      LatLng(_deviceLocation!.latitude, _deviceLocation!.longitude),
      17,
    );
  }

  void triggerFeedback() {
    changeMapAction(MapAction.feedbackPage);
    notifyListeners();
  }

  void triggerTripCompleted() {
    resetMapAction();
    cancelTrip();
    ScaffoldMessenger.of(_scaffoldKey!.currentContext!).showSnackBar(
      const SnackBar(content: Text('Trip Completed')),
    );

    notifyListeners();
  }

  void startListeningToTrip() {
    if (kDebugMode) {
      print('======== Start litening to trip stream ========');
    }

    _tripStream = _dbService.getTrip$(_ongoingTrip!).listen((Trip trip) {
      if (kDebugMode) {}
      setOngoingTrip(trip);

      if (trip.tripCompleted != null && trip.tripCompleted!) {
        triggerFeedback();
      } else if (trip.reachedDestination != null && trip.reachedDestination!) {
        triggerReachedDestination();
      } else if (trip.arrivedToFinalDestination != null && trip.arrivedToFinalDestination!) {
        triggerTripToFinalStarted();
      } else if (trip.started != null && trip.started!) {
        triggerTripStarted();
      } else if (trip.arrived != null && trip.arrived!) {
        triggerDriverArrived();
      } else if (trip.accepted!) {
        triggerDriverArriving();
      }
    });
  }

  void startListeningToTodaTrip() {
    if (kDebugMode) {
      print('======== Start litening to trip stream ========');
    }

    _tripStream = _dbService.getTodaTrip$(_ongoingTrip!).listen((Trip trip) {
      if (kDebugMode) {}
      setOngoingTrip(trip);

      if (trip.tripCompleted != null && trip.tripCompleted!) {
        triggerFeedback();
      } else if (trip.reachedDestination != null && trip.reachedDestination!) {
        triggerReachedDestination();
      } else if (trip.arrivedToFinalDestination != null && trip.arrivedToFinalDestination!) {
        triggerTripToFinalStarted();
      } else if (trip.started != null && trip.started!) {
        triggerTripStarted();
      } else if (trip.arrived != null && trip.arrived!) {
        triggerDriverArrived();
      } else if (trip.accepted!) {
        triggerDriverArriving();
      }
    });
  }

  void stopListeningToTrip() {
    if (_tripStream != null) {
      _tripStream!.cancel();
      _tripStream = null;
    }
  }

  void triggerAutoCancelTrip({
    VoidCallback? tripDeleteHandler,
    VoidCallback? snackbarHandler,
  }) {
    stopAutoCancelTimer();

    if (kDebugMode) {
      print('======= Set auto cancel trip timer to 100 seconds =======');
    }

    _tripCancelTimer = Timer(
      const Duration(seconds: 60),
      () {
        tripDeleteHandler!();
        cancelTrip();
        snackbarHandler!();
      },
    );
  }

  void stopAutoCancelTimer() {
    if (_tripCancelTimer != null) {
      if (kDebugMode) {
        print('======= Auto cancel timer stopped =======');
      }

      _tripCancelTimer!.cancel();
      _tripCancelTimer = null;
    }
  }

  void confirmTrip(Trip trip) {
    changeMapAction(MapAction.searchDriver);
    toggleMarkerDraggable();
    setOngoingTrip(trip);
    startListeningToTrip();

    notifyListeners();
  }

  void confirmTodaTrip(Trip trip) {
    changeMapAction(MapAction.searchDriver);
    toggleMarkerDraggable();
    setOngoingTrip(trip);
    startListeningToTodaTrip();

    notifyListeners();
  }

  void cancelTrip() {
    resetMapAction();
    _markersPickup!.clear;
    _markers!.clear;
    _markersFinal!.clear;

    clearRoutes();
    _ongoingTrip = null;
    _driverArrivingInit = false;
    stopListeningToTrip();
    stopAutoCancelTimer();

    notifyListeners();
  }

  LatLng getNorthEastLatLng(LatLng firstPoint, LatLng lastPoint) => LatLng(
        firstPoint.latitude >= lastPoint.latitude
            ? firstPoint.latitude
            : lastPoint.latitude,
        firstPoint.longitude >= lastPoint.longitude
            ? firstPoint.longitude
            : lastPoint.longitude,
      );

  LatLng getSouthWestLatLng(LatLng firstPoint, LatLng lastPoint) => LatLng(
        firstPoint.latitude <= lastPoint.latitude
            ? firstPoint.latitude
            : lastPoint.latitude,
        firstPoint.longitude <= lastPoint.longitude
            ? firstPoint.longitude
            : lastPoint.longitude,
      );

  void animateCameraToBounds({
    LatLng? firstPoint,
    LatLng? secondPoint,
    double? padding,
  }) {
    _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          northeast: getNorthEastLatLng(firstPoint!, secondPoint!),
          southwest: getSouthWestLatLng(firstPoint, secondPoint),
        ),
        padding!,
      ),
    );
  }

  void animateCameraToPos(LatLng pos, [double zoom = 15]) {
    _controller!.animateCamera(CameraUpdate.newLatLngZoom(pos, zoom));
  }
}
