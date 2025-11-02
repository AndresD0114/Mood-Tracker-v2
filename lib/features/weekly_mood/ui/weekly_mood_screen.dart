import 'package:flutter/material.dart';
import '../logic/weekly_mood_logic.dart';
import 'weekly_mood_chat.dart';

class MoodStatsScreen extends StatefulWidget {
  const MoodStatsScreen({super.key});

  @override
  State<MoodStatsScreen> createState() => _MoodStatsScreenState();
}

class _MoodStatsScreenState extends State<MoodStatsScreen> {
  final WeeklyMoodLogic _logic = WeeklyMoodLogic();
  List<double?> averages = List<double?>.filled(7, null);
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final computed = await _logic.loadAndCompute(_selectedRange);
    setState(() => averages = computed);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );

    if (picked != null) {
      setState(() => _selectedRange = picked);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAny = averages.any((e) => e != null);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("📊 Estadísticas semanales",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey.shade100,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: hasAny
            ? Column(
                children: [
                  _buildBanner(),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: WeeklyMoodBarChart(values: averages),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildLegendRow()
                ],
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 64, color: Colors.black26),
                    SizedBox(height: 12),
                    Text('Aún no hay datos para mostrar'),
                    Text('Registra estados desde la pantalla principal'),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.teal.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
        ),
        child: Row(
          children: [
            const Icon(Icons.insights, size: 40, color: Colors.white),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tu resumen emocional",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    _selectedRange == null
                        ? "Selecciona un rango para ver tendencias"
                        : "Del ${_selectedRange!.start.day}/${_selectedRange!.start.month} "
                          "al ${_selectedRange!.end.day}/${_selectedRange!.end.month}",
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _pickDateRange,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.date_range),
              label: const Text("Rango"),
            ),
          ],
        ),
      );

  Widget _buildLegendRow() => Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        children: [
          _buildLegend("😁 Muy Feliz", Colors.yellow.shade600),
          _buildLegend("🙂 Feliz", Colors.green.shade500),
          _buildLegend("😐 Neutral", Colors.grey.shade400),
          _buildLegend("😢 Triste", Colors.lightBlue.shade400),
          _buildLegend("😭 Muy Triste", Colors.red.shade400),
        ],
      );

  Widget _buildLegend(String text, Color color) => Chip(
        backgroundColor: color,
        label: Text(text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
}
