import 'package:flutter/material.dart';
import 'package:trissea/constant.dart';
import 'package:trissea/models/autocomplate_prediction.dart';
import 'package:trissea/models/place_auto_complate_response.dart';
import 'package:trissea/models/placedetails.dart';
import 'package:trissea/providers/map_provider.dart';
import 'package:trissea/services/search_request.dart';
import 'package:trissea/widgets/map_screen_widgets/location_list_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class SearchLocationWidget extends StatefulWidget {
  const SearchLocationWidget({Key? key, this.mapProvider}) : super(key: key);

  final MapProvider? mapProvider;

  @override
  State<SearchLocationWidget> createState() => _SearchLocationWidgetState();
}

class _SearchLocationWidgetState extends State<SearchLocationWidget> {
  TextEditingController pickupSearchController = TextEditingController();
  TextEditingController destinationSearchController = TextEditingController();
  List<AutocompletePrediction> pickupPlacePredictions = [];
  List<AutocompletePrediction> destinationPlacePredictions = [];
  bool showPickupResults = false;
  bool showDestinationResults = false;
  double containerHeight = 400;

  void pickupPlacesAutocomplete(String query) async {
    Uri uri =
        Uri.https("maps.googleapis.com", 'maps/api/place/autocomplete/json', {
      "input": query,
      "key": googleMapApi,
      "components": 'country:ph',
    });
    String? response = await requestSearch.fetchUrl(uri);

    if (response != null) {
      Map<String, dynamic> responseData = json.decode(response);
      PlaceAutocompleteResponse result =
          PlaceAutocompleteResponse.fromJson(responseData);

      if (result.predictions != null) {
        setState(() {
          pickupPlacePredictions = result.predictions!;
          showPickupResults = true;
        });
      }
    }
  }

  void destinationPlacesAutocomplete(String query) async {
    Uri uri =
        Uri.https("maps.googleapis.com", 'maps/api/place/autocomplete/json', {
      "input": query,
      "key": googleMapApi,
      "components": 'country:ph',
    });
    String? response = await requestSearch.fetchUrl(uri);

    if (response != null) {
      Map<String, dynamic> responseData = json.decode(response);
      PlaceAutocompleteResponse result =
          PlaceAutocompleteResponse.fromJson(responseData);

      if (result.predictions != null) {
        setState(() {
          destinationPlacePredictions = result.predictions!;
          showDestinationResults = true;
        });
      }
    }
  }

  void selectPickupLocation(AutocompletePrediction prediction) {
    String placeId = prediction.placeId!;

    if (placeId.isEmpty) {
      print('Selected pickup location is empty');
      return;
    }
    print('Selected pickup location: $placeId');

    moveCameraToSelectedPickUpLocation(context, placeId);

    setState(() {
      showPickupResults = false;
    });
  }

  void selectDestinationLocation(AutocompletePrediction prediction) {
    String placeId = prediction.placeId!;

    if (placeId.isEmpty) {
      print('Selected destination location is empty');
      return;
    }
    print('Selected destination location: $placeId');

    moveCameraToSelectedDestinationLocation(context, placeId);

    setState(() {
      showDestinationResults = false;
    });
  }

  Future<void> moveCameraToSelectedPickUpLocation(
      BuildContext context, String location) async {
    final mapProvider = context.read<MapProvider>();
    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': location,
        'key': googleMapApi,
      },
    );

    try {
      final http.Response response = await http.get(uri);

      if (response.statusCode == 200) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        final Map<String, dynamic> responseData = json.decode(response.body);
        final PlaceDetailsResponse result =
            PlaceDetailsResponse.fromJson(responseData);

        if (result.status == 'OK' && result.result != null) {
          final double searchLatitude =
              result.result!.geometry?.location?.lat ?? 0.0;
          final double searchLongitude =
              result.result!.geometry?.location?.lng ?? 0.0;

          print(
              'Selected Location - Latitude: $searchLatitude, Longitude: $searchLongitude');

          print('Moving camera to the selected pickup location');
          mapProvider
              .animateCameraToPos(LatLng(searchLatitude, searchLongitude));
        } else {
          print('Invalid response status or result is null');
        }
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred: $e');
    }
  }

  Future<void> moveCameraToSelectedDestinationLocation(
      BuildContext context, String location) async {
    final mapProvider = context.read<MapProvider>();
    final Uri uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': location,
        'key': googleMapApi,
      },
    );

    try {
      final http.Response response = await http.get(uri);

      if (response.statusCode == 200) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        final Map<String, dynamic> responseData = json.decode(response.body);
        final PlaceDetailsResponse result =
            PlaceDetailsResponse.fromJson(responseData);

        if (result.status == 'OK' && result.result != null) {
          final double searchLatitude =
              result.result!.geometry?.location?.lat ?? 0.0;
          final double searchLongitude =
              result.result!.geometry?.location?.lng ?? 0.0;

          print(
              'Selected Location - Latitude: $searchLatitude, Longitude: $searchLongitude');

          print('Moving camera to the selected location');

          mapProvider
              .animateCameraToPos(LatLng(searchLatitude, searchLongitude));
        } else {
          print('Invalid response status or result is null');
        }
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred: $e');
    }
  }

  Future<void> getDeviceLocation(BuildContext context) async {
    final mapProvider = context.read<MapProvider>();
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      double latitude = position.latitude;
      double longitude = position.longitude;
      print("$latitude, $longitude");
      mapProvider.moveCameraToPickup(
        LatLng(latitude, longitude),
      );
    } catch (e) {
      print("Error getting device location: $e");

      // Throw an exception with a custom error message
      throw Exception("Failed to retrieve device location");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.search),
                  title: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: pickupSearchController,
                          onChanged: (value) {
                            setState(() {
                              showPickupResults = value.isNotEmpty;
                            });
                            pickupPlacesAutocomplete(value);
                          },
                          decoration: const InputDecoration(
                            hintText: 'Pickup location',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.my_location),
                        onPressed: () async {
                          getDeviceLocation(context);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: TextFormField(
                    controller: destinationSearchController,
                    onChanged: (value) {
                      setState(() {
                        showDestinationResults = value.isNotEmpty;
                      });
                      destinationPlacesAutocomplete(value);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Destination location',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (showPickupResults || showDestinationResults)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.zero,
                  topRight: Radius.zero,
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Column(
                children: [
                  if (showPickupResults)
                    ...pickupPlacePredictions.map((prediction) {
                      return LocationListTile(
                        onLocationSelected: selectPickupLocation,
                        prediction: prediction,
                      );
                    }),
                  if (showDestinationResults)
                    ...destinationPlacePredictions.map((prediction) {
                      return LocationListTile(
                        onLocationSelected: selectDestinationLocation,
                        prediction: prediction,
                      );
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
