import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CitasPorSemanaChartPage extends StatelessWidget {
  /// key = "YYYY-MM-DD", value = cantidad de citas ese día
  final Map<String, int> citasPorDia;

  const CitasPorSemanaChartPage({
    super.key,
    required this.citasPorDia,
  });

  // ========= HELPERS SIN intl =========

  String _two(int n) => n.toString().padLeft(2, '0');

  /// "YYYY-MM-DD"
  String keyYMD(DateTime d) =>
      "${d.year}-${_two(d.month)}-${_two(d.day)}";

  /// Lunes de la semana actual (ISO)
  DateTime startOfCurrentWeek(DateTime now) {
    final n = DateTime(now.year, now.month, now.day);
    return n.subtract(Duration(days: n.weekday - 1)); // lunes
  }

  /// Formato dd/MM
  String fmtDM(DateTime d) => "${_two(d.day)}/${_two(d.month)}";

  /// Etiquetas: "Lun\n11/11"
  String labelForDay(DateTime d) {
    const names = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final idx = d.weekday - 1; // Lun=0..Dom=6
    return "${names[idx]}\n${fmtDM(d)}";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startWeek = startOfCurrentWeek(now);

    // 7 días de la semana actual: lunes a domingo
    final days = List.generate(7, (i) => startWeek.add(Duration(days: i)));

    // construir barras por día
    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < days.length; i++) {
      final d = days[i];
      final k = keyYMD(d);
      final value = citasPorDia[k] ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              width: 18,
              borderRadius: BorderRadius.circular(4),
              // colores distintos por barra
              color: Colors.primaries[i % Colors.primaries.length],
            ),
          ],
        ),
      );
    }

    final rangoLabel =
        "${fmtDM(days.first)} - ${fmtDM(days.last)}";

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Semana actual ($rangoLabel)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cada barra representa el total de citas creadas por día.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= days.length) {
                            return const SizedBox.shrink();
                          }
                          final d = days[idx];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              labelForDay(d),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final d = days[group.x.toInt()];
                        return BarTooltipItem(
                          '${labelForDay(d)}\n',
                          const TextStyle(fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: 'Citas: ${rod.toY.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.normal),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
