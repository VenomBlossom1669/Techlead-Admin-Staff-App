import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = ThemeData.light();
  bool isDarkMode = false;

  ThemeProvider() {
    _loadTheme();
  }

  ThemeData get currentTheme => _currentTheme;

  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDarkTheme = prefs.getBool('isDarkTheme');
    _currentTheme = (isDarkTheme ?? false) ? ThemeData.dark() : ThemeData.light();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    _currentTheme = (_currentTheme == ThemeData.light()) ? ThemeData.dark() : ThemeData.light();
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', _currentTheme == ThemeData.dark());
  }
}
