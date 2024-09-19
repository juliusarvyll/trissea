import 'package:flutter/material.dart';

ThemeData get theme {
  return ThemeData(
    primarySwatch: Colors.green,
    colorScheme: ThemeData().colorScheme.copyWith(
          primary: Colors.green,
          secondary: Colors.greenAccent,
        ),
    scaffoldBackgroundColor: Colors.white,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        elevation: 0,
        enableFeedback: true,
        shadowColor: Colors.transparent,
      ),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
