import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EnfermedadesPieChartPage extends StatefulWidget {
  /// key = nombre enfermedad (motivo), value = cantidad de citas
  final Map<String, int> enfermedadesCount;

  const EnfermedadesPieChartPage({
    super.key,
    required this.enfermedadesCount,
  });

  @override
  State<EnfermedadesPieChartPage> createState() =>
      _EnfermedadesPieChartPageState();
}

class _EnfermedadesPieChartPageState extends State<EnfermedadesPieChartPage> {
  bool _dialogOpen = false;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, int>> entries = widget.enfermedadesCount.entries
        .where((e) => e.key.trim().isNotEmpty && e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final int total =
        entries.fold<int>(0, (sum, item) => sum + item.value);

    if (entries.isEmpty || total == 0) {
      return const Center(
        child: Text(
          'No hay enfermedades registradas para graficar.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Top 6 + "Otras"
    final List<MapEntry<String, int>> top =
        entries.length > 6 ? entries.take(6).toList() : entries;

    final List<MapEntry<String, int>> rest =
        entries.length > 6 ? entries.skip(6).toList() : [];

    int otherCount = rest.fold(0, (s, e) => s + e.value);

    final List<MapEntry<String, int>> finalEntries = [
      ...top,
      if (otherCount > 0) MapEntry("Otras", otherCount),
    ];

    final List<Color> colors = List.generate(
      finalEntries.length,
      (i) => Colors.primaries[i % Colors.primaries.length],
    );

    final List<PieChartSectionData> sections = List.generate(
      finalEntries.length,
      (i) {
        final e = finalEntries[i];
        final percent = (e.value / total) * 100;

        return PieChartSectionData(
          color: colors[i],
          value: e.value.toDouble(),
          radius: 75,
          title: "${percent.toStringAsFixed(1)}%",
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      },
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribución por enfermedad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Toca una sección para ver más información.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),

            // ✅ GRÁFICO MÁS ARRIBA (altura fija)
            Center(
              child: SizedBox(
                height: 260, // antes quedaba muy abajo
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 0,
                    sections: sections,
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        if (event is! FlTapUpEvent) return;

                        final touched = response?.touchedSection;
                        if (touched == null) return;

                        final idx = touched.touchedSectionIndex;
                        if (idx < 0 || idx >= finalEntries.length) return;

                        if (_dialogOpen) return;
                        _dialogOpen = true;

                        final item = finalEntries[idx];
                        final percent = (item.value / total) * 100;

                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colors[idx],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.key,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Citas: ${item.value}',
                                    style: const TextStyle(fontSize: 15)),
                                const SizedBox(height: 6),
                                Text(
                                  'Porcentaje: ${percent.toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        ).then((_) => _dialogOpen = false);
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            const Divider(),

            // ✅ ÍNDICE/LEYENDA CLARA Y CERCANA
            Expanded(
              child: ListView.builder(
                itemCount: finalEntries.length,
                itemBuilder: (_, i) {
                  final e = finalEntries[i];
                  final percent = (e.value / total) * 100;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: colors[i],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          "${e.value}  •  ${percent.toStringAsFixed(1)}%",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
