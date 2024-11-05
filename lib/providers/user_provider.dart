import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:trissea/models/map_action.dart';
import 'package:provider/provider.dart';
import 'package:trissea/providers/map_provider.dart';
import 'package:trissea/main.dart';

import '../models/user_model.dart' as user;
import '../services/database_service.dart';
import '../models/trip_model.dart' as trip;

class UserProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  user.User? _loggedUser;
  trip.Trip? activeBooking;

  user.User? get loggedUser => _loggedUser;

  UserProvider() {
    print('🏗️ UserProvider constructor called');
    if (FirebaseAuth.instance.currentUser != null) {
      print('👤 Current user found: ${FirebaseAuth.instance.currentUser!.uid}');
      _dbService.getUser(FirebaseAuth.instance.currentUser!.uid).then(
        (user.User user) {
          print('📥 User data retrieved: ${user.passengerName}');
          _loggedUser = user;
          notifyListeners();
        },
      );
    } else {
      print('�� No current user found');
    }
  }

  void setUser(user.User user) {
    _loggedUser = user;
  }

  void clearUser() {
    _loggedUser = null;
  }

  Future<void> updateUserName(String newName) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Update display name in Firebase Authentication
        await firebaseUser.updateDisplayName(newName);

        if (_loggedUser != null) {
          _loggedUser!.passengerName = newName;
        }

        // Update passengerName in Firebase Firestore
        final userFirestoreReference = FirebaseFirestore.instance
            .collection("passengers")
            .doc(firebaseUser.uid);
        await userFirestoreReference.update({"passengerName": newName});

        notifyListeners();
      }
    } catch (e) {
      print("Failed to update user name and Firestore: $e");
    }
  }

  // Update the user's email
  Future<void> updateUserEmail(String newEmail) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.verifyBeforeUpdateEmail(newEmail);
        if (_loggedUser != null) {
          _loggedUser!.email = newEmail;
        }
        notifyListeners();
      }
    } catch (e) {
      print("Failed to update user email: $e");
    }
  }

  static Future<UserProvider> createInstance() async {
    print('🔨 Creating UserProvider instance');
    final provider = UserProvider();
    print('🚀 Starting provider initialization');
    await provider.onStart();
    return provider;
  }

  Future<void> onStart() async {
    print('🎬 onStart called');
    // Check for active bookings when user logs in
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      print('👂 Auth state changed - User: ${user?.uid}');
      if (user != null) {
        print('✅ User logged in, checking active booking');
        await checkActiveBooking(user.uid);
      } else {
        print('❌ User logged out, clearing active booking');
        activeBooking = null;
        notifyListeners();
      }
    });
  }

  Future<void> checkActiveBooking(String userId) async {
    print('🔍 Checking active booking for user: $userId');
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('passengers')
          .doc(userId)
          .collection('activeBookings')
          .get();

      print('📚 Found ${querySnapshot.docs.length} active bookings');

      if (querySnapshot.docs.isNotEmpty) {
        final bookingData = querySnapshot.docs.first.data();
        print('📋 Raw booking data: $bookingData');
        
        activeBooking = trip.Trip.fromJson(bookingData);
        print('🎯 Active booking details:'
            '\n   - ID: ${activeBooking?.id}'
            '\n   - Canceled: ${activeBooking?.canceled}'
            '\n   - Accepted: ${activeBooking?.accepted}'
            '\n   - Started: ${activeBooking?.started}');
        
        final mapProvider = Provider.of<MapProvider>(navigatorKey.currentContext!, listen: false);
        print('🗺️ Current MapAction before update: ${mapProvider.mapAction}');
        
        if (activeBooking != null) {
          // Set the active booking as ongoing trip in MapProvider
          mapProvider.setOngoingTrip(activeBooking!);
          
          if (activeBooking!.canceled == true) {
            print('❌ Trip canceled, resetting state');
            mapProvider.changeMapAction(MapAction.selectTrip);
            activeBooking = null;
          } else if (activeBooking!.accepted == false) {
            print('🔄 Setting MapAction to searchDriver');
            mapProvider.changeMapAction(MapAction.searchDriver);
          } else if (activeBooking!.accepted == true && activeBooking!.started == false) {
            print('🚗 Setting MapAction to driverArriving');
            mapProvider.changeMapAction(MapAction.driverArriving);
          }
          print('🗺️ MapAction after update: ${mapProvider.mapAction}');
        }
        
        notifyListeners();
      } else {
        print('❌ No active bookings found');
        activeBooking = null;
      }
      notifyListeners();
    } catch (e) {
      print('⚠️ Error checking active booking: $e');
      activeBooking = null;
      notifyListeners();
    }
  }

  void listenToActiveBooking(String userId, String tripId) {
    print('👂 Setting up listener for booking: $tripId');
    FirebaseFirestore.instance
        .collection('passengers')
        .doc(userId)
        .collection('activeBookings')
        .doc(tripId)
        .snapshots()
        .listen((snapshot) {
      print('📡 Received booking update for $tripId');
      if (snapshot.exists) {
        print('📝 Booking data updated: ${snapshot.data()}');
        activeBooking = trip.Trip.fromMap(snapshot.data()!);
      } else {
        print('🗑️ Booking no longer exists');
        activeBooking = null;
      }
      notifyListeners();
    });
  }

  static UserProvider initialize() {
    print('🎯 Initialize called');
    return UserProvider();
  }
}
