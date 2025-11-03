import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../logic/mood_controller.dart';
import '../../../../../firebase/data/auth_datasource.dart';
import '../../../../../firebase/data/auth_repository.dart';
import '../../../../../firebase/logic/auth_controller.dart';
import '../../../../firebase/UsuarioMoodService.dart';
import '../../../../session_manager.dart';

import '../../login/ui/login.dart';

class MoodInputScreen extends StatefulWidget {
  final String? initialMood;
  final DateTime? selectedDate;

  const MoodInputScreen({
    super.key,
    this.initialMood,
    this.selectedDate,
  });

  @override
  State<MoodInputScreen> createState() => _MoodInputScreenState();
}

class _MoodInputScreenState extends State<MoodInputScreen> {
  late MoodController controller;
  late AuthController authController;

  final TextEditingController _noteCtrl = TextEditingController();

  final Map<String, Map<String, dynamic>> moodOptions = {
    "Muy Feliz": {"emoji": "😁", "color": Colors.yellow.shade700},
    "Feliz": {"emoji": "😊", "color": Colors.green.shade400},
    "Neutral": {"emoji": "😐", "color": Colors.grey.shade500},
    "Triste": {"emoji": "😔", "color": Colors.blue.shade400},
    "Muy Triste": {"emoji": "😭", "color": Colors.red.shade400},
  };

  @override
  void initState() {
    super.initState();

    // Inyección simple
    final ds = AuthRemoteDataSource();
    final repo = AuthRepository(ds);
    final moodService = UsuarioMoodService(authRepository: repo);
    authController = AuthController(repo);

    controller = MoodController(
      moodOptions,
      moodService: moodService,
    );

    // Si viene mood preseleccionado, lo asigno
    controller.selectedMood = widget.initialMood;

    // 🔄 Cargar mood+nota existentes (local/remoto) del día mostrado
    final date = widget.selectedDate ?? DateTime.now();
    _loadExisting(date);
  }

  Future<void> _loadExisting(DateTime date) async {
    final data = await controller.loadForDate(date);
    if (!mounted) return;

    setState(() {
      // El controller ya setea selectedMood si existe
      final note = data["note"];
      if (note != null && note.isNotEmpty) {
        _noteCtrl.text = note; // 👈 Pintar nota traída de BD o local
      }
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    if (controller.selectedMood == null) return;

    final date = widget.selectedDate ?? DateTime.now();
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    await controller.saveMood(date, note: note);

    if (!mounted) return;

    final cameFromCalendar =
        widget.selectedDate != null && Navigator.of(context).canPop();

    if (cameFromCalendar) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "✅ Tu estado de ánimo ha sido guardado correctamente",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    // No limpio la nota: si el usuario vuelve quiere verla editada.
    // _noteCtrl.clear();
  }

  Future<void> _logout() async {
    await authController.logout();
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
    final dateText = (widget.selectedDate ?? DateTime.now());
    final datePretty =
        DateFormat("EEEE, d 'de' MMMM yyyy", "es_ES").format(dateText);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Banner con botón salir
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.lightGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  children: [
                    const Icon(Icons.emoji_emotions, size: 60, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text(
                      "Tu estado de ánimo importa 💚",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      datePretty,
                      style: const TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                Positioned(
                  right: 15,
                  top: 10,
                  child: IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: "Cerrar sesión",
                  ),
                ),
              ],
            ),
          ),

          // Opciones + Nota
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: moodOptions.entries.map((entry) {
                      final mood = entry.key;
                      final emoji = entry.value["emoji"];
                      final color = entry.value["color"];
                      final isSelected = controller.selectedMood == mood;

                      return GestureDetector(
                        onTap: () => setState(() => controller.selectedMood = mood),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: isSelected ? color : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected ? color.withOpacity(0.5) : Colors.black12,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            border: Border.all(
                              color: isSelected ? Colors.transparent : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 40)),
                                const SizedBox(height: 8),
                                Text(
                                  mood,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: controller.selectedMood == null
                        ? const SizedBox.shrink()
                        : TextField(
                            key: const ValueKey('noteField'),
                            controller: _noteCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: "Nota (opcional)",
                              hintText: "Escribí algo sobre cómo te sentís...",
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                                borderSide: BorderSide(color: Colors.green, width: 2),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Botón guardar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.selectedMood != null ? _saveMood : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: controller.selectedMood != null ? Colors.green : Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text("Guardar", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
