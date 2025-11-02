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

  /// Guarda local (SharedPreferences) y remoto (Firestore upsert por dateKey).
  Future<void> saveMood(DateTime selectedDate, {String? note}) async {
    if (selectedMood == null) return;

    final dateKey = formatDate(selectedDate);

    // 1) Local
    await MoodStorage.saveMood(dateKey, selectedMood!, note: note);

    // 2) Remoto (upsert)
    try {
      await moodService.upsertEstadoPorFecha(
        dateKey: dateKey,
        estado: selectedMood!,
        fechaLocal: selectedDate,
        extra: (note != null && note.trim().isNotEmpty)
            ? {'nota': note.trim()}
            : null,
      );
    } catch (_) {
      // Podés loguear/avisar suave si querés. No rompemos UX.
    }
  }
}
