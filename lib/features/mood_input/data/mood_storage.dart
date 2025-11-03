import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 💾 Local: guarda {mood, note} por dateKey (yyyy-MM-dd).
/// v2: { "2025-11-02": {"mood":"Feliz","note":"..."} }
/// v1 retrocompat: { "2025-11-02": "Feliz" }
class MoodStorage {
  static const String _key = "moods";

  static Future<void> saveMood(String dateKey, String mood, {String? note}) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);

    Map<String, dynamic> moods = {};
    if (stored != null) {
      final decoded = json.decode(stored);
      if (decoded is Map<String, dynamic>) {
        moods = decoded;
      }
    }

    final Map<String, dynamic> payload = {"mood": mood};
    if (note != null && note.trim().isNotEmpty) {
      payload["note"] = note.trim();
    }

    moods[dateKey] = payload;
    await prefs.setString(_key, json.encode(moods));
  }

  static Future<Map<String, Map<String, String>>> getAllMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == null) return {};

    final decoded = json.decode(stored);
    if (decoded is! Map) return {};

    final Map<String, Map<String, String>> result = {};
    decoded.forEach((k, v) {
      if (v is String) {
        result[k] = {"mood": v}; // v1
      } else if (v is Map) {
        final mood = v["mood"]?.toString();
        final note = v["note"]?.toString();
        if (mood != null) {
          result[k] = {"mood": mood, if (note != null) "note": note};
        }
      }
    });
    return result;
  }

  /// 🔎 Nuevo: obtiene {mood, note?} de una fecha específica
  static Future<Map<String, String>?> getByDate(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == null) return null;

    final decoded = json.decode(stored);
    if (decoded is! Map) return null;

    final v = decoded[dateKey];
    if (v == null) return null;

    if (v is String) return {"mood": v};
    if (v is Map) {
      final mood = v["mood"]?.toString();
      final note = v["note"]?.toString();
      if (mood == null) return null;
      return {"mood": mood, if (note != null) "note": note};
    }
    return null;
  }
}
