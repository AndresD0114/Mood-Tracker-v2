import 'package:flutter/material.dart';

class WeeklyMoodBarChart extends StatelessWidget {
  final List<double?> values;
  final double maxValue;
  final double maxBarHeight;
  final double barWidth;

  const WeeklyMoodBarChart({
    super.key,
    required this.values,
    this.maxValue = 4.0,
    this.maxBarHeight = 180.0,
    this.barWidth = 28.0,
  }) : assert(values.length == 7);

  static const weekdayLabels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String _emojiForValue(double? v) {
    if (v == null) return '—';
    if (v < 0.5) return '😭';
    if (v < 1.5) return '😢';
    if (v < 2.5) return '😐';
    if (v < 3.5) return '🙂';
    return '😁';
  }

  Color _colorForValue(double? v) {
    if (v == null) return Colors.grey.shade300;
    if (v < 0.5) return Colors.red.shade400;
    if (v < 1.5) return Colors.lightBlue.shade400;
    if (v < 2.5) return Colors.grey.shade500;
    if (v < 3.5) return Colors.green.shade500;
    return Colors.yellow.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxBarHeight + 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final v = values[i];
          final t = (v ?? 0) / maxValue;
          final barHeight = (v == null) ? 12.0 : (t * maxBarHeight).clamp(12.0, maxBarHeight);
          final color = _colorForValue(v);
          final emoji = _emojiForValue(v);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: barHeight,
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  weekdayLabels[i],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
