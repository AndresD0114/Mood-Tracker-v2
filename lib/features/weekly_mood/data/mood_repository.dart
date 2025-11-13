import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Repositorio local de moods para las estadísticas.
/// Soporta:
/// v1: { "2025-11-02": "Feliz" }
/// v2: { "2025-11-02": { "mood": "Feliz", "note": "..." } }
class MoodRepository {
  static const _key = 'moods';

  /// Carga los estados guardados en el almacenamiento local
  /// y los normaliza a { "yyyy-MM-dd": "Feliz" }.
  Future<Map<String, String>> loadMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == null || stored.isEmpty) return {};

    final decoded = json.decode(stored);
    if (decoded is! Map) return {};

    final Map<String, String> result = {};
    decoded.forEach((k, v) {
      if (v is String) {
        // v1 -> "Feliz"
        result[k] = v;
      } else if (v is Map) {
        // v2 -> {mood: "...", note: "..."}
        final mood = v['mood']?.toString();
        if (mood != null) result[k] = mood;
      }
    });
    return result;
  }

  /// Limpia los estados almacenados (opcional para pruebas).
  Future<void> clearMoods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
