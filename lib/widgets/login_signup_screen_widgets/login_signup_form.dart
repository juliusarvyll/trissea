import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trissea/screens/map_screen.dart';

import '../../providers/user_provider.dart';
import '../../services/auth_services.dart';
import 'text_field.dart';
import 'form_button.dart';
import '../../models/auth_mode.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key, required this.context}) : super(key: key);

  final BuildContext context;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthServices _auth = AuthServices();
  late AuthMode authMode;
  late AnimationController _animationController;
  late Animation<double> _sizetransition;
  late String _firstName;
  late String _lastName;
  late String _email;
  late String _password;
  bool _isLoading = false; // Track loading state

  void _switchMode() {
    if (authMode == AuthMode.login) {
      setState(() => authMode = AuthMode.signup);
      _animationController.forward();
    } else {
      setState(() => authMode = AuthMode.login);
      _animationController.reverse();
    }
  }

  Future<void> _authenticate(BuildContext context) async {
  final UserProvider userProvider = Provider.of<UserProvider>(
    context,
    listen: false,
  );

  _formKey.currentState!.save();

  setState(() {
    _isLoading = true; // Set loading state to true when authentication starts
  });

  if (authMode == AuthMode.login) {
    bool isAuthenticated = await _auth.login(
      email: _email,
      firstName: _firstName,
      lastName: _lastName,
      password: _password,
      userProvider: userProvider,
      context: context,
    );

    if (isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(MapScreen.route);
    }
  } else {
    bool isAccountCreated = await _auth.createAccount(
      firstName: _firstName,
      lastName: _lastName,
      email: _email,
      password: _password,
      userProvider: userProvider,
      context: context, // Pass context here
    );

    if (isAccountCreated) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Account Created'),
            content: const Text('Your account has been created. Please check your email for verification'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  setState(() {
    _isLoading = false; // Set loading state to false when authentication finishes
  });
}



  @override
  void initState() {
    authMode = AuthMode.login;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _sizetransition = CurvedAnimation(
      curve: Curves.easeIn,
      parent: _animationController,
    );
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          SizeTransition(
            sizeFactor: _sizetransition,
            child: Column(
              children: [
                InputTextField(
                  title: 'First Name',
                  handler: (String? value) => _firstName = value!,
                  icon: Icons.account_circle,
                ),
                const SizedBox(height: 15),
                InputTextField(
                  title: 'Last Name',
                  handler: (String? value) => _lastName = value!,
                  icon: Icons.account_circle,
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
          InputTextField(
            title: 'Email',
            handler: (String? value) => _email = value!,
            icon: Icons.email,
          ),
          const SizedBox(height: 15),
          InputTextField(
            title: 'Password',
            handler: (String? value) => _password = value!,
            icon: Icons.key,
            password: true,
          ),
          const SizedBox(height: 15),
          _isLoading
              ? CircularProgressIndicator() // Show loading indicator when _isLoading is true
              : FormButton(
                  title: authMode == AuthMode.login ? 'Login' : 'Sign Up',
                  handler: () => _authenticate(context),
                ),
          const SizedBox(height: 15),
          FormButton(
            title: authMode == AuthMode.login
                ? 'Create An Account'
                : 'Already have an account?',
            handler: _switchMode,
          ),
        ],
      ),
    );
  }
}
