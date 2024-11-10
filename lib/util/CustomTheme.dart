import 'package:flutter/material.dart';

class CustomThemeData{
  static final ThemeData light = ThemeData(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor:  Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.black,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colors.white,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black, width: 4)),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 4)),
    ),
  );
  static final ThemeData dark = ThemeData(
    textTheme: textTheme,
    scaffoldBackgroundColor:  const Color.fromRGBO(31, 31, 31, 1),
    appBarTheme: AppBarTheme(
      backgroundColor: Color.fromRGBO(51, 51, 51, 1),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromRGBO(41, 41, 41, 1),
      selectedItemColor: Colors.deepOrange,
      unselectedItemColor: Colors.white,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Colors.white,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 4)),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepOrange, width: 4)),
    ),
  );
  static final TextTheme textTheme = TextTheme();
}