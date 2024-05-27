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
    if (kDebugMode) {
      print(email);
      print(password);
    }

    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password!,
      );

      if (userCred.user != null) {
        if (userCred.user!.emailVerified) {
          user.User loggedUser = await _db.getUser(userCred.user!.uid);
          userProvider!.setUser(loggedUser);
        } else {
          showDialog(
            context: context!,
            builder: (ctx) => AlertDialog(
              title: const Text('Account Not Verified'),
              content: const Text(
                'Your account has not been verified. Please check your email for verification instructions.',
              ),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
          // Return true to indicate a successful login attempt, but with an unverified account
          return true;
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }

      // Check the specific error message to determine if it's due to incorrect password or unverified account
      if (e is FirebaseAuthException && e.code == 'user-not-found') {
        showDialog(
          context: context!,
          builder: (ctx) => AlertDialog(
            title: const Text('Login Failed'),
            content: const Text('Email not found. Please check your email or sign up.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      } else if (e is FirebaseAuthException && e.code == 'wrong-password') {
        // Handle the incorrect password error separately
        showDialog(
          context: context!,
          builder: (ctx) => AlertDialog(
            title: const Text('Login Failed'),
            content: const Text('Incorrect email or password.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      }

      // Return false to indicate a failed login attempt
      return false;
    }
  }


  Future<bool> createAccount({
  required String? firstName,
  required String? lastName,
  required String? email,
  required String? password,
  UserProvider? userProvider,
  BuildContext? context,
}) async {
  if (kDebugMode) {
    print(email);
    print(password);
  }

  String username = '$firstName $lastName';

  try {
    UserCredential userData = await _auth.createUserWithEmailAndPassword(
      email: email!,
      password: password!,
    );

    await userData.user!.sendEmailVerification();
    await setDisplayName(username , userProvider);

    await _db.storeUser(
      user.User(
        id: userData.user!.uid,
        passengerName: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      ),
    );
    userProvider!.setUser(
      user.User(
        id: userData.user!.uid,
        email: email,
        passengerName: username,
        password: password,
      ),
    );

    // Show success SnackBar
    ScaffoldMessenger.of(context!).showSnackBar(
      SnackBar(
        content: Text('Account created successfully!'),
        duration: Duration(seconds: 2),
      ),
    );

    return true;
  } catch (e) {
    if (kDebugMode) {
      print(e.toString());
    }

    // Show error SnackBar
    ScaffoldMessenger.of(context!).showSnackBar(
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
