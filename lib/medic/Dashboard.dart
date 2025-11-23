// lib/medic/Dashboard.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dates_graph.dart';

// NUEVO IMPORT
import 'enfermedades_pie_chart_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool _loadingMedicoIds = true;
  late Set<String> _medicoIds;

  @override
  void initState() {
    super.initState();
    _loadAcceptedMedicoIds();
  }

  Future<void> _loadAcceptedMedicoIds() async {
    final user = _auth.currentUser;
    final ids = <String>{};

    if (user != null) {
      ids.add(user.uid);

      try {
        final doc = await _db.collection('usuarios').doc(user.uid).get();
        final data = doc.data();
        final possible =
            (data?['medicoId'] ?? data?['id_medico'] ?? data?['alias'])
                ?.toString();
        if (possible != null && possible.trim().isNotEmpty) {
          ids.add(possible.trim());
        }

        final nombre = (data?['nombre'] ?? '').toString().toLowerCase();
        if (nombre.contains('joel')) {
          ids.add('dr_joel');
        }
      } catch (_) {}
    }

    if (ids.isEmpty) ids.add('dr_joel');

    setState(() {
      _medicoIds = ids;
      _loadingMedicoIds = false;
    });
  }

  String _fmtFechaHora(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy  $hh:$min';
  }

  String _fmtSoloFecha(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  List<_Appt> _mapDocsToAppointments(List<QueryDocumentSnapshot> docs) {
    final list = <_Appt>[];
    for (final d in docs) {
      final m = d.data() as Map<String, dynamic>;
      final ts = m['cuando'] as Timestamp?;
      final dt = ts?.toDate();
      if (dt == null) continue;

      list.add(_Appt(
        id: d.id,
        cuando: dt,
        cuandoFin: (m['cuandoFin'] as Timestamp?)?.toDate(),
        medicoId: (m['medicoId'] ?? '').toString(),
        pacienteId: (m['pacienteId'] ?? '').toString(),
        motivo: (m['motivo'] ?? m['titulo'] ?? '—').toString(),
        titulo: (m['titulo'] ?? m['motivo'] ?? 'Cita médica').toString(),
        lugar: (m['lugar'] ?? '—').toString(),
      ));
    }
    return list;
  }

  Future<Map<String, String>> _fetchPatientNames(Set<String> ids) async {
    final out = <String, String>{};
    if (ids.isEmpty) return out;

    final list = ids.toList();
    for (int i = 0; i < list.length; i += 10) {
      final chunk = list.sublist(i, min(i + 10, list.length));
      try {
        final q = await _db
            .collection('usuarios')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in q.docs) {
          final data = doc.data();
          final nombre =
              (data['nombre'] ?? data['name'] ?? 'Paciente').toString();
          out[doc.id] = nombre;
        }
      } catch (_) {}
    }
    return out;
  }

  // ================================================================
  //  BOTTOM SHEET PARA GRÁFICA DE ENFERMEDADES (PASTEL)
  // ================================================================
  void _showEnfermedadesPie(BuildContext context, Map<String, int> freq) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.80,
          child: EnfermedadesPieChartPage(enfermedadesCount: freq),
        );
      },
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(.25),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingMedicoIds) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final citasStream = _db.collection('citas').snapshots();

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: citasStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Dashboard de citas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Error al cargar citas: ${snap.error}'),
              ],
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = _mapDocsToAppointments(snap.data!.docs);
          final appts = all.where((a) => _medicoIds.contains(a.medicoId)).toList();
          appts.sort((a, b) => a.cuando.compareTo(b.cuando));

          final now = DateTime.now();
          final totalCitas = appts.length;
          final proximas = appts.where((a) => a.cuando.isAfter(now)).toList();

          final pacientesUnicos = appts
              .map((a) => a.pacienteId)
              .where((id) => id.trim().isNotEmpty)
              .toSet();

          // enfermedad top (motivo o titulo)
          final freq = <String, int>{};
          for (final a in appts) {
            final key = a.motivo.trim().isEmpty ? a.titulo.trim() : a.motivo.trim();
            if (key.isEmpty) continue;
            freq[key] = (freq[key] ?? 0) + 1;
          }
          String topEnf = '—';
          int topCount = 0;
          freq.forEach((k, v) {
            if (v > topCount) {
              topCount = v;
              topEnf = k;
            }
          });

          final apptsForChart = appts;

          return FutureBuilder<Map<String, String>>(
            future: _fetchPatientNames(pacientesUnicos),
            builder: (context, namesSnap) {
              final names = namesSnap.data ?? {};

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Dashboard de citas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Resumen en tiempo real de tus citas médicas.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 14),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      _metricCard(
                        title: 'Citas creadas',
                        value: '$totalCitas',
                        subtitle: 'Total registradas',
                        color: const Color(0xFF2196F3),
                        icon: Icons.event_available,
                        // TU GRÁFICA DE SEMANA ACTUAL (ya la tienes)
                        onTap: () {
                          final fechas = apptsForChart.map((a) => a.cuando).toList();
                          final map = _buildWeekMap(fechas);

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            backgroundColor: Colors.white,
                            builder: (_) {
                              return SizedBox(
                                height: MediaQuery.of(context).size.height * 0.75,
                                child: CitasPorSemanaChartPage(citasPorDia: map),
                              );
                            },
                          );
                        },
                      ),

                      _metricCard(
                        title: 'Citas próximas',
                        value: '${proximas.length}',
                        subtitle: 'Pendientes por atender',
                        color: const Color(0xFF4CAF50),
                        icon: Icons.schedule,
                      ),

                      _metricCard(
                        title: 'Pacientes atendidos',
                        value: '${pacientesUnicos.length}',
                        subtitle: 'Con al menos 1 cita',
                        color: const Color(0xFFFF9800),
                        icon: Icons.people_alt,
                      ),

                      _metricCard(
                        title: 'Enfermedad top',
                        value: '$topCount',
                        subtitle: topEnf,
                        color: const Color(0xFF9C27B0),
                        icon: Icons.healing,
                        // NUEVO: ABRE PIE CHART DESDE ABAJO
                        onTap: () => _showEnfermedadesPie(context, freq),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Próximas citas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (proximas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No tienes citas próximas.')),
                    )
                  else
                    Column(
                      children: proximas.take(5).map((a) {
                        final pacienteNombre = names[a.pacienteId] ?? a.pacienteId;

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.medical_services_outlined),
                            title: Text(a.titulo,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              '${_fmtFechaHora(a.cuando)}  •  ${a.lugar}\nPaciente: $pacienteNombre',
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 18),

                  const Text(
                    'Pacientes atendidos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (pacientesUnicos.isEmpty)
                    const Text('Aún no tienes pacientes registrados.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pacientesUnicos.map((id) {
                        final nombre = names[id] ?? id;
                        return Chip(
                          avatar: const Icon(Icons.person, size: 18),
                          label: Text(nombre),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ===== helper para semana actual (la que ya usas) =====
  Map<String, int> _buildWeekMap(List<DateTime> fechas) {
    String two(int n) => n.toString().padLeft(2, '0');
    String keyYMD(DateTime d) => "${d.year}-${two(d.month)}-${two(d.day)}";

    DateTime startOfCurrentWeek(DateTime now) {
      final n = DateTime(now.year, now.month, now.day);
      return n.subtract(Duration(days: n.weekday - 1)); // lunes
    }

    final now = DateTime.now();
    final start = startOfCurrentWeek(now);
    final end = start.add(const Duration(days: 6));

    final map = <String, int>{};
    for (final f in fechas) {
      final d = DateTime(f.year, f.month, f.day);
      if (d.isBefore(start) || d.isAfter(end)) continue;
      final k = keyYMD(d);
      map[k] = (map[k] ?? 0) + 1;
    }
    return map;
  }
}

// ===== modelo interno =====
class _Appt {
  final String id;
  final DateTime cuando;
  final DateTime? cuandoFin;
  final String medicoId;
  final String pacienteId;
  final String motivo;
  final String titulo;
  final String lugar;

  _Appt({
    required this.id,
    required this.cuando,
    this.cuandoFin,
    required this.medicoId,
    required this.pacienteId,
    required this.motivo,
    required this.titulo,
    required this.lugar,
  });
}
