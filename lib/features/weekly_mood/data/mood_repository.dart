import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MoodRepository {
  /// Carga los estados guardados en el almacenamiento local.
  Future<Map<String, String>> loadMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('moods');
    if (stored == null) return {};
    return Map<String, String>.from(json.decode(stored));
  }

  /// Limpia los estados almacenados (opcional para pruebas).
  Future<void> clearMoods() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('moods');
  }
}
