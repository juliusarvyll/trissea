import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart' as user;

class DriverInfo {
  final String caseNumber;
  final String contactNumber;
  final String email;
  final String fullName;
  final String operatorName;
  final String tricycleColor;
  final String vehicleNumber;

  DriverInfo({
    required this.caseNumber,
    required this.contactNumber,
    required this.email,
    required this.fullName,
    required this.operatorName,
    required this.tricycleColor,
    required this.vehicleNumber,
  });
}

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkIfDriver(String email) async {
    Map<String, dynamic> data =
        (await _firestore.collection('registeredUsers').doc('drivers').get())
            .data()!;

    if (kDebugMode) {
      print(data);
    }

    if (data['registeredEmails'] == null) {
      return false;
    } else if ((data['registeredEmails'] as List).contains(email)) {
      return true;
    }

    return false;
  }

  Future<void> storeUser(user.User user) async {
    await _firestore.collection('passengers').doc(user.id).set(user.toMap());
    _firestore.collection('registeredUsers').doc('passengers').set({
      'registeredEmails': FieldValue.arrayUnion([user.email]),
    });
  }

  Future<user.User> getUser(String id) async {
    return user.User.fromJson(
      (await _firestore.collection('passengers').doc(id).get()).data()!,
    );
  }

  Stream<user.User> getDriver$(String driverId) {
    return _firestore.collection('drivers').doc(driverId).snapshots().map(
          (DocumentSnapshot snapshot) => user.User.fromJson(
            snapshot.data() as Map<String, dynamic>,
          ),
        );
  }

  Future<DriverInfo> getDriverInfo(String? driverId) async {
    try {
      // Assuming you have a collection named 'drivers' in Firestore
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('drivers').doc(driverId).get();

      // Access the fields in the 'drivers' document
      String caseNumber = snapshot['caseNumber'];
      String contactNumber = snapshot['contactNumber'];
      String email = snapshot['email'];
      String fullName = snapshot['fullName'];
      String operatorName = snapshot['operatorName'];
      String tricycleColor = snapshot['tricycleColor'];
      String vehicleNumber = snapshot['vehicleNumber'];

      return DriverInfo(
        caseNumber: caseNumber,
        contactNumber: contactNumber,
        email: email,
        fullName: fullName,
        operatorName: operatorName,
        tricycleColor: tricycleColor,
        vehicleNumber: vehicleNumber,
      );
    } catch (e) {
      print('Error getting driver info: $e');
      // Handle the error or return default values
      return DriverInfo(
        caseNumber: '',
        contactNumber: '',
        email: '',
        fullName: '',
        operatorName: '',
        tricycleColor: '',
        vehicleNumber: '',
      );
    }
  }

  Future<String> startTrip(Trip trip) async {
    String docId = _firestore.collection('trips').doc().id;
    trip.id = docId;
    await _firestore.collection('trips').doc(docId).set(trip.toMap());

    return trip.id!;
  }

  Future<String> startTodaTrip(Trip trip) async {
    String docId = _firestore.collection('todaTrips').doc().id;
    trip.id = docId;
    await _firestore.collection('todaTrips').doc(docId).set(trip.toMap());

    return trip.id!;
  }

  Future<void> updateTrip(Trip trip) async {
    await _firestore.collection('trips').doc(trip.id).update(trip.toMap());
  }
  

  Future<void> updateTodaTrip(Trip trip) async {
    await _firestore.collection('trips').doc(trip.id).update(trip.toMap());
  }

  Future<List<Trip>> getCompletedTrips() async {
    return (await _firestore
            .collection('trips')
            .where(
              'passengerId',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
            .where('tripCompleted', isEqualTo: true)
            .get())
        .docs
        .map(
          (QueryDocumentSnapshot snapshot) =>
              Trip.fromJson(snapshot.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Stream<Trip> getTrip$(Trip trip) {
    return _firestore.collection('trips').doc(trip.id).snapshots().map(
          (DocumentSnapshot snapshot) =>
              Trip.fromJson(snapshot.data() as Map<String, dynamic>),
        );
  }

  Stream<Trip> getTodaTrip$(Trip trip) {
    return _firestore.collection('todaTrips').doc(trip.id).snapshots().map(
          (DocumentSnapshot snapshot) =>
              Trip.fromJson(snapshot.data() as Map<String, dynamic>),
        );
  }

  Future<List<Map<String, dynamic>>> getTodas() async {
    final QuerySnapshot snapshot = await _firestore.collection('todas').get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> reportDriver(DriverInfo driverInfo, String reportReason) async {
    try {
      await _firestore.collection('reportedDrivers').add({
        'caseNumber': driverInfo.caseNumber,
        'fullName': driverInfo.fullName,
        'vehicleNumber': driverInfo.vehicleNumber,
        'reportReason': reportReason,
        'reportedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error reporting driver: $e');
      }
      rethrow;
    }
  }
}
