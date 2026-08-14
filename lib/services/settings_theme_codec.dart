import 'package:flutter/material.dart';

String serializeThemeMode(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'system',
  ThemeMode.light => 'light',
  ThemeMode.dark => 'dark',
};

ThemeMode? deserializeThemeMode(String value) => switch (value) {
  'system' => ThemeMode.system,
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => null,
};
