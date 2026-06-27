import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, loggedIn, loggedOut }

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  AuthStatus _status = AuthStatus.loading;
  String? _error;

  UserModel? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoggedIn => _status == AuthStatus.loggedIn;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final sessionUser = await AuthService.getSessionUser();
    if (sessionUser != null && sessionUser.id.isNotEmpty) {
      _user = sessionUser;
      _status = AuthStatus.loggedIn;
    } else {
      _status = AuthStatus.loggedOut;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    notifyListeners();

    try {
      final user = await AuthService.login(email, password);
      if (user != null) {
        _user = user;
        _status = AuthStatus.loggedIn;
        notifyListeners();
        return true;
      } else {
        _error = 'E-Mail oder Passwort ist falsch.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Verbindungsfehler: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _status = AuthStatus.loggedOut;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
