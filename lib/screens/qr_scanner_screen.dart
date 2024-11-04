import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:trissea/services/database_service.dart';
import 'package:trissea/screens/driver_profile.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);
  static const String route = '/qr-screen';

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  String qrText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text('Scanned Data: $qrText'),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        qrText = scanData.code ?? ''; // Handle null value
      });

      if (qrText.isNotEmpty) {
        await _navigateToDriverProfile(context, qrText); // Navigate to driver profile using scanned data
      }
    });
  }

  Future<void> _navigateToDriverProfile(BuildContext context, String driverId) async {
    try {
      // Query Firestore to retrieve driver details based on driver ID
      DriverInfo driverInfo = await DatabaseService().getDriverInfo(driverId);
      if (driverInfo.fullName.isNotEmpty) { // Updated to check `fullName` instead of `driverName`
        // Driver found, navigate to driver profile screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverProfile(driverInfo: driverInfo),
          ),
        );
      } else {
        // Driver not found, show error message
        _showErrorDialog(context, 'Driver Not Found', 'The scanned QR code does not correspond to a valid driver.');
      }
    } catch (error) {
      // Error occurred while querying Firestore
      print('Error retrieving driver details: $error');
      // Show error message
      _showErrorDialog(context, 'Error', 'An error occurred while retrieving driver details. Please try again later.');
    }
  }

  void _showErrorDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
