import 'package:flutter/material.dart';
import '../data/reminder_repostory.dart';

/// Clase lógica que maneja el estado de los recordatorios.
/// Se comunica con el repositorio para cargar y guardar los datos.
class ReminderLogic extends ChangeNotifier {
  final ReminderRepository _repository;
  bool enabled = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 0);

  ReminderLogic(this._repository);

  /// Carga la configuración guardada en el almacenamiento
  Future<void> loadSettings() async {
    final data = await _repository.loadSettings();
    enabled = data['enabled'];
    reminderTime = TimeOfDay(hour: data['hour'], minute: data['minute']);
    notifyListeners(); // Notifica a la UI que cambió algo
  }

  /// Actualiza el estado del recordatorio (on/off)
  Future<void> updateEnabled(bool value) async {
    enabled = value;
    await _repository.saveEnabled(value);
    notifyListeners();
  }

  /// Actualiza la hora seleccionada
  Future<void> updateTime(TimeOfDay time) async {
    reminderTime = time;
    await _repository.saveTime(time.hour, time.minute);
    notifyListeners();
  }
}
