import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/map_action.dart';
import '../../providers/map_provider.dart';
import '../../services/database_service.dart';

class TripStarted extends StatelessWidget {
  const TripStarted({Key? key, required this.mapProvider}) : super(key: key);

  final MapProvider mapProvider;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: mapProvider.mapAction == MapAction.tripStarted ||
          mapProvider.mapAction == MapAction.driverArriving ||
          mapProvider.mapAction == MapAction.driverArrived,
      child: Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 16),
                  _buildDriverInfo(),
                  _buildInfoText(
                    'Remaining Distance: ',
                    mapProvider.distance != null ? '${mapProvider.distance!.toStringAsFixed(2)} Km' : '--',
                  ),
                  _buildInfoText(
                    'Cost: ',
                    mapProvider.cost != null ? '\₱${mapProvider.cost!.toStringAsFixed(2)}' : '--',
                  ),
                  const SizedBox(height: 16),
                  _buildReportIssueButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    String titleText = getTitleText();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'images/tricycle.svg',
          width: 60,
          height: 60,
          color: Colors.red, // Use Grab's primary color
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            titleText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Use Grab's primary color
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverInfo() {
    if (_isDriverInfoVisible()) {
      return FutureBuilder(
        future: _getDriverInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text(
              'Fetching driver information...',
              style: TextStyle(color: Colors.black), // Placeholder text color
            );
          } else if (snapshot.hasError) {
            return const Text(
              'Error fetching driver information',
              style: TextStyle(color: Colors.red), // Error text color
            );
          } else {
            DriverInfo driverInfo = snapshot.data as DriverInfo;
            return Column(
              children: [
                _buildInfoText('Driver: ', driverInfo.driverName),
                _buildInfoText('Vehicle Color: ', driverInfo.tricycleColor),
                _buildInfoText('Vehicle Number: ', driverInfo.vehicleNumber),
              ],
            );
          }
        },
      );
    } else {
      return SizedBox.shrink();
    }
  }

  bool _isDriverInfoVisible() {
    return [
      MapAction.tripStarted,
      MapAction.driverArriving,
      MapAction.driverArrived
    ].contains(mapProvider.mapAction);
  }

  Widget _buildInfoText(String title, String info) {
    return RichText(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.black, // Text color
          fontWeight: FontWeight.bold,
        ),
        children: [
          TextSpan(
            text: info,
            style: const TextStyle(
              color: Colors.black, // Text color
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildReportIssueButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _showReportIssueDialog(context);
      },
      child: Text('Report Issue'),
    );
  }

  void _showReportIssueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String reportedIssue = '';
        String? selectedIssue;
        List<String> predefinedIssues = [
          'Late Arrival',
          'Driver Behavior',
          'Payment Issue',
          'Vehicle Condition',
          // Add more predefined issues as needed
        ];
        return AlertDialog(
          title: Text(
            'Report Issue',
            style: TextStyle(color: Colors.black), // Title text color
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select an issue',
                  border: OutlineInputBorder(),
                ),
                value: selectedIssue,
                onChanged: (value) {
                  selectedIssue = value;
                },
                items: predefinedIssues.map((issue) {
                  return DropdownMenuItem<String>(
                    value: issue,
                    child: Text(issue),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter additional details (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  reportedIssue = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.black), // Button text color
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _handleReportedIssue(selectedIssue, reportedIssue);
                Navigator.of(context).pop();
              },
              child: Text(
                'Submit',
                style: TextStyle(color: Colors.white), // Button text color
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleReportedIssue(String? selectedIssue, String reportedIssue) {
    String finalIssue = selectedIssue ?? '';
    if (reportedIssue.isNotEmpty) {
      finalIssue += ' - $reportedIssue';
    }
    mapProvider.setReport(finalIssue);
  }

  Future<DriverInfo> _getDriverInfo() async {
    String? driverId = mapProvider.ongoingTrip?.driverId;
    if (driverId != null) {
      return await DatabaseService().getDriverInfo(driverId);
    } else {
      throw Exception('Driver information not available');
    }
  }

  String getTitleText() {
    switch (mapProvider.mapAction) {
      case MapAction.tripStarted:
        return 'Enjoy your ride!';
      case MapAction.driverArriving:
        return 'Driver is on their way to your location';
      case MapAction.driverArrived:
        return 'Driver has arrived at your location';
      default:
        return 'Trip Started';
    }
  }
}
