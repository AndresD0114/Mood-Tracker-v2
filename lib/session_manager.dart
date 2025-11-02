import 'package:shared_preferences/shared_preferences.dart';

/// 💾 Maneja la sesión local del usuario con SharedPreferences.
class SessionManager {
  static const _keyUid = "user_uid";
  static const _keyEmail = "user_email";

  /// Guarda sesión del usuario autenticado
  static Future<void> saveSession(String uid, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyEmail, email);
  }

  /// Obtiene la sesión guardada (uid, email) o null si no hay
  static Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_keyUid);
    final email = prefs.getString(_keyEmail);
    if (uid == null || email == null) return null;
    return {'uid': uid, 'email': email};
  }

  /// Elimina sesión (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyEmail);
  }
}
