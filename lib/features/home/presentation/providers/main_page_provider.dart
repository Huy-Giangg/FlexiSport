import 'package:flutter/material.dart';

class MainPageProvider extends ChangeNotifier {
  bool _isVisible = true;

  bool get isVisible => _isVisible;

  void showNavbar() {
    if (!_isVisible) {
      _isVisible = true;
      notifyListeners();
    }
  }

  void hideNavbar() {
    if (_isVisible) {
      _isVisible = false;
      notifyListeners();
    }
  }

  void setNavbarVisibility(bool value) {
    if (_isVisible != value) {
      _isVisible = value;
      notifyListeners();
    }
  }
}
