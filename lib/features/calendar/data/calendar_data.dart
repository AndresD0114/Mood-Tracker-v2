// 📦 DATA: Maneja el acceso directo a los datos (almacenamiento local)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarData {
  static const _key = "moods"; // clave única para guardar moods

  // Carga todos los moods almacenados en SharedPreferences
  static Future<Map<String, String>> loadMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);

    // Si no hay datos guardados, devolvemos un mapa vacío
    if (stored == null || stored.isEmpty) return {};

    // Convertimos el JSON guardado en un Map
    return Map<String, String>.from(json.decode(stored));
  }

  // Guarda los moods actualizados
  static Future<void> saveMoods(Map<String, String> moods) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(moods));
  }
}
