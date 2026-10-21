import 'package:flutter/material.dart';

const brand = Color(0xFF0E6F66);
const brandDark = Color(0xFF0A5A52);
const brandSoft = Color(0xFFDDF1EE);
const surface = Color(0xFFF3F5F7);
const muted = Color(0xFF526373);
const lineColor = Color(0xFFE1E6EB);
const okColor = Color(0xFF0B6B3F);
const warnColor = Color(0xFF8A4B00);
const badColor = Color(0xFFA3261B);

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: brand),
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
