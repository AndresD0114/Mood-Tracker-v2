
import 'package:flutter/material.dart';
import '../data/mood_repository.dart';


class WeeklyMoodLogic {
  final MoodRepository _repo = MoodRepository();

  /// Carga los moods desde SharedPreferences y calcula los promedios.
  Future<List<double?>> loadAndCompute([DateTimeRange? range]) async {
    final Map<String, String> moods = await _repo.loadMoods();
    return _averageByWeekday(moods, range);
  }

  /// Convierte una etiqueta de estado a valor numérico.
  double _moodToValue(String mood) {
    switch (mood) {
      case "Muy Triste": return 0.0;
      case "Triste": return 1.0;
      case "Neutral": return 2.0;
      case "Feliz": return 3.0;
      case "Muy Feliz": return 4.0;
      default: return 2.0;
    }
  }

  /// Calcula los promedios de mood agrupados por día de la semana.
  List<double?> _averageByWeekday(Map<String, String> entries, DateTimeRange? range) {
    final buckets = List<List<double>>.generate(7, (_) => []);

    entries.forEach((dateStr, mood) {
      try {
        final parts = dateStr.split('-');
        if (parts.length != 3) return;
        final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

        if (range != null &&
            (dt.isBefore(range.start) || dt.isAfter(range.end))) return;

        final idx = dt.weekday - 1;
        buckets[idx].add(_moodToValue(mood));
      } catch (_) {}
    });

    return buckets.map((list) {
      if (list.isEmpty) return null;
      return list.reduce((a, b) => a + b) / list.length;
    }).toList();
  }
}
