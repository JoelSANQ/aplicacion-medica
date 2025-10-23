import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
String _dispDocId(String medicoId, DateTime inicio) {
  final f = DateFormat('yyyyMMdd_HHmm').format(inicio);
  return '${medicoId}_$f';
}

/// Abre un **Dialog centrado** con el formulario de crear cita.
/// Misma lógica que tenías, solo cambia el contenedor visual.
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
  final lugarCtrl = TextEditingController(text: lugarSugerido ?? '');
  DateTime? fecha;      // solo fecha
  TimeOfDay? hora;      // solo hora
  String? selMedicoId = medicoIdSugerido;

  // Catálogo idéntico
  const medicos = <Map<String, String>>[
    {'id': 'dr_lopez', 'nombre': 'Dr. López'},
    {'id': 'dra_martinez', 'nombre': 'Dra. Martínez'},
    {'id': 'dr_ramirez', 'nombre': 'Dr. Ramírez'},
    {'id': 'dra_gomez', 'nombre': 'Dra. Gómez'},
    {'id': 'dr_perez',  'nombre': 'Dr. Pérez'},
    {'id': 'dra_ruiz',  'nombre': 'Dra. Ruiz'},
    {'id': 'dr_castro', 'nombre': 'Dr. Castro'},
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
            // Ancho máximo amigable para web/escritorio; en móvil ocupa casi todo
            final maxW = constraints.maxWidth.clamp(0, 560.0);
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxW is double ? maxW : 560,
                // altura tope para evitar overflow y permitir scroll
                maxHeight: 640,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: StatefulBuilder(
                    builder: (innerCtx, setSheet) {
                      final fechaTxt = (fecha == null)
                          ? 'Elegir fecha'
                          : DateFormat('dd/MM/yyyy').format(fecha!);
                      final horaTxt = (hora == null)
                          ? 'Elegir hora'
                          : '${hora!.hour.toString().padLeft(2, '0')}:${hora!.minute.toString().padLeft(2, '0')}';

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Cabecera
                          Container(
                            height: 4,
                            width: 48,
                            margin: const EdgeInsets.only(bottom: 12, top: 4),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Crear cita',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),

                          // Form
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  TextField(
                                    controller: tituloCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Motivo / Título (ej. Consulta general)',
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
                                    onChanged: (v) => setSheet(() => selMedicoId = v),
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
                                              firstDate: now,
                                              lastDate: now.add(const Duration(days: 365 * 2)),
                                            );
                                            if (picked != null) {
                                              setSheet(() => fecha = _day(picked));
                                            }
                                          },
                                          icon: const Icon(Icons.calendar_today),
                                          label: Text(fechaTxt),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            final picked = await showTimePicker(
                                              context: innerCtx,
                                              initialTime: TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              setSheet(() => hora = picked);
                                            }
                                          },
                                          icon: const Icon(Icons.access_time),
                                          label: Text(horaTxt),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          // Botones
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
                                    final lugar = lugarCtrl.text.trim();

                                    if (motivo.isEmpty ||
                                        lugar.isEmpty ||
                                        selMedicoId == null ||
                                        fecha == null ||
                                        hora == null) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Completa motivo, lugar, médico, fecha y hora.'),
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    final DateTime inicio = DateTime(
                                      fecha!.year, fecha!.month, fecha!.day, hora!.hour, hora!.minute,
                                    );
                                    final DateTime fin = inicio.add(const Duration(minutes: 30));
                                    final DateTime soloDia = DateTime(inicio.year, inicio.month, inicio.day);

                                    final String dispId = _dispDocId(selMedicoId!, inicio);
                                    final dispRef = FirebaseFirestore.instance
                                        .collection('disponibilidad_medicos')
                                        .doc(dispId);

                                    try {
                                      final existing = await dispRef.get();
                                      if (existing.exists) {
                                        final data = existing.data() as Map<String, dynamic>;
                                        final ocupado = (data['esta_disponible'] ?? false) == false;
                                        if (ocupado) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Ese horario ya está ocupado. Elige otra hora.'),
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                      }

                                      await dispRef.set({
                                        'medicoId': selMedicoId,
                                        'fecha': Timestamp.fromDate(soloDia),
                                        'horaInicio': Timestamp.fromDate(inicio),
                                        'esta_disponible': false,
                                      }, SetOptions(merge: true));

                                      await FirebaseFirestore.instance
                                          .collection('usuarios')
                                          .doc(uid)
                                          .collection('citas')
                                          .add({
                                        'pacienteId': uid,
                                        'medicoId': selMedicoId,
                                        'motivo': motivo,
                                        'titulo': motivo,
                                        'lugar': lugar,
                                        'cuando': Timestamp.fromDate(inicio),
                                        'cuandoFin': Timestamp.fromDate(fin),
                                        'creadoEn': FieldValue.serverTimestamp(),
                                      });

                                      await FirebaseFirestore.instance.collection('citas').add({
                                        'pacienteId': uid,
                                        'medicoId': selMedicoId,
                                        'motivo': motivo,
                                        'lugar': lugar,
                                        'cuando': Timestamp.fromDate(inicio),
                                        'cuandoFin': Timestamp.fromDate(fin),
                                        'creadoEn': FieldValue.serverTimestamp(),
                                      });

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
