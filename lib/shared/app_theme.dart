import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const _key = 'appearance_theme';
  static final _preferences = SharedPreferencesAsync();
  static final mode = ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    final stored = await _preferences.getString(_key);
    mode.value = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> save(ThemeMode selection) async {
    await _preferences.setString(_key, selection.name);
    mode.value = selection;
  }

  static final light = _theme(Brightness.light);
  static final dark = _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {

    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF73A1FD),
      brightness: brightness,
    );
    return ThemeData(
      primaryColor: const Color(0xFF73A1FD),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF315FAD),
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF315FAD),
        foregroundColor: Colors.white,
      ),
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
