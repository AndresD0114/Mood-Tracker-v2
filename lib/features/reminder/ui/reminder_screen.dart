import 'package:flutter/material.dart';
import '../logic/reminder_logic.dart';
import '../data/reminder_repostory.dart';

/// Pantalla principal del recordatorio.
/// Esta capa solo se encarga de mostrar la interfaz visual.
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late ReminderLogic logic;

  @override
  void initState() {
    super.initState();
    logic = ReminderLogic(ReminderRepository());
    logic.loadSettings();
    logic.addListener(() => setState(() {})); // Redibuja la UI al cambiar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          _buildHeader(),
          _buildBody(context),
          _buildSaveButton(context),
        ],
      ),
    );
  }

  /// Header con icono, título y descripción
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: const Column(
        children: [
          Icon(Icons.alarm, size: 60, color: Colors.white),
          SizedBox(height: 10),
          Text(
            "Activa tus recordatorios 🔔",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Te ayudaremos a no olvidar registrar tu estado de ánimo",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Contenido principal (switch + hora)
  Widget _buildBody(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReminderToggle(
              enabled: logic.enabled,
              onChanged: logic.updateEnabled,
            ),
            const SizedBox(height: 20),
            _ReminderTimePicker(
              reminderTime: logic.reminderTime,
              onTimePicked: logic.updateTime,
            ),
          ],
        ),
      ),
    );
  }

  /// Botón guardar
  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: logic.enabled
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recordatorio guardado ✅'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: logic.enabled ? Colors.green : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
          ),
          icon: const Icon(Icons.save, color: Colors.white),
          label: const Text(
            "Guardar",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Switch estilizado
class _ReminderToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ReminderToggle({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Recordatorio diario", style: TextStyle(fontSize: 18)),
        Switch(value: enabled, onChanged: onChanged),
      ],
    );
  }
}

/// Selector de hora estilizado
class _ReminderTimePicker extends StatelessWidget {
  final TimeOfDay reminderTime;
  final ValueChanged<TimeOfDay> onTimePicked;

  const _ReminderTimePicker({
    required this.reminderTime,
    required this.onTimePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Hora del recordatorio:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: reminderTime,
            );
            if (picked != null) onTimePicked(picked);
          },
          icon: const Icon(Icons.access_time),
          label: Text(reminderTime.format(context)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: Colors.lightGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
