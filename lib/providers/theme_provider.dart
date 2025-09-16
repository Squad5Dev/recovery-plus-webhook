import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isDarkMode = false;
  late SharedPreferences _prefs;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _isDarkMode;

  ThemeData get currentThemeData => _isDarkMode ? ThemeData.dark() : ThemeData.light();

  ThemeProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final String? themeModeString = _prefs.getString('themeMode');
    if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
      _isDarkMode = true;
    } else {
      _themeMode = ThemeMode.light;
      _isDarkMode = false;
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      _isDarkMode = true;
    } else {
      _themeMode = ThemeMode.light;
      _isDarkMode = false;
    }
    await _prefs.setString('themeMode', _themeMode.toString().split('.').last);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _isDarkMode = (mode == ThemeMode.dark);
    await _prefs.setString('themeMode', _themeMode.toString().split('.').last);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await _prefs.setString('themeMode', _themeMode.toString().split('.').last);
    notifyListeners();
  }
}