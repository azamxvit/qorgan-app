import 'package:flutter/material.dart';

import 'colors.dart';

ThemeData qorganTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Manrope',
  scaffoldBackgroundColor: QorganColors.canvas,
  colorScheme: const ColorScheme.light(
    primary: QorganColors.mint,
    onPrimary: QorganColors.mintInk,
    primaryContainer: QorganColors.mint,
    onPrimaryContainer: QorganColors.mintInk,
    secondary: QorganColors.signal,
    onSecondary: QorganColors.mintInk,
    secondaryContainer: QorganColors.line,
    onSecondaryContainer: QorganColors.ink,
    tertiary: QorganColors.dark,
    onTertiary: QorganColors.surface,
    tertiaryContainer: QorganColors.pale,
    onTertiaryContainer: QorganColors.ink,
    surface: QorganColors.surface,
    onSurface: QorganColors.ink,
    onSurfaceVariant: QorganColors.muted,
    surfaceContainerLowest: QorganColors.surface,
    surfaceContainerLow: QorganColors.canvas,
    surfaceContainer: QorganColors.surface,
    surfaceContainerHigh: QorganColors.pale,
    surfaceContainerHighest: QorganColors.line,
    surfaceTint: Colors.transparent,
    inverseSurface: QorganColors.dark,
    onInverseSurface: QorganColors.surface,
    inversePrimary: QorganColors.signal,
    error: QorganColors.dark,
    onError: QorganColors.surface,
    errorContainer: QorganColors.line,
    onErrorContainer: QorganColors.ink,
    outline: QorganColors.line,
    outlineVariant: QorganColors.line,
  ),
  iconTheme: const IconThemeData(color: QorganColors.muted, size: 20),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.12,
      color: QorganColors.ink,
      height: 1.18,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      color: QorganColors.ink,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: QorganColors.ink,
    ),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: QorganColors.ink),
    bodySmall: TextStyle(fontSize: 12, height: 1.4, color: QorganColors.muted),
    labelLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: QorganColors.ink,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: QorganColors.muted,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      foregroundColor: QorganColors.mintInk,
      backgroundColor: QorganColors.mint,
      minimumSize: const Size(48, 48),
      shape: const StadiumBorder(),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: QorganColors.muted,
      backgroundColor: QorganColors.surface,
      side: const BorderSide(color: QorganColors.line),
      shape: const StadiumBorder(),
      minimumSize: const Size(48, 44),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: QorganColors.ink),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: QorganColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: QorganColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: QorganColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: QorganColors.mint),
    ),
    contentPadding: const EdgeInsets.all(16),
  ),
  dividerColor: QorganColors.line,
);
