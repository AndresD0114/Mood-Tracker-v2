import 'package:flutter/material.dart';

import '../data/mood_repository.dart';
import '../../../firebase/UsuarioMoodService.dart';
import '../../../firebase/data/auth_datasource.dart';
import '../../../firebase/data/auth_repository.dart';

/// Lógica combinada para estadísticas semanales.
/// Lee estados desde:
///   1) Local (SharedPreferences) vía MoodRepository
///   2) Remoto (Firestore) vía UsuarioMoodService
class WeeklyMoodLogic {
  final MoodRepository localRepo;
  final UsuarioMoodService moodService;

  WeeklyMoodLogic({
    required this.localRepo,
    required this.moodService,
  });

  /// Factory de conveniencia para usar directamente desde la UI
  factory WeeklyMoodLogic.standard() {
    final ds = AuthRemoteDataSource();
    final authRepo = AuthRepository(ds);
    final moodService = UsuarioMoodService(authRepository: authRepo);
    final localRepo = MoodRepository();

    return WeeklyMoodLogic(
      localRepo: localRepo,
      moodService: moodService,
    );
  }

  /// Carga estados locales + remotos, los fusiona y calcula promedios
  /// por día de la semana (Lun..Dom).
  Future<List<double?>> loadAndCompute([DateTimeRange? range]) async {
    // 1) Local
    final Map<String, String> local = await localRepo.loadMoods();

    // 2) Remoto (Firestore)
    Map<String, String> remote = {};
    try {
      remote = await moodService.fetchEstadosComoMapa();
    } catch (_) {
      // Si falla Firestore, seguimos solo con local
    }

    // 3) Merge: remoto sobrescribe local si hay misma fecha
    final merged = <String, String>{
      ...local,
      ...remote,
    };

    return _averageByWeekday(merged, range);
  }

  /// Convierte una etiqueta de estado a valor numérico.
  double _moodToValue(String mood) {
    switch (mood) {
      case "Muy Triste":
        return 0.0;
      case "Triste":
        return 1.0;
      case "Neutral":
        return 2.0;
      case "Feliz":
        return 3.0;
      case "Muy Feliz":
        return 4.0;
      default:
        return 2.0; // Neutral por defecto
    }
  }

  /// Calcula los promedios de mood agrupados por día de la semana.
  /// Devuelve una lista de 7 posiciones: [Lun, Mar, Mié, Jue, Vie, Sáb, Dom]
  List<double?> _averageByWeekday(
    Map<String, String> entries,
    DateTimeRange? range,
  ) {
    final buckets = List<List<double>>.generate(7, (_) => []);

    entries.forEach((dateStr, mood) {
      try {
        final parts = dateStr.split('-');
        if (parts.length != 3) return;

        final dt = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        if (range != null) {
          // Rango inclusivo
          final start = DateTime(range.start.year, range.start.month, range.start.day);
          final end = DateTime(range.end.year, range.end.month, range.end.day);
          final current = DateTime(dt.year, dt.month, dt.day);

          if (current.isBefore(start) || current.isAfter(end)) {
            return;
          }
        }

        final idx = dt.weekday - 1; // 1=Lunes -> 0
        if (idx < 0 || idx > 6) return;

        buckets[idx].add(_moodToValue(mood));
      } catch (_) {
        // Si falla el parse, ignoramos esa entrada
      }
    });

    // Promedio por día o null si no hay datos
    return buckets.map((list) {
      if (list.isEmpty) return null;
      final sum = list.reduce((a, b) => a + b);
      return sum / list.length;
    }).toList();
  }

  /// (Opcional) limpiar solo los datos locales, útil para pruebas.
  Future<void> clearLocal() => localRepo.clearMoods();
}
