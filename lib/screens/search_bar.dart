import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:trissea/constant.dart';
import 'package:trissea/models/autocomplate_prediction.dart';
import 'package:trissea/models/map_action.dart';
import 'package:trissea/providers/map_provider.dart';
import 'package:provider/provider.dart';
import 'package:ionicons/ionicons.dart';

class SearchLocationWidget extends StatefulWidget {
  const SearchLocationWidget({Key? key, this.mapProvider}) : super(key: key);

  final MapProvider? mapProvider;
  static const String route = '/search';

  @override
  State<SearchLocationWidget> createState() => _SearchLocationWidgetState();
}

class _SearchLocationWidgetState extends State<SearchLocationWidget> {
  TextEditingController destinationSearchController = TextEditingController();
  List<AutocompletePrediction> destinationPlacePredictions = [];

  void moveCameraToSelectedLocation(LatLng pos) {
    widget.mapProvider!.animateCameraToPos(pos);
  }
  Future<double> parseDouble(String? input) async {
  // Parse the input string to a double asynchronously
  return double.parse(input ?? '0.0');
}

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    print('mapAction: ${mapProvider.mapAction}');
    return Visibility(
      visible: mapProvider.mapAction == MapAction.selectTrip,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 80, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(Ionicons.pin, color: Colors.black),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GooglePlaceAutoCompleteTextField(
                        textEditingController: destinationSearchController,
                        googleAPIKey: googleMapApi,
                        inputDecoration: const InputDecoration(),
                        debounceTime: 800, // default 600 ms,
                        countries: ["ph"], // optional by default null is set
                        isLatLngRequired: true, // if you required coordinates from place detail
                        getPlaceDetailWithLatLng: (Prediction prediction) {
                          print("Prediction details:");
                          print("Description: ${prediction.description}");
                          print("Place ID: ${prediction.placeId}");

                          // Convert lat and lng to doubles
                          final double latitude = double.parse(prediction.lat ?? '0.0');
                          final double longitude = double.parse(prediction.lng ?? '0.0');

                          print(" pred1 Latitude: $latitude");
                          print("pred1 Longitude: $longitude");
                          moveCameraToSelectedLocation(LatLng(latitude, longitude));
                        },
                        itemClick: (Prediction prediction) async {                          
                          destinationSearchController.text = prediction.description.toString();
                          destinationSearchController.selection = TextSelection.fromPosition(TextPosition(offset: prediction.description!.length));
                        },
                        itemBuilder: (context, index, Prediction prediction) {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on),
                                const SizedBox(
                                  width: 7,
                                ),
                                Expanded(child: Text(prediction.description ?? ""))
                              ],
                            ),
                          );
                        },
                        seperatedBuilder: const Divider(),
                        // want to show close icon 
                        isCrossBtnShown: true,
                        // optional container padding
                        containerHorizontalPadding: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
