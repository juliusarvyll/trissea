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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTitle(),
              const Divider(height: 30),
              _buildDriverInfo(),
              const SizedBox(height: 16),
              _buildTripDetails(),
              const SizedBox(height: 20),
              _buildReportButton(context),
            ],
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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(
            'images/tricycle.svg',
            width: 40,
            height: 40,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            titleText,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetails() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.route,
            'Distance',
            mapProvider.distance != null 
                ? '${mapProvider.distance!.toStringAsFixed(2)} Km'
                : '--',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            Icons.attach_money,
            'Cost',
            mapProvider.cost != null 
                ? '₱${mapProvider.cost!.toStringAsFixed(2)}'
                : '--',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.red, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildReportButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showReportIssueDialog(context),
      icon: const Icon(Icons.report_problem_outlined),
      label: const Text('Report an Issue'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
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
                _buildInfoText('Driver: ', driverInfo.fullName),
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
    return Row(
      children: [
        Icon(Icons.info, color: Colors.red, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
        const Spacer(),
        Text(
          info,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
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
                decoration: const InputDecoration(
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
