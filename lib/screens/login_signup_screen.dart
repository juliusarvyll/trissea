import 'package:flutter/material.dart';
import '../widgets/login_signup_screen_widgets/login_signup_form.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginSignupScreen extends StatelessWidget {
  const LoginSignupScreen({Key? key}) : super(key: key);

  static const String route = '/login-signup';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SvgPicture.asset(
                  'images/logo.svg',
                  width: 300,
                  height: 300,
                ),
                const SizedBox(height: 10),
                LoginForm(context: context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
