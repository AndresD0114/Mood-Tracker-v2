import 'package:flutter/material.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  bool enabled = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "🔔 Recordatorio",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        color: Colors.lightBlue[50],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReminderToggle(
              enabled: enabled,
              onChanged: (value) => setState(() => enabled = value),
            ),
            const SizedBox(height: 20),
            _ReminderTimePicker(
              reminderTime: reminderTime,
              onTimePicked: (time) => setState(() => reminderTime = time),
            ),
          ],
        ),
      ),

  
    );
  }
}

///Switch para activar/desactivar recordatorio
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

///Selector de hora
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
        const Text("Hora del recordatorio:"),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: reminderTime,
            );
            if (picked != null) onTimePicked(picked);
          },
          child: Text(reminderTime.format(context)),
        ),
      ],
    );
  }
}

