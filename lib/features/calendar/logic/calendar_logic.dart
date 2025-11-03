// 🧠 LOGIC: Contiene la lógica del calendario (sin widgets)
import 'package:flutter/material.dart';
import '../data/calendar_data.dart';
import '../data/calendar_remote.dart';

class CalendarLogic {
  final CalendarRemoteData remote; // inyectado para leer Firestore

  CalendarLogic({required this.remote});

  /// Obtiene moods: primero local, luego remoto, y MERGE (remoto gana)
  Future<Map<String, String>> getMoods() async {
    final local = await CalendarData.loadMoods();
    final remoteMoods = await remote.fetchRemoteMoods();

    // Política: remoto sobrescribe local si hay colisión
    return {
      ...local,
      ...remoteMoods,
    };
  }

  /// Guarda moods locales (solo si tu UI los edita manualmente desde el calendario)
  Future<void> saveMoods(Map<String, String> moods) async {
    await CalendarData.saveMoods(moods);
  }

  /// Convierte un DateTime en clave de texto (yyyy-MM-dd)
  String dateKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  /// Retorna el color según el estado de ánimo
  Color getMoodColor(String? mood) {
    switch (mood) {
      case "Muy Feliz":
        return Colors.yellow.shade600;
      case "Feliz":
        return Colors.green.shade500;
      case "Neutral":
        return Colors.grey.shade400;
      case "Triste":
        return Colors.lightBlue.shade400;
      case "Muy Triste":
        return Colors.red.shade400;
      default:
        return Colors.transparent;
    }
  }

  /// ✅ Verifica si una fecha es futura
  bool isFutureDate(DateTime date) {
    final today = DateTime.now();
    final currentDate = DateTime(today.year, today.month, today.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isAfter(currentDate);
  }
}
