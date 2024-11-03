import 'package:flutter/material.dart';
import '../../models/auth_mode.dart';

class InputTextField extends StatelessWidget {
  const InputTextField({
    Key? key,
    required this.title,
    required this.icon,
    this.password = false,
    this.handler,
    this.validator,
    required this.authMode,
    required this.fieldType,
  }) : super(key: key);

  final String title;
  final String? Function(String? value)? handler;
  final String? Function(String? value)? validator;
  final IconData? icon;
  final bool? password;
  final AuthMode authMode;
  final FieldType fieldType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: title,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon!),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      obscureText: password! ? true : false,
      onSaved: handler,
      validator: (value) {
        if (authMode == AuthMode.login && 
            (fieldType == FieldType.firstName || fieldType == FieldType.lastName)) {
          return null;
        }

        return validator?.call(value) ?? defaultValidation(value);
      },
    );
  }

  String? defaultValidation(String? value) {
    if (value == null || value.isEmpty) {
      return '$title is required';
    }
    
    switch (fieldType) {
      case FieldType.email:
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        break;
      case FieldType.password:
        if (authMode == AuthMode.signup && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        break;
      default:
        break;
    }
    
    return null;
  }
}

enum FieldType {
  firstName,
  lastName,
  email,
  password,
}
