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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileSection(),
              const SizedBox(height: 24),
              _buildReportButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileItem('Case Number', driverInfo.caseNumber),
            _buildProfileItem('Contact Number', driverInfo.contactNumber),
            _buildProfileItem('Email', driverInfo.email),
            _buildProfileItem('Full Name', driverInfo.fullName),
            _buildProfileItem('Operator Name', driverInfo.operatorName),
            _buildProfileItem('Tricycle Color', driverInfo.tricycleColor),
            _buildProfileItem('Vehicle Number', driverInfo.vehicleNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showReportDialog(context, driverInfo),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: const Icon(Icons.report_problem),
      label: const Text('Report Driver'),
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
    final controller = TextEditingController();
    String? reportReason = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report Driver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please provide details about your report:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter reason for reporting...',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Submit Report'),
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
