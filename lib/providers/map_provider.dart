import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constant.dart';
import '../models/map_action.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';

class MapProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _dbService = DatabaseService();
  GlobalKey<ScaffoldState>? _scaffoldKey;
  GoogleMapController? _controller;
  Set<Marker>? _markers;
  Set<Marker>? _markersPickup;
  MapAction? _mapAction;
  Marker? _remoteMarker;
  BitmapDescriptor? _selectionPin;
  BitmapDescriptor? _carPin;
  BitmapDescriptor? _personPin;
  Set<Polyline>? _polylines;
  double? _cost;
  String? _remoteAddress;
  String? _deviceAddress;
  String? _draggedAddress;
  double? _distance;
  LatLng? _draggedLatlng;
  LatLng? _remoteLocation;
  LatLng? _deviceLocation;
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
  Set<Marker>? get markersPickup => _markersPickup;
  Marker? get remoteMarker => _remoteMarker!;
  MapAction? get mapAction => _mapAction;
  BitmapDescriptor? get selectionPin => _selectionPin;
  BitmapDescriptor? get personPin => _personPin;
  BitmapDescriptor? get carPin => _carPin;
  LatLng? get draggedLatlng => _draggedLatlng;
  LatLng? get deviceLocation => _deviceLocation;
  LatLng? get remoteLocation => _remoteLocation;
  String? get remoteAddress => _remoteAddress;
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
    _remoteAddress = null;
    _draggedLatlng = null;
    _draggedAddress = null;
    _deviceAddress = null;
    _cost = null;
    _distance = null;
    _cameraPos = null;
    _markers = {};
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

  Future<void> initializeMap({GlobalKey<ScaffoldState>? scaffoldKey}) async {
    LatLng? cameraLatLng;

    // Request location permission
    final status = await Permission.location.request();

    if (status.isPermanentlyDenied) {
      showDialog(
        context: _scaffoldKey!.currentContext!,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text(
              'Location permission is permanently disabled. Enable it from app settings',
            ),
            actions: [
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open App Settings'),
              ),
            ],
          );
        },
      );
    } else if (status.isDenied) {
      // Handle the case when the user denied location permission
      // You can show a message or take appropriate action here.
    } else if (status.isGranted) {
      // Location permission granted, proceed with your map initialization
      cameraLatLng = const LatLng(17.6168, 121.7230);
      setCameraPosition(cameraLatLng);
      notifyListeners();
    }
  }

  Future<void> _getAddress(LatLng position) async {
    //this will list down all address around the position
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark address = placemarks[0]; // get only first and closest address
    String addresStr =
        "${address.street}, ${address.locality}, ${address.administrativeArea}, ${address.country}";
    _draggedAddress = addresStr;
    notifyListeners();
  }

  void setPickupLocation(double latitude, double longitude) {
    _deviceLocation = LatLng(latitude, longitude);
  }

  Future<void> setDeviceLocationAddress(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            "${place.name}, ${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        _deviceAddress = address;
        print(_deviceAddress);
        notifyListeners();
      } else {
        print("No address found for the given coordinates.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  void moveCameraToDestination(
    LatLng latLng,
  ) {
    animateCameraToPos(
      LatLng(latLng.latitude, latLng.longitude),
      15,
    );
    print('Latitude: ${latLng.latitude}');
    print('Longitude: ${latLng.longitude}');

    onTap(latLng);
  }

  void useDeviceLocation(double latitude, double longitude) {
    setPickupLocation(latitude, longitude);
  }

  void moveCameraToPickup(LatLng latLng) async {
    _markersPickup!.clear();
    print('Latitude: ${latLng.latitude}');
    print('Longitude: ${latLng.longitude}');

    // Use the custom BitmapDescriptor for the pickup marker
    final customPin = _personPin!; // Replace with the appropriate custom pin

    // Add the marker to the map using the MapProvider's addMarker function
    addMarkerPickup(
      latLng,
      customPin,
    );

    // Set the device location to the pickup location's LatLng
    setPickupLocation(latLng.latitude, latLng.longitude);

    // Set the device location address
    await setDeviceLocationAddress(latLng.latitude, latLng.longitude);
  }

  void setCameraPosition(LatLng latLng, {double zoom = 15}) {
    _cameraPos = CameraPosition(
      target: LatLng(latLng.latitude, latLng.longitude),
      zoom: zoom,
    );
  }

  void pickupLocation(LatLng pos) async {
    if (mapAction == MapAction.selectTrip ||
        mapAction == MapAction.tripSelected) {
      addMarkerPickup(pos, _personPin!);
    }
  }

  void onTap(LatLng pos) async {
    if (mapAction == MapAction.selectTrip ||
        mapAction == MapAction.tripSelected) {
      clearRoutes();

      changeMapAction(MapAction.tripSelected);
      addMarker(pos, _selectionPin!);
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 500), () async {
        await setRemoteAddress(pos);

        if (_deviceLocation != null) {
          PolylineResult polylineResult = await setPolyline(pos);
          calculateDistance(polylineResult.points);
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
      onDragEnd: (LatLng newPos) async {
        await updateMarkerPos(newPos);
      },
      rotation: heading ?? 0.0,
      icon: pin,
      zIndex: 3,
    );

    _markersPickup!.add(newMarker);
    _remoteMarker = newMarker;
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
      onDragEnd: (LatLng newPos) async {
        await updateMarkerPos(newPos);
      },
      rotation: heading ?? 0.0,
      icon: pin,
      zIndex: 3,
    );

    _markers!.add(newMarker);
    _remoteMarker = newMarker;
  }

  Future<void> updateMarkerPos(LatLng newPos) async {
    if (mapAction == MapAction.tripSelected) {
      Marker marker = _remoteMarker!;
      clearRoutes();
      _markers!.remove(marker);
      marker = marker.copyWith(positionParam: newPos);
      _markers!.add(marker);
      _remoteMarker = marker;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 500), () async {
        await setRemoteAddress(newPos);

        if (_deviceLocation != null) {
          PolylineResult polylineResult = await setPolyline(newPos);
          calculateDistance(polylineResult.points);
          calculateCost();
        }

        notifyListeners();
      });
    }
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
          color: Colors.black,
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

  Future<void> updateRoutes() async {
    PolylineResult result = await setPolyline(_remoteLocation!);
    if (_remoteLocation != null) {
      calculateDistance(result.points);
      notifyListeners();
    }
  }

  Future<void> setRemoteAddress(LatLng pos) async {
    _remoteLocation = pos;

    List<Placemark> places = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );

    if (places.isNotEmpty) {
      Placemark firstPlace = places.first;
      String address = firstPlace.thoroughfare ?? '';
      if (firstPlace.subThoroughfare != null) {
        address = '${firstPlace.subThoroughfare}, $address';
      }
      if (firstPlace.locality != null) {
        address = '$address, ${firstPlace.locality}';
      }
      if (firstPlace.administrativeArea != null) {
        address = '$address, ${firstPlace.administrativeArea}';
      }
      if (firstPlace.postalCode != null) {
        address = '$address ${firstPlace.postalCode}';
      }
      if (firstPlace.country != null) {
        address = '$address, ${firstPlace.country}';
      }

      _remoteAddress = address;
      print(_remoteLocation);
    } else {
      _remoteAddress = "Address not found";
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

  void calculateCost() {
    _cost = _distance! * 50;
  }

  void clearRoutes([bool shouldClearDistanceCost = true]) {
    _markers!.clear();
    _polylines!.clear();
    _remoteMarker = null;
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

  void resetMapAction() {
    _mapAction = MapAction.selectTrip;
  }

  void changeMapAction(MapAction mapAction) {
    _mapAction = mapAction;
  }

  void setOngoingTrip(Trip trip) {
    _ongoingTrip = trip;
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

  void triggerReachedDestination() {
    changeMapAction(MapAction.reachedDestination);
    clearRoutes(false);

    notifyListeners();
    animateCameraToPos(
      LatLng(_deviceLocation!.latitude, _deviceLocation!.longitude),
      17,
    );
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
        triggerTripCompleted();
      } else if (trip.reachedDestination != null && trip.reachedDestination!) {
        triggerReachedDestination();
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

  void cancelTrip() {
    resetMapAction();
    _markersPickup!.clear;
    _markers!.clear;

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
