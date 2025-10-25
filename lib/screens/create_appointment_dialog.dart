// lib/screens/create_appointment_dialog.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
String _dispDocId(String medicoId, DateTime inicio) {
  final f = DateFormat('yyyyMMdd_HHmm').format(inicio);
  return '${medicoId}_$f';
}

// Config jornada para bloques (08:00-20:00).
const int _inicioJornada = 8;   // 08:00
const int _finJornada   = 20;   // 20:00 (exclusivo)

List<DateTime> _generarBloques(DateTime dia) {
  final base = DateTime(dia.year, dia.month, dia.day);
  return [for (var h = _inicioJornada; h < _finJornada; h++) base.add(Duration(hours: h))];
}

String _fmtFecha(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
String _fmtHora(DateTime d)  => DateFormat('HH:mm').format(d);

/// Dialog para crear cita con selección de bloque (reserva disponibilidad)
Future<void> showCreateAppointmentDialog(
  BuildContext context, {
  String? motivoSugerido,
  String? lugarSugerido,
  String? medicoIdSugerido,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para crear una cita.')),
      );
    }
    return;
  }

  final tituloCtrl = TextEditingController(text: motivoSugerido ?? '');
  final lugarCtrl  = TextEditingController(text: lugarSugerido ?? '');

  DateTime? fecha;             // solo fecha
  String? selMedicoId = medicoIdSugerido;

  DateTime? selectedSlotStart; // bloque elegido (inicio)
  DateTime? selectedSlotEnd;   // bloque fin (inicio + 1h)

  const medicos = <Map<String, String>>[
    {'id': 'dr_lopez',     'nombre': 'Dr. López'},
    {'id': 'dra_martinez', 'nombre': 'Dra. Martínez'},
    {'id': 'dr_ramirez',   'nombre': 'Dr. Ramírez'},
    {'id': 'dra_gomez',    'nombre': 'Dra. Gómez'},
    {'id': 'dr_perez',     'nombre': 'Dr. Pérez'},
    {'id': 'dra_ruiz',     'nombre': 'Dra. Ruiz'},
    {'id': 'dr_castro',    'nombre': 'Dr. Castro'},
  ];

  await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: LayoutBuilder(
          builder: (_, constraints) {
            final maxW = constraints.maxWidth.clamp(0, 560.0);
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxW is double ? maxW : 560,
                maxHeight: 720,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: StatefulBuilder(
                    builder: (innerCtx, setSheet) {
                      final fechaTxt = (fecha == null) ? 'Elegir fecha' : _fmtFecha(fecha!);

                      Widget _buildBloques() {
                        if (selMedicoId == null || fecha == null) return const SizedBox.shrink();
                        final dia = _day(fecha!);
                        final bloques = _generarBloques(dia);

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('disponibilidad_medicos')
                              .where('medicoId', isEqualTo: selMedicoId)
                              .where('fecha', isEqualTo: Timestamp.fromDate(dia))
                              .snapshots(),
                          builder: (ctx, snap) {
                            final Map<DateTime, bool> estado = {};
                            if (snap.hasData) {
                              for (final d in snap.data!.docs) {
                                final data = d.data() as Map<String, dynamic>;
                                final tsIni = data['horaInicio'] as Timestamp?;
                                if (tsIni == null) continue;
                                estado[tsIni.toDate()] = (data['esta_disponible'] ?? true) as bool;
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                const Text('Horario de inicio',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: bloques.map((inicio) {
                                    final disponible = estado[inicio] ?? true;
                                    final fin = inicio.add(const Duration(hours: 1));
                                    final etiqueta = '${_fmtHora(inicio)} - ${_fmtHora(fin)}';
                                    final isSelected = selectedSlotStart == inicio;

                                    return ChoiceChip(
                                      label: Text(etiqueta),
                                      avatar: Icon(
                                        disponible ? Icons.check_circle : Icons.lock_clock,
                                        size: 18,
                                        color: disponible ? Colors.green : Colors.red,
                                      ),
                                      selected: isSelected,
                                      onSelected: (sel) {
                                        if (!disponible) return;
                                        setSheet(() {
                                          selectedSlotStart = sel ? inicio : null;
                                          selectedSlotEnd = sel ? fin : null;
                                        });
                                      },
                                      selectedColor: Colors.green.shade100,
                                      backgroundColor:
                                          disponible ? Colors.green.shade50 : Colors.red.shade50,
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                                const Text('Seleccione el bloque disponible del médico',
                                    style: TextStyle(color: Colors.black54)),
                              ],
                            );
                          },
                        );
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 4, width: 48,
                            margin: const EdgeInsets.only(bottom: 12, top: 4),
                            decoration: BoxDecoration(
                              color: Colors.black12, borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Crear cita',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),

                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  TextField(
                                    controller: tituloCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Motivo / Título',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: lugarCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Lugar / Clínica',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    value: selMedicoId,
                                    items: medicos
                                        .map((m) => DropdownMenuItem(
                                              value: m['id'],
                                              child: Text('${m['nombre']}  (${m['id']})'),
                                            ))
                                        .toList(),
                                    onChanged: (v) {
                                      setSheet(() {
                                        selMedicoId = v;
                                        selectedSlotStart = null;
                                        selectedSlotEnd = null;
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
                                              context: innerCtx,
                                              initialDate: fecha ?? now,
                                              firstDate: _day(now),
                                              lastDate: _day(now.add(const Duration(days: 365 * 2))),
                                            );
                                            if (picked != null) {
                                              setSheet(() {
                                                fecha = _day(picked);
                                                selectedSlotStart = null;
                                                selectedSlotEnd = null;
                                              });
                                            }
                                          },
                                          icon: const Icon(Icons.calendar_today),
                                          label: Text(fechaTxt),
                                        ),
                                      ),
                                    ],
                                  ),
                                  _buildBloques(),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.close),
                                  label: const Text('Cancelar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade200,
                                    foregroundColor: Colors.black87,
                                  ),
                                  onPressed: () => Navigator.of(dialogCtx).pop(false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.save_outlined),
                                  label: const Text('Guardar cita'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7E57C2),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    final motivo = tituloCtrl.text.trim();
                                    final lugar  = lugarCtrl.text.trim();

                                    if (motivo.isEmpty ||
                                        lugar.isEmpty ||
                                        selMedicoId == null ||
                                        fecha == null ||
                                        selectedSlotStart == null ||
                                        selectedSlotEnd == null) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Completa motivo, lugar, médico, fecha y bloque.'),
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    final inicio = selectedSlotStart!;
                                    final fin    = selectedSlotEnd!;
                                    final soloDia = _day(inicio);

                                    final String dispId = _dispDocId(selMedicoId!, inicio);
                                    final dispRef = FirebaseFirestore.instance
                                        .collection('disponibilidad_medicos')
                                        .doc(dispId);

                                    try {
                                      // Verificar que el bloque siga libre
                                      final existing = await dispRef.get();
                                      if (existing.exists) {
                                        final data = existing.data() as Map<String, dynamic>;
                                        final ocupado = (data['esta_disponible'] ?? false) == false;
                                        if (ocupado) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Ese horario ya está ocupado.'),
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                      }

                                      // ----- ID COMPARTIDO -----
                                      final userApptRef = FirebaseFirestore.instance
                                          .collection('usuarios')
                                          .doc(uid)
                                          .collection('citas')
                                          .doc(); // genera id

                                      final String apptId = userApptRef.id;
                                      final globalApptRef = FirebaseFirestore.instance
                                          .collection('citas')
                                          .doc(apptId);

                                      final batch = FirebaseFirestore.instance.batch();

                                      final payload = {
                                        'id': apptId,
                                        'pacienteId': uid,
                                        'medicoId': selMedicoId,
                                        'motivo': motivo,
                                        'titulo': motivo,
                                        'lugar': lugar,
                                        'cuando': Timestamp.fromDate(inicio),
                                        'cuandoFin': Timestamp.fromDate(fin),
                                        'creadoEn': FieldValue.serverTimestamp(),
                                      };

                                      batch.set(userApptRef, payload);
                                      batch.set(globalApptRef, payload);

                                      // Reservar bloque
                                      batch.set(
                                        dispRef,
                                        {
                                          'medicoId': selMedicoId,
                                          'fecha': Timestamp.fromDate(soloDia),
                                          'horaInicio': Timestamp.fromDate(inicio),
                                          'horaFin': Timestamp.fromDate(fin),
                                          'esta_disponible': false,
                                        },
                                        SetOptions(merge: true),
                                      );

                                      await batch.commit();

                                      if (context.mounted) {
                                        Navigator.of(dialogCtx).pop(true);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Cita creada ✅ (bloque reservado)')),
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
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );

  tituloCtrl.dispose();
  lugarCtrl.dispose();
}
