// lib/screens/my_appointments_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'edit_appointment_dialog.dart'; // <-- usamos este editor
import 'Medics_available.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  DateTime? _startDate;
  DateTime? _endDate;

  String _fmtFecha(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _fmtHora(DateTime d) => DateFormat('HH:mm').format(d);
  DateTime _soloDia(DateTime d) => DateTime(d.year, d.month, d.day);

  // id del doc de disponibilidad
  String _dispDocId(String medicoId, DateTime inicio) =>
      '${medicoId}_${DateFormat('yyyyMMdd_HHmm').format(inicio)}';

  Query _appointmentsQuery() {
    Query q = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_uid)
        .collection('citas')
        .orderBy('cuando');

    if (_startDate != null) {
      final from = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      q = q.where('cuando', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (_endDate != null) {
      final to = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59, 999);
      q = q.where('cuando', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }
    return q;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  // ========= Detalle con botón Editar (abre showEditAppointmentDialog) =========
  void _mostrarDetalleCita(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final inicio = (data['cuando'] as Timestamp?)?.toDate();
    final fin = (data['cuandoFin'] as Timestamp?)?.toDate() ??
        (inicio == null ? null : inicio.add(const Duration(hours: 1)));
    final medico = data['medicoId']?.toString() ?? '—';
    final lugar = data['lugar']?.toString() ?? '—';
    final motivo = data['motivo']?.toString() ?? '—';
    final titulo = (data['titulo'] ?? motivo).toString();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.person_pin, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Médico: $medico')),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.place_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Lugar: $lugar')),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (inicio == null)
                        ? 'Horario: —'
                        : 'Horario: ${_fmtFecha(inicio)}  ${_fmtHora(inicio)} - ${_fmtHora(fin!)}',
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Text('Motivo: $motivo'),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                    onPressed: () async {
                      Navigator.pop(context);
                      await showEditAppointmentDialog(
                        context,
                        userApptDoc: doc,
                        titulo: 'Modificar cita',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis citas')),
        body: const Center(child: Text('Inicia sesión para ver tus citas.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis citas')),
      body: ListView(
        children: [
          // ===== Filtro por rango =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _startDate == null ? 'Fecha inicio' : 'Inicio: ${_fmtFecha(_startDate!)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pickEndDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _endDate == null ? 'Fecha fin' : 'Fin: ${_fmtFecha(_endDate!)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_startDate != null || _endDate != null)
                  IconButton(
                    tooltip: 'Limpiar',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                  )
              ],
            ),
          ),

          const Divider(),

          // ===== Lista de citas =====
          StreamBuilder<QuerySnapshot>(
            stream: _appointmentsQuery().snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: ${snap.error}'),
                );
              }
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('No hay citas en el rango seleccionado.')),
                );
              }

              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final titulo = (data['titulo'] ?? data['motivo'] ?? 'Cita médica').toString();
                  final lugar = (data['lugar'] ?? '—').toString();

                  final tsInicio = data['cuando'] as Timestamp?;
                  final inicio = tsInicio?.toDate();
                  final medicoId = data['medicoId']?.toString();

                  DateTime? fin;
                  if (data['cuandoFin'] is Timestamp) {
                    fin = (data['cuandoFin'] as Timestamp).toDate();
                  } else if (inicio != null) {
                    fin = inicio.add(const Duration(hours: 1));
                  }

                  final fecha = inicio == null ? '—' : _fmtFecha(inicio);
                  final horaInicio = inicio == null ? '—' : _fmtHora(inicio);
                  final horaFin = fin == null ? '—' : _fmtHora(fin!);

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.event_available),
                      title: Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('$fecha  •  $horaInicio - $horaFin  •  $lugar'),
                      onTap: () => _mostrarDetalleCita(d),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () async {
                              await showEditAppointmentDialog(
                                context,
                                userApptDoc: d,
                                titulo: 'Modificar cita',
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final fechaTxt = inicio == null
                                  ? '—'
                                  : DateFormat('dd/MM/yyyy – HH:mm').format(inicio);
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Eliminar cita'),
                                  content: Text('¿Eliminar “$titulo” el $fechaTxt ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton.tonal(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Sí, eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true && inicio != null) {
                                try {
                                  // 1) Borrar la cita del usuario
                                  await d.reference.delete();

                                  // 2) Liberar disponibilidad (borrar doc)
                                  if (medicoId != null) {
                                    final dispRef = FirebaseFirestore.instance
                                        .collection('disponibilidad_medicos')
                                        .doc(_dispDocId(medicoId, inicio));
                                    final dispSnap = await dispRef.get();
                                    if (dispSnap.exists) {
                                      await dispRef.delete();
                                    } else {
                                      final q = await FirebaseFirestore.instance
                                          .collection('disponibilidad_medicos')
                                          .where('medicoId', isEqualTo: medicoId)
                                          .where('fecha',
                                              isEqualTo: Timestamp.fromDate(_soloDia(inicio)))
                                          .where('horaInicio',
                                              isEqualTo: Timestamp.fromDate(inicio))
                                          .limit(1)
                                          .get();
                                      for (final e in q.docs) {
                                        await e.reference.delete();
                                      }
                                    }
                                  }

                                  // 3) Borrar en colección global `citas` POR ID (si existe)
                                  final globalRef = FirebaseFirestore.instance
                                      .collection('citas')
                                      .doc(d.id);
                                  final snapGlobal = await globalRef.get();
                                  if (snapGlobal.exists) {
                                    await globalRef.delete();
                                  } else {
                                    // Fallback para citas viejas creadas sin ID compartido
                                    try {
                                      final startTs = Timestamp.fromDate(inicio);
                                      final endTs =
                                          Timestamp.fromDate(inicio.add(const Duration(hours: 1)));

                                      Query gq = FirebaseFirestore.instance
                                          .collection('citas')
                                          .where('pacienteId', isEqualTo: _uid)
                                          .where('cuando', isGreaterThanOrEqualTo: startTs)
                                          .where('cuando', isLessThan: endTs);

                                      if ((medicoId ?? '').isNotEmpty) {
                                        gq = gq.where('medicoId', isEqualTo: medicoId);
                                      }

                                      var gdocs = await gq.get();

                                      if (gdocs.docs.isEmpty) {
                                        gdocs = await FirebaseFirestore.instance
                                            .collection('citas')
                                            .where('pacienteId', isEqualTo: _uid)
                                            .where('cuando', isEqualTo: Timestamp.fromDate(inicio))
                                            .get();
                                      }

                                      for (final e in gdocs.docs) {
                                        await e.reference.delete();
                                      }
                                    } catch (_) {}
                                  }

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Cita eliminada y bloque liberado.')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al eliminar: $e')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 25),
          const Divider(thickness: 1),
          const SizedBox(height: 10),

          // ===== Panel de disponibilidad =====
          const DoctorAvailabilitySection(),
        ],
      ),
    );
  }
}
