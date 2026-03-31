import 'package:flutter/material.dart';

/// Manages the current [ThemeMode] for the app.
///
/// Wrap the MaterialApp in a [ListenableBuilder] listening to this notifier
/// so that toggling the mode triggers a rebuild.
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode;

  ThemeNotifier([ThemeMode initial = ThemeMode.light]) : _mode = initial;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}
