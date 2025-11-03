// 📦 DATA: Maneja el acceso directo a los datos (almacenamiento local)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarData {
  static const _key = "moods"; // misma clave que usa MoodStorage

  /// Carga moods desde SharedPreferences y los normaliza a Map<String, String>
  /// v1: { "2025-11-02": "Feliz" }
  /// v2: { "2025-11-02": { "mood": "Feliz", "note": "..." } }
  static Future<Map<String, String>> loadMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);

    if (stored == null || stored.isEmpty) return {};

    final decoded = json.decode(stored);
    if (decoded is! Map) return {};

    final Map<String, String> result = {};
    decoded.forEach((k, v) {
      if (v is String) {
        result[k] = v; // v1
      } else if (v is Map) {
        final mood = v["mood"]?.toString();
        if (mood != null) result[k] = mood;
      }
    });
    return result;
  }

  /// Guarda el mapa plano (por compatibilidad con tu lógica actual de calendario).
  /// Si querés guardar nota acá, usá la clase centralizada `MoodStorage`.
  static Future<void> saveMoods(Map<String, String> moods) async {
    final prefs = await SharedPreferences.getInstance();
    // Guardamos simple como v1 para el calendario (solo estado).
    await prefs.setString(_key, json.encode(moods));
  }
}
