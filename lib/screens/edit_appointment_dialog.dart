// lib/screens/edit_appointment_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// ===== Helpers
DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);
String _fmtFecha(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
String _fmtHora(DateTime d) => DateFormat('HH:mm').format(d);
String _dispDocId(String medicoId, DateTime inicio) =>
    '${medicoId}_${DateFormat('yyyyMMdd_HHmm').format(inicio)}';

List<DateTime> _bloquesDelDia(DateTime day, {int inicio = 8, int finExclusivo = 20}) {
  final base = DateTime(day.year, day.month, day.day);
  return [for (var h = inicio; h < finExclusivo; h++) base.add(Duration(hours: h))];
}

/// Catálogo de médicos (ajústalo si lo necesitas)
const _medicos = <Map<String, String>>[
  {'id': 'dr_lopez', 'nombre': 'Dr. López'},
  {'id': 'dra_martinez', 'nombre': 'Dra. Martínez'},
  {'id': 'dr_ramirez', 'nombre': 'Dr. Ramírez'},
  {'id': 'dra_gomez', 'nombre': 'Dra. Gómez'},
  {'id': 'dr_perez', 'nombre': 'Dr. Pérez'},
  {'id': 'dra_ruiz', 'nombre': 'Dra. Ruiz'},
  {'id': 'dr_castro', 'nombre': 'Dr. Castro'},
];

/// Diálogo para editar una cita del usuario.
/// `userApptDoc` = doc en `usuarios/{uid}/citas/{id}` (se asume MISMO id en `citas/{id}`)
Future<void> showEditAppointmentDialog(
  BuildContext context, {
  required DocumentSnapshot userApptDoc,
  String titulo = 'Modificar cita',
}) async {
  final data = userApptDoc.data() as Map<String, dynamic>? ?? {};
  final String apptId = userApptDoc.id;

  // Valores actuales
  String motivo = (data['motivo'] ?? data['titulo'] ?? '').toString();
  String lugar  = (data['lugar'] ?? '').toString();
  String? medicoIdActual = data['medicoId']?.toString();

  final DateTime inicioActual =
      (data['cuando'] as Timestamp?)?.toDate() ?? DateTime.now();
  final DateTime finActual =
      (data['cuandoFin'] as Timestamp?)?.toDate() ??
      inicioActual.add(const Duration(hours: 1));

  // Estado de edición
  String? selMedicoId = medicoIdActual;
  DateTime selFecha   = _onlyDate(inicioActual);
  DateTime? selInicio = inicioActual; // bloque seleccionado

  final motivoCtrl = TextEditingController(text: motivo);
  final lugarCtrl  = TextEditingController(text: lugar);

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return StatefulBuilder(builder: (ctx, setSt) {
        // Bloques por médico+fecha
        Widget _bloques() {
          if (selMedicoId == null) return const SizedBox.shrink();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('disponibilidad_medicos')
                .where('medicoId', isEqualTo: selMedicoId)
                .where('fecha', isEqualTo: Timestamp.fromDate(selFecha))
                .snapshots(),
            builder: (_, snap) {
              final estado = <DateTime, bool>{}; // inicio -> disponible?
              if (snap.hasData) {
                for (final d in snap.data!.docs) {
                  final m = d.data() as Map<String, dynamic>;
                  final ts = m['horaInicio'] as Timestamp?;
                  if (ts != null) {
                    estado[ts.toDate()] = (m['esta_disponible'] ?? true) as bool;
                  }
                }
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _bloquesDelDia(selFecha).map((b) {
                  final libre = estado[b] ?? true;
                  final esActual = (selMedicoId == medicoIdActual) &&
                      (_dispDocId(selMedicoId!, b) ==
                       _dispDocId(medicoIdActual ?? '', inicioActual));
                  final habilitado = libre || esActual;

                  final etiqueta =
                      '${_fmtHora(b)} - ${_fmtHora(b.add(const Duration(hours: 1)))}';

                  return ChoiceChip(
                    label: Text(etiqueta),
                    avatar: Icon(
                      habilitado ? Icons.check_circle : Icons.lock_clock,
                      size: 18,
                      color: habilitado ? Colors.green : Colors.red,
                    ),
                    selected: selInicio == b,
                    onSelected: (sel) {
                      if (!habilitado) return;
                      setSt(() => selInicio = sel ? b : null);
                    },
                    selectedColor: Colors.green.shade100,
                    backgroundColor:
                        habilitado ? Colors.green.shade50 : Colors.red.shade50,
                  );
                }).toList(),
              );
            },
          );
        }

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(titulo,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: motivoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motivo / Título',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lugarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lugar',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: selMedicoId,
                  items: _medicos
                      .map((m) => DropdownMenuItem(
                            value: m['id'],
                            child: Text(m['nombre']!),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setSt(() {
                      selMedicoId = v;
                      selInicio = null; // al cambiar médico, obliga a elegir horario
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Médico',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selFecha,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 2),
                          );
                          if (picked != null) {
                            setSt(() {
                              selFecha = _onlyDate(picked);
                              selInicio = null; // obliga a re-elegir bloque
                            });
                          }
                        },
                        icon: const Icon(Icons.today_outlined),
                        label: Text(_fmtFecha(selFecha)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Bloques',
                      style: TextStyle(
                          color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 6),
                _bloques(),
                const SizedBox(height: 12),

                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cancelar'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar'),
                      onPressed: () async {
                        try {
                          final nuevoMotivo = motivoCtrl.text.trim();
                          final nuevoLugar  = lugarCtrl.text.trim();
                          final nuevoMedico = selMedicoId;
                          final nuevoInicio = selInicio ?? inicioActual;
                          final nuevoFin    = nuevoInicio.add(const Duration(hours: 1));

                          if (nuevoMotivo.isEmpty || nuevoLugar.isEmpty || nuevoMedico == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Completa motivo, lugar y médico.')),
                            );
                            return;
                          }

                          final cambioMedico  = nuevoMedico != medicoIdActual;
                          final cambioHorario = nuevoInicio != inicioActual;

                          // 1) Disponibilidad
                          if (cambioMedico || cambioHorario) {
                            // liberar viejo
                            if (medicoIdActual != null) {
                              final oldId  = _dispDocId(medicoIdActual!, inicioActual);
                              final oldRef = FirebaseFirestore.instance
                                  .collection('disponibilidad_medicos')
                                  .doc(oldId);
                              final oldSnap = await oldRef.get();
                              if (oldSnap.exists) {
                                await oldRef.delete();
                              } else {
                                final q = await FirebaseFirestore.instance
                                    .collection('disponibilidad_medicos')
                                    .where('medicoId', isEqualTo: medicoIdActual)
                                    .where('fecha', isEqualTo: Timestamp.fromDate(_onlyDate(inicioActual)))
                                    .where('horaInicio', isEqualTo: Timestamp.fromDate(inicioActual))
                                    .limit(1).get();
                                for (final e in q.docs) { await e.reference.delete(); }
                              }
                            }
                            // reservar nuevo
                            final newId = _dispDocId(nuevoMedico, nuevoInicio);
                            await FirebaseFirestore.instance
                                .collection('disponibilidad_medicos')
                                .doc(newId)
                                .set({
                              'medicoId': nuevoMedico,
                              'fecha': Timestamp.fromDate(_onlyDate(nuevoInicio)),
                              'horaInicio': Timestamp.fromDate(nuevoInicio),
                              'horaFin': Timestamp.fromDate(nuevoFin),
                              'esta_disponible': false,
                            }, SetOptions(merge: true));
                          }

                          // 2) Subcolección del usuario
                          await userApptDoc.reference.update({
                            'motivo': nuevoMotivo,
                            'titulo': nuevoMotivo,
                            'lugar': nuevoLugar,
                            'medicoId': nuevoMedico,
                            'cuando': Timestamp.fromDate(nuevoInicio),
                            'cuandoFin': Timestamp.fromDate(nuevoFin),
                          });

                          // 3) Colección global (mismo id)
                          final globalRef = FirebaseFirestore.instance
                              .collection('citas')
                              .doc(apptId);
                          final gSnap = await globalRef.get();
                          if (gSnap.exists) {
                            await globalRef.update({
                              'motivo': nuevoMotivo,
                              'lugar': nuevoLugar,
                              'medicoId': nuevoMedico,
                              'cuando': Timestamp.fromDate(nuevoInicio),
                              'cuandoFin': Timestamp.fromDate(nuevoFin),
                            });
                          } else {
                            // fallback para citas antiguas sin id compartido
                            try {
                              final gStart = Timestamp.fromDate(inicioActual);
                              final gEnd   = Timestamp.fromDate(inicioActual.add(const Duration(hours: 1)));
                              var gq = FirebaseFirestore.instance
                                  .collection('citas')
                                  .where('pacienteId', isEqualTo: (data['pacienteId'] ?? ''))
                                  .where('cuando', isGreaterThanOrEqualTo: gStart)
                                  .where('cuando', isLessThan: gEnd);
                              if ((medicoIdActual ?? '').isNotEmpty) {
                                gq = gq.where('medicoId', isEqualTo: medicoIdActual);
                              }
                              var gdocs = await gq.get();
                              if (gdocs.docs.isEmpty) {
                                gdocs = await FirebaseFirestore.instance
                                    .collection('citas')
                                    .where('pacienteId', isEqualTo: (data['pacienteId'] ?? ''))
                                    .where('cuando', isEqualTo: Timestamp.fromDate(inicioActual))
                                    .get();
                              }
                              for (final e in gdocs.docs) {
                                await e.reference.update({
                                  'motivo': nuevoMotivo,
                                  'lugar': nuevoLugar,
                                  'medicoId': nuevoMedico,
                                  'cuando': Timestamp.fromDate(nuevoInicio),
                                  'cuandoFin': Timestamp.fromDate(nuevoFin),
                                });
                              }
                            } catch (_) {}
                          }

                          if (context.mounted) {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cita actualizada ✅')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
    },
  );

  motivoCtrl.dispose();
  lugarCtrl.dispose();
}
