import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trissea/providers/user_provider.dart';

class ProfileEditScreen extends StatefulWidget {
  static const String route = '/profile_edit';

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final User? user = FirebaseAuth.instance.currentUser;

    // Pre-fill the form fields with the user's current data
    _nameController.text = user?.displayName ?? '';
    _emailController.text = user?.email ?? '';
  }

  void _saveChanges(BuildContext context) {
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    // Add debug statements
    print('Updating user name: ${_nameController.text}');
    print('Updating user email: ${_emailController.text}');

    // Update user information using the UserProvider methods
    userProvider.updateUserName(_nameController.text);
    userProvider.updateUserEmail(_emailController.text);

    // Navigate back to the profile page
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _saveChanges(context);
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
