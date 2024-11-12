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
    
    // Add active booking to passenger's document
    await addActiveBooking(trip.passengerId!, docId, trip.toMap());

    return trip.id!;
  }

  Future<void> addActiveBooking(String passengerId, String tripId, Map<String, dynamic> tripData) async {
    try {
      await _firestore
          .collection('passengers')
          .doc(passengerId)
          .collection('activeBookings')
          .doc(tripId)
          .set({
        ...tripData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding active booking: $e');
      throw Exception('Failed to add active booking');
    }
  }

  Future<String> startTodaTrip(Trip trip) async {
    String docId = _firestore.collection('todaTrips').doc().id;
    trip.id = docId;
    await _firestore.collection('todaTrips').doc(docId).set(trip.toMap());

    return trip.id!;
  }

  Future<void> updateTrip(Trip trip) async {
    try {
      print('🔄 Starting updateTrip for trip ID: ${trip.id}');
      print('📝 Trip data: ${trip.toMap()}');
      print('👤 PassengerId: ${trip.passengerId}');
      print('✅ Trip completed: ${trip.tripCompleted}');
      print('❌ Trip canceled: ${trip.canceled}');

      // Update main trip document
      await _firestore.collection('trips').doc(trip.id).update(trip.toMap());
      print('✨ Main trip document updated successfully');
      
      // Only proceed with passenger updates if we have a passengerId
      if (trip.passengerId != null) {
        print('👥 Found passengerId: ${trip.passengerId}');
        
        // Update active booking in passenger's collection
        if (trip.tripCompleted == true || trip.canceled == true) {
          print('🗑️ Attempting to remove trip ${trip.id} from active bookings');
          print('📍 Path: passengers/${trip.passengerId}/activeBookings/${trip.id}');
          
          await _firestore
              .collection('passengers')
              .doc(trip.passengerId)
              .collection('activeBookings')
              .doc(trip.id)
              .delete();
          
          print('✅ Successfully removed from active bookings');
        } else {
          await _firestore
              .collection('passengers')
              .doc(trip.passengerId)
              .collection('activeBookings')
              .doc(trip.id)
              .update(trip.toMap());
        }
      } else {
        print('⚠️ No passengerId found for trip ${trip.id}');
      }
    } catch (e) {
      print('❌ Error updating trip: $e');
      throw Exception('Failed to update trip');
    }
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
    // First, get the trip updates
    Stream<Trip> tripStream = _firestore.collection('trips').doc(trip.id).snapshots().map(
          (DocumentSnapshot snapshot) =>
              Trip.fromJson(snapshot.data() as Map<String, dynamic>),
        );

    // Listen to changes and sync with passenger's active bookings
    tripStream.listen((Trip updatedTrip) async {
      if (updatedTrip.passengerId != null) {
        if (updatedTrip.tripCompleted == true || updatedTrip.canceled == true) {
          // Remove from active bookings if trip is completed or canceled
          await _firestore
              .collection('passengers')
              .doc(updatedTrip.passengerId)
              .collection('activeBookings')
              .doc(updatedTrip.id)
              .delete();
        } else {
          // Update the active booking
          await _firestore
              .collection('passengers')
              .doc(updatedTrip.passengerId)
              .collection('activeBookings')
              .doc(updatedTrip.id)
              .set(updatedTrip.toMap());
        }
      }
    });

    return tripStream;
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
