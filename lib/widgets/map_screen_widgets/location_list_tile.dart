import 'package:flutter/material.dart';
import 'package:trissea/models/autocomplate_prediction.dart';

class LocationListTile extends StatelessWidget {
  const LocationListTile({
    Key? key,
    required this.onLocationSelected,
    required this.prediction,
  }) : super(key: key);

  final Function(AutocompletePrediction) onLocationSelected;
  final AutocompletePrediction prediction;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(prediction.description!),
      onTap: () {
        onLocationSelected(prediction);
      },
    );
  }
}
