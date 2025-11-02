import 'package:shared_preferences/shared_preferences.dart';

/// Clase encargada de manejar el almacenamiento de la configuración
/// de los recordatorios en SharedPreferences.
/// Esta capa se encarga SOLO de guardar y leer datos.
class ReminderRepository {
  static const _enabledKey = 'reminder_enabled';
  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';

  /// Guarda si el recordatorio está activado o no
  Future<void> saveEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  /// Guarda la hora y minuto del recordatorio
  Future<void> saveTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
  }

  /// Carga la configuración almacenada
  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final hour = prefs.getInt(_hourKey) ?? 8;
    final minute = prefs.getInt(_minuteKey) ?? 0;

    return {
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
    };
  }
}
