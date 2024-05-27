import 'package:flutter/material.dart';
import 'package:trissea/services/database_service.dart';

class DriverProfile extends StatelessWidget {
  final DriverInfo driverInfo;

  const DriverProfile({Key? key, required this.driverInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileItem('Case Number', driverInfo.caseNumber),
            _buildProfileItem('Contact Number', driverInfo.contactNumber),
            _buildProfileItem('Email', driverInfo.email),
            _buildProfileItem('Full Name', driverInfo.driverName),
            _buildProfileItem('Operator Name', driverInfo.operatorName),
            _buildProfileItem('Tricycle Color', driverInfo.tricycleColor),
            _buildProfileItem('Vehicle Number', driverInfo.vehicleNumber),
            const SizedBox(height: 20), // Add space before the button
            ElevatedButton(
              onPressed: () {
                _showReportDialog(context, driverInfo);
              },
              child: const Text('Report Driver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReportDialog(BuildContext context, DriverInfo driverInfo) async {
    String? reportReason = await showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Report Driver'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter reason for reporting...',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (reportReason != null && reportReason.isNotEmpty) {
      await _reportDriver(context, driverInfo, reportReason);
    }
  }

  Future<void> _reportDriver(BuildContext context, DriverInfo driverInfo, String reportReason) async {
    try {
      DatabaseService dbService = DatabaseService();
      await dbService.reportDriver(driverInfo, reportReason);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver reported successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report driver: $e')),
      );
    }
  }
}
