import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trissea/services/database_service.dart';

import '../models/user_model.dart' as user;
import '../providers/user_provider.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();

  Future<bool> login({
    String email = "",
    String? password,
    String? firstName,
    String? lastName,
    UserProvider? userProvider,
    BuildContext? context,
  }) async {
    if (email.isEmpty || password == null || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCred.user == null) {
        throw Exception('Login failed');
      }

      if (!userCred.user!.emailVerified) {
        // Resend verification email if needed
        await userCred.user!.sendEmailVerification();
        throw Exception('Please verify your email address. A new verification email has been sent.');
      }

      // Fetch user data and update provider
      user.User loggedUser = await _db.getUser(userCred.user!.uid);
      userProvider?.setUser(loggedUser);
      
      return true;
    } on FirebaseAuthException catch (e) {
      String message = 'Authentication failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Invalid password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> createAccount({
    required String? firstName,
    required String? lastName,
    required String? email,
    required String? password,
    required UserProvider userProvider,  // Remove optional
    required BuildContext context,       // Remove optional
  }) async {
    if (kDebugMode) {
      print(email);
      print(password);
    }

    // Validate required fields
    if (email == null || password == null || firstName == null || lastName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    String username = '$firstName $lastName';

    try {
      UserCredential userData = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userData.user == null) {
        throw Exception('Failed to create user');
      }

      await userData.user!.sendEmailVerification();
      await setDisplayName(username, userProvider);

      final newUser = user.User(
        id: userData.user!.uid,
        passengerName: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      await _db.storeUser(newUser);

      userProvider.setUser(user.User(
        id: userData.user!.uid,
        email: email,
        passengerName: username,
        password: password,
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create account. ${e.toString()}'),
          duration: Duration(seconds: 2),
        ),
      );

      return false;
    }
  }

  Future<bool> setDisplayName(
      String displayName, UserProvider? userProvider) async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // Update the user's display name
        await currentUser.updateDisplayName(displayName);

        // Reload the user to ensure the updated data is reflected
        await currentUser.reload();
        currentUser = _auth.currentUser; // Get the updated user data

        // Update the userProvider with the updated user information
        userProvider?.setUser(user.User(
          id: currentUser?.uid,
          email: currentUser?.email,
          passengerName: displayName, // Set the display name
          // Other user properties as needed
        ));

        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      return false;
    }
  }
}
