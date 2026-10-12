import 'package:flutter/material.dart';

// Configuración del Tema Claro
ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.grey[100],
  colorScheme: ColorScheme.light(
    surface: Colors.grey[100]!,
    primary: Colors.redAccent,
    onSurface: Colors.black87,
  ),
);

// Configuración del Tema Oscuro
ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF121212),
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF1E1E1E),
    primary: Colors.redAccent,
    onSurface: Colors.white,
  ),
);

// Gestor de Estado del Tema
class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = lightMode;

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}