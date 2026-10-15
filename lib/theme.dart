import 'package:flutter/material.dart';

class AppTheme {
  static const seed = Color(0xFF0E7C66);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    brightness: Brightness.light,
  );
  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
        seedColor: seed, brightness: Brightness.dark),
    brightness: Brightness.dark,
  );
}
