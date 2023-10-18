import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart' as user;
import '../services/database_service.dart';

class UserProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  user.User? _loggedUser;

  user.User? get loggedUser => _loggedUser;

  UserProvider.initialize() {
    if (FirebaseAuth.instance.currentUser != null) {
      _dbService.getUser(FirebaseAuth.instance.currentUser!.uid).then(
        (user.User user) {
          _loggedUser = user;
          notifyListeners();
        },
      );
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
        await firebaseUser.updateEmail(newEmail);
        if (_loggedUser != null) {
          _loggedUser!.email = newEmail;
        }
        notifyListeners();
      }
    } catch (e) {
      print("Failed to update user email: $e");
    }
  }
}
