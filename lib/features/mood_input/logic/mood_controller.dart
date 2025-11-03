import 'package:intl/intl.dart';
import '../data/mood_storage.dart';
import '../../../firebase/UsuarioMoodService.dart';

/// Lógica de negocio: selecciona, formatea y persiste.
class MoodController {
  String? selectedMood;
  final Map<String, Map<String, dynamic>> moodOptions;
  final UsuarioMoodService moodService;

  MoodController(
    this.moodOptions, {
    required this.moodService,
  });

  String formatDate(DateTime date) => DateFormat("yyyy-MM-dd").format(date);

  /// Guarda local y remoto (upsert por dateKey).
  Future<void> saveMood(DateTime selectedDate, {String? note}) async {
    if (selectedMood == null) return;

    final dateKey = formatDate(selectedDate);

    // 1) Local
    await MoodStorage.saveMood(dateKey, selectedMood!, note: note);

    // 2) Remoto
    try {
      await moodService.upsertEstadoPorFecha(
        dateKey: dateKey,
        estado: selectedMood!,
        fechaLocal: selectedDate,
        extra: (note != null && note.trim().isNotEmpty)
            ? {'nota': note.trim()}
            : null,
      );
    } catch (_) {/* log suave */}
  }

  /// 🔄 Nuevo: carga mood+nota del día. Remoto sobrescribe local si existe.
  /// Retorna {"mood": "...", "note": "..."} o {} si no hay datos.
  Future<Map<String, String>> loadForDate(DateTime date) async {
    final dateKey = formatDate(date);

    // Local
    final local = await MoodStorage.getByDate(dateKey);

    // Remoto
    Map<String, String>? remote;
    try {
      final r = await moodService.getEstadoPorFecha(dateKey);
      if (r != null) {
        remote = {
          "mood": r["estado"]?.toString() ?? "",
          if (r["nota"] != null) "note": r["nota"].toString(),
        };
      }
    } catch (_) {}

    // merge: remoto gana
    final merged = {
      if (local != null) ...local,
      if (remote != null) ...remote,
    };

    // Actualiza selección si hay mood
    if (merged["mood"] != null && merged["mood"]!.isNotEmpty) {
      selectedMood = merged["mood"];
    }

    return merged;
  }
}
