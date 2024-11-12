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
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as travel_mode;

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
  Position? _deviceLocation;
  CameraPosition? _cameraPos;
  Trip? _ongoingTrip;
  Timer? _tripCancelTimer;
  StreamSubscription<Trip>? _tripStream;
  StreamSubscription<User>? _driverStream;
  StreamSubscription<Position>? _positionStream;
  bool _driverArrivingInit = false;
  Timer? _geocodingDebounceTimer;
  bool _isAddressSet = false;
  Timer? _deviceAddressDebounceTimer;
  final CollectionReference _specialPriceCollection = FirebaseFirestore.instance.collection('specialPrice');
  double _pricePerKm = 20.0; // Default price if Firebase fetch fails
  String? _specialPriceReason;

  MapAction get mapAction => _mapAction ?? MapAction.selectTrip;

  GlobalKey<ScaffoldState>? get scaffoldKey => _scaffoldKey;
  CameraPosition? get cameraPos => _cameraPos;
  GoogleMapController? get controller => _controller;
  Set<Marker>? get markers => _markers;
  Set<Marker>? get markersFinal => _markersFinal;
  Set<Marker>? get markersPickup => _markersPickup;
  Marker? get pickupMarker => _pickupMarker!;
  Marker? get remoteMarker => _remoteMarker!;
  Marker? get finalMarker => _finalMarker!;
  BitmapDescriptor? get selectionPin => _selectionPin;
  BitmapDescriptor? get personPin => _personPin;
  BitmapDescriptor? get carPin => _carPin;
  LatLng? get draggedLatlng => _draggedLatlng;
  Position? get deviceLocation => _deviceLocation;
  LatLng? get remoteLocation => _remoteLocation;
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
    _selectionPin = await BitmapDescriptor.asset(
      const ImageConfiguration(devicePixelRatio: 0.5, size: Size(5, 5)),
      'images/pin.png',
    );
    _carPin = await BitmapDescriptor.asset(
      const ImageConfiguration(devicePixelRatio: 0.5),
      'images/car.png',
    );
    _personPin = await BitmapDescriptor.asset(
      const ImageConfiguration(
        devicePixelRatio: 0.5,
      ),
      'images/map-person.png',
    );
  }

  void setScaffoldKey(GlobalKey<ScaffoldState> scaffoldKey) {
    _scaffoldKey = scaffoldKey;
  }

  Future<void> initializePrice() async {
    try {
      // Listen to real-time updates
      _specialPriceCollection.doc('current').snapshots().listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          _pricePerKm = (data['price'] ?? 40.0).toDouble();
          _specialPriceReason = data['reason'] as String?;
          
          if (kDebugMode) {
            print('Price per km updated to: $_pricePerKm');
            print('Special price reason: $_specialPriceReason');
          }
          
          notifyListeners();
        }
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching price: $e');
      }
      // Set default values on error
      _pricePerKm = 20.0;
      _specialPriceReason = null;
      notifyListeners();
    }
  }

  Future<void> initializeMap({GlobalKey<ScaffoldState>? scaffoldKey}) async {
    await initializePrice();

    Position? deviceLocation;
    LatLng? cameraLatLng;


      setScaffoldKey(scaffoldKey!);

      if (await _locationService.checkLocationIfPermanentlyDisabled()) {
        // Show dialog for permanently disabled location
        if (scaffoldKey.currentContext != null) {
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
        }
      } else if (await _locationService.checkLocationPermission()) {
        try {
          deviceLocation = await _locationService.getLocation();
          cameraLatLng = LatLng(
            deviceLocation.latitude,
            deviceLocation.longitude,
          );
          
          // Batch state updates
          await Future.microtask(() {
            setDeviceLocation(deviceLocation!);
            addMarkerPickup(cameraLatLng!, _personPin!);
            setCameraPosition(cameraLatLng);
            changeMapAction(MapAction.selectTrip);
            
            // Cancel existing stream before starting new one
            _positionStream?.cancel();
            listenToPositionStream();
          });

          // Handle address update separately
          await setDeviceLocationAddress(
            deviceLocation.latitude,
            deviceLocation.longitude,
          );
        } catch (error) {
          if (kDebugMode) {
            print('Unable to get device location: $error');
          }
        }
      }

    // Use default LatLng if deviceLocation is null
    cameraLatLng ??= const LatLng(37.42227936982647, -122.08611108362673);
    
    // Set camera position
    setCameraPosition(cameraLatLng);
  }

  void setDeviceLocation(Position location) {
    _deviceLocation = location;
  }

  Future<void> setDeviceLocationAddress(double latitude, double longitude) async {
    _deviceAddressDebounceTimer?.cancel();
    _deviceAddressDebounceTimer = Timer(const Duration(seconds: 3), () async {
      try {
        const bool isDebugMode = true;
        final api = GoogleGeocodingApi(googleMapApi, isLogged: isDebugMode);
        
        final reversedSearchResults = await api.reverse(
          '$latitude,$longitude',
        );

        final formattedAddress = reversedSearchResults.results.firstOrNull?.mapToPretty();
        
        if (formattedAddress != null) {
          _deviceAddress = '${formattedAddress.streetName}, ${formattedAddress.city}';
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error setting device address: $e');
        }
      }
    });
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
    if (_positionStream != null) {
        _positionStream!.cancel();
        _positionStream = null;
    }
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
    if (kDebugMode) {
      print('====== Setting Polyline ======');
      print('Remote Point: ${remotePoint.latitude}, ${remotePoint.longitude}');
      print('Device Location: ${_deviceLocation!.latitude}, ${_deviceLocation!.longitude}');
    }

    _polylines!.clear();

    PolylineResult result = await PolylinePoints().getRouteBetweenCoordinates(
      googleApiKey: googleMapApi,
      request: PolylineRequest(
        destination: PointLatLng(remotePoint.latitude, remotePoint.longitude),
        origin: PointLatLng(_deviceLocation!.latitude, _deviceLocation!.longitude),
        mode: travel_mode.TravelMode.driving
      )
    );

    if (kDebugMode) {
      print('Points received: ${result.points.length}');
      print('Status: ${result.status}');
      if (result.errorMessage?.isNotEmpty ?? false) {
        print('Error: ${result.errorMessage}');
      }
    }

    if (result.points.isNotEmpty) {
      final String polylineId = const Uuid().v4();

      if (kDebugMode) {
        print('Creating polyline with ID: $polylineId');
      }

      _polylines!.add(
        Polyline(
          polylineId: PolylineId(polylineId),
          color: Colors.blue,
          points: result.points
              .map((PointLatLng point) =>
                  LatLng(point.latitude, point.longitude))
              .toList(),
          width: 4,
        ),
      );

      if (kDebugMode) {
        print('Polyline added successfully');
        print('Current polylines count: ${_polylines!.length}');
      }
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
    if (_isAddressSet && _remoteLocation == pos) {
      return;
    }

    _remoteLocation = pos;
    addMarker(pos, _selectionPin!);
    
    _geocodingDebounceTimer?.cancel();
    _geocodingDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        const bool isDebugMode = true;
        final api = GoogleGeocodingApi(googleMapApi, isLogged: isDebugMode);
        
        final reversedSearchResults = await api.reverse(
          '${pos.latitude},${pos.longitude}',
        );

        final remoteFormattedAddress = reversedSearchResults.results.firstOrNull?.mapToPretty();
        
        if (remoteFormattedAddress != null) {
          String streetNumber = remoteFormattedAddress.streetNumber;
          String streetName = remoteFormattedAddress.streetName;
          String city = remoteFormattedAddress.city;
          
          _remoteAddress = '$streetNumber $streetName, $city'.trim();
          _isAddressSet = true;
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error setting remote address: $e');
        }
        _remoteAddress = 'Location not found';
        notifyListeners();
      }
    });
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
    double calculatedCost = _distance! * _pricePerKm;
    _cost = calculatedCost.clamp(_pricePerKm, 100);
    notifyListeners();
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
    _isAddressSet = false;
    clearRemoteAddress();
  }

  void clearRemoteAddress() {
    _remoteAddress = null;
    _remoteLocation = null;
    _isAddressSet = false;
  }


  void resetMapAction() {
    _mapAction = MapAction.selectTrip;
  }

  void changeMapAction(MapAction newAction) {
    print('🔄 Changing MapAction from: $_mapAction to: $newAction');
    _mapAction = newAction;
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
    if (_carPin == null) {
      if (kDebugMode) {
        print('Warning: Car pin not initialized');
      }
      return;
    }

    if (_ongoingTrip?.driverId == null) {
      if (kDebugMode) {
        print('Warning: No driver ID available');
      }
      return;
    }

    _driverStream = _dbService.getDriver$(_ongoingTrip!.driverId!).listen(
      (User driver) async {
        if (driver.userLatitude != null && driver.userLongitude != null) {
          if (kDebugMode) {
            print('Driver location updated: ${driver.userLatitude}, ${driver.userLongitude}');
          }

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

          // Clear only driver route, not destination route
          _polylines?.removeWhere((polyline) => polyline.polylineId.value.contains('driver'));

          // Add driver marker with car pin
          addMarker(
            LatLng(driver.userLatitude!, driver.userLongitude!),
            _carPin!,  // Use car pin here
            isDraggable: false,
            heading: driver.heading,
          );

          // Draw polyline from driver to pickup location
          await setPolyline(
            LatLng(driver.userLatitude!, driver.userLongitude!),
          );

          notifyListeners();
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error in driver stream: $error');
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

      if (trip.tripCompleted != true && trip.tripCompleted!) {
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

  Future<void> cancelTrip() async {
    print('🔄 Starting trip cancellation');
    print('📦 Current ongoing trip: $_ongoingTrip');

    if (_ongoingTrip == null) {
      print('⚠️ No ongoing trip to cancel');
      // Just reset the UI state
      resetMapAction();
      _markersPickup?.clear();
      _markers?.clear();
      _markersFinal?.clear();
      clearRoutes();
      notifyListeners();
      return;
    }

    try {
      print('🎯 Canceling trip ID: ${_ongoingTrip!.id}');
      _ongoingTrip!.canceled = true;
      await _dbService.updateTrip(_ongoingTrip!);
      print('✅ Trip updated as canceled in database');
    } catch (e) {
      print('❌ Error canceling trip: $e');
    } finally {
      // Reset state after database update
      resetMapAction();
      _markersPickup?.clear();
      _markers?.clear();
      _markersFinal?.clear();
      clearRoutes();
      _ongoingTrip = null;
      _driverArrivingInit = false;
      stopListeningToTrip();
      stopAutoCancelTimer();

      notifyListeners();
      print('🔄 Map state reset after cancellation');
    }
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

  void updateTripStatus(Trip trip) {
    print('📊 UpdateTripStatus - Current MapAction: $_mapAction');
    print('📊 Trip status - accepted: ${trip.accepted}, started: ${trip.started}, completed: ${trip.tripCompleted}');

    // Preserve searchDriver state
    if (_mapAction == MapAction.searchDriver && !trip.accepted!) {
      print('🔒 Preserving searchDriver state');
      return;
    }

    if (trip.accepted == true) {
      changeMapAction(MapAction.searchDriver);
    } else if (trip.started == true) {
      changeMapAction(MapAction.tripStarted);
    } else if (trip.tripCompleted == true) {
      changeMapAction(MapAction.reachedDestination);
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _geocodingDebounceTimer?.cancel();
    _deviceAddressDebounceTimer?.cancel();
    super.dispose();
  }

  String? get specialPriceReason => _specialPriceReason;
}
