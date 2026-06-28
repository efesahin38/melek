import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class AuthService {
  static const String _prefKeyUserId = 'user_id';
  static const String _prefKeyUserName = 'user_name';
  static const String _prefKeyUserEmail = 'user_email';
  static const String _prefKeyUserRole = 'user_role';

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<UserModel?> login(String email, String password) async {
    final user = await SupabaseService.getUserByEmail(email.trim().toLowerCase());
    if (user == null) return null;

    // Fetch full user with password hash to verify
    final fullUser = await SupabaseService.verifyLogin(
      email.trim().toLowerCase(),
      hashPassword(password),
    );
    if (fullUser == null) return null;

    final loggedUser = fullUser;
    await _saveSession(loggedUser);
    return loggedUser;
  }

  static Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyUserId, user.id);
    await prefs.setString(_prefKeyUserName, user.name);
    await prefs.setString(_prefKeyUserEmail, user.email);
    await prefs.setString(_prefKeyUserRole, user.role);
  }

  static Future<UserModel?> getSessionUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefKeyUserId);
    if (id == null || id.isEmpty) return null;

    return UserModel(
      id: id,
      name: prefs.getString(_prefKeyUserName) ?? '',
      email: prefs.getString(_prefKeyUserEmail) ?? '',
      role: prefs.getString(_prefKeyUserRole) ?? 'employee',
      createdAt: DateTime.now(),
    );
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyUserId);
    await prefs.remove(_prefKeyUserName);
    await prefs.remove(_prefKeyUserEmail);
    await prefs.remove(_prefKeyUserRole);
  }

  static Future<bool> isLoggedIn() async {
    final user = await getSessionUser();
    return user != null && user.id.isNotEmpty;
  }
}
