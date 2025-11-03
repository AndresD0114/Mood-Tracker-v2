// 🎨 UI: Interfaz del calendario, usa CalendarLogic para la parte funcional
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../mood_input/ui/mood_input_screen.dart';

// 🔧 Firebase + Auth
import '../../../firebase/data/auth_datasource.dart';
import '../../../firebase/data/auth_repository.dart';
import '../../../firebase/logic/auth_controller.dart';
import '../../../session_manager.dart';
import '../../../main.dart';
import '../../login/ui/login.dart';

// 📊 Data y lógica del calendario
import '../data/calendar_remote.dart';
import '../logic/calendar_logic.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarLogic _logic;
  late final AuthController _auth;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, String> moods = {}; // Ej: {"2025-10-15": "Feliz"}

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();

    // 🧩 Inyección simple
    final ds = AuthRemoteDataSource();
    final repo = AuthRepository(ds);
    final remote = CalendarRemoteData(authRepository: repo);
    _logic = CalendarLogic(remote: remote);
    _auth = AuthController(repo);

    _loadMoods();
  }

  Future<void> _loadMoods() async {
    final data = await _logic.getMoods();
    if (!mounted) return;
    setState(() => moods = data);
  }

  Future<void> _openMoodInput(DateTime date, String? currentMood) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MoodInputScreen(initialMood: currentMood, selectedDate: date),
      ),
    );

    if (updated != null) {
      await _loadMoods();
      if (!mounted) return;
      setState(() {
        _selectedDay = date;
        _focusedDay = date;
      });
    } else {
      await _loadMoods();
    }
  }

  /// 🚪 Cierra sesión y redirige al login
  Future<void> _logout() async {
    await _auth.logout();
    await SessionManager.clearSession();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final key = _selectedDay != null ? _logic.dateKey(_selectedDay!) : null;
    final mood = key != null ? moods[key] : null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "📅 Calendario",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            tooltip: "Actualizar",
            onPressed: _loadMoods,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Cerrar sesión",
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🌈 Leyenda de colores
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                _legend("Muy Feliz", Colors.yellow.shade600),
                _legend("Feliz", Colors.green.shade500),
                _legend("Neutral", Colors.grey.shade400),
                _legend("Triste", Colors.lightBlue.shade400),
                _legend("Muy Triste", Colors.red.shade400),
              ],
            ),
            const SizedBox(height: 16),

            // 📆 Calendario principal
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

                    // 🧠 Bloquear días futuros
                    enabledDayPredicate: (day) {
                      final now = DateTime.now();
                      return !day.isAfter(DateTime(now.year, now.month, now.day));
                    },

                    onDaySelected: (selected, focused) {
                      if (selected.isAfter(DateTime.now())) return;
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },

                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    calendarStyle:
                        const CalendarStyle(isTodayHighlighted: false),

                    // 🎨 Personalización de las celdas
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final key = _logic.dateKey(day);
                        final mood = moods[key];
                        final bool isSelected = isSameDay(_selectedDay, day);

                        final bg = mood != null
                            ? _logic.getMoodColor(mood)
                            : Colors.white;

                        return Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: bg,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 3)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${day.day}",
                            style: TextStyle(
                              color: mood != null
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // 🟢 Botón agregar/editar emoción
            if (_selectedDay != null)
              GestureDetector(
                onTap: () {
                  if (_selectedDay!.isAfter(DateTime.now())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No puedes registrar emociones futuras."),
                      ),
                    );
                  } else {
                    _openMoodInput(_selectedDay!, mood);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.lightGreen.shade400,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        mood == null
                            ? "Agregar emoción"
                            : "Editar emoción ($mood)",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend(String text, Color color) {
    return Chip(
      backgroundColor: color,
      label: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
