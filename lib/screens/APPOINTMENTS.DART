// lib/screens/my_appointments.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// ================= MODELOS =================

class Appointment {
  final String id;
  final DateTime dateTime; // inicio
  final DateTime? endTime; // fin (opcional)
  final String pacienteId;
  final String? medicoId;
  final String motivo;
  final String? lugar;
  final DateTime? createdAt;

  Appointment({
    required this.id,
    required this.dateTime,
    required this.pacienteId,
    required this.motivo,
    this.endTime,
    this.medicoId,
    this.lugar,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'cuando': Timestamp.fromDate(dateTime),
      if (endTime != null) 'cuandoFin': Timestamp.fromDate(endTime!),
      'pacienteId': pacienteId,
      'medicoId': medicoId,
      'motivo': motivo,
      'lugar': lugar,
      'creadoEn':
          createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'titulo': motivo,
    };
  }

  factory Appointment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      dateTime: (data['cuando'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['cuandoFin'] as Timestamp?)?.toDate(),
      pacienteId: (data['pacienteId'] ?? '').toString(),
      medicoId: data['medicoId']?.toString(),
      motivo: (data['motivo'] ?? data['titulo'] ?? '').toString(),
      lugar: data['lugar']?.toString(),
      createdAt: (data['creadoEn'] is Timestamp)
          ? (data['creadoEn'] as Timestamp).toDate()
          : null,
    );
  }
}

class DoctorAvailability {
  final String id;
  final String medicoId;
  final DateTime fecha;      // solo y/m/d
  final DateTime horaInicio; // fecha+hora
  final DateTime horaFin;    // fecha+hora
  final bool estaDisponible;

  DoctorAvailability({
    required this.id,
    required this.medicoId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estaDisponible,
  });

  factory DoctorAvailability.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final inicio = (data['horaInicio'] as Timestamp).toDate();
    // Si no existiera 'horaFin' en el doc, usamos +1h por defecto para no romper UI
    final fin = (data['horaFin'] as Timestamp?)?.toDate() ?? inicio.add(const Duration(hours: 1));
    return DoctorAvailability(
      id: doc.id,
      medicoId: (data['medicoId'] ?? '').toString(),
      fecha: (data['fecha'] as Timestamp).toDate(),
      horaInicio: inicio,
      horaFin: fin,
      estaDisponible: (data['esta_disponible'] ?? true) as bool,
    );
  }
}

/// ================ PANTALLA =================

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  DateTime? _startDate;
  DateTime? _endDate;

  // Sección "Disponibilidad": elegir médico y luego día para ver bloques de 1h
  static const _medicos = <Map<String, String>>[
    {'id': 'dr_lopez', 'nombre': 'Dr. López'},
    {'id': 'dra_martinez', 'nombre': 'Dra. Martínez'},
    {'id': 'dr_ramirez', 'nombre': 'Dr. Ramírez'},
    {'id': 'dra_gomez', 'nombre': 'Dra. Gómez'},
    {'id': 'dr_perez', 'nombre': 'Dr. Pérez'},
    {'id': 'dra_ruiz', 'nombre': 'Dra. Ruiz'},
    {'id': 'dr_castro', 'nombre': 'Dr. Castro'},
  ];
  String? _medicoSeleccionado;
  DateTime? _diaSeleccionado;
  String? _resultadoDia; // texto “Disponible / Ocupado / Sin registros”

  String _fmtFecha(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _fmtHora(DateTime d) => DateFormat('HH:mm').format(d);
  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  // --- CONFIGURACIÓN HORARIA PARA BLOQUES DE 1 HORA ---
  final int _inicioJornada = 8;  // 08:00
  final int _finJornada = 20;    // 20:00 (exclusivo)
  // Si no hay documentos de catálogo para ese día, ¿mostramos todos los bloques menos los ocupados explícitos?
  final bool _inferirSiNoHayCatalogo = true;

  // Genera todos los DateTime inicio de cada bloque de 1h.
  List<DateTime> _generarBloquesDeHora(DateTime day) {
    final base = DateTime(day.year, day.month, day.day);
    final slots = <DateTime>[];
    for (var h = _inicioJornada; h < _finJornada; h++) {
      slots.add(base.add(Duration(hours: h)));
    }
    return slots;
  }

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

  Future<void> _deleteWithConfirm(
    BuildContext context, {
    required DocumentReference docRef,
    required String titulo,
    required DateTime? cuando,
  }) async {
    final fechaTxt =
        cuando == null ? '—' : DateFormat('dd/MM/yyyy – hh:mm a').format(cuando);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: Text('¿Estás seguro de eliminar la cita:\n\n“$titulo”\n$fechaTxt ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await docRef.delete();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cita eliminada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
      }
    }
  }

  /// ====== Checar si un día (solo fecha) tiene disponibilidad para un médico ======
  Future<void> _checarDia() async {
    if (_medicoSeleccionado == null || _diaSeleccionado == null) {
      setState(() => _resultadoDia = 'Selecciona médico y fecha.');
      return;
    }
    final fechaSolo = _onlyDate(_diaSeleccionado!);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('disponibilidad_medicos')
          .where('medicoId', isEqualTo: _medicoSeleccionado)   // igualdad
          .where('fecha', isEqualTo: Timestamp.fromDate(fechaSolo)) // igualdad
          .get();

      if (snap.docs.isEmpty) {
        setState(() => _resultadoDia =
            'Sin registros para ${_fmtFecha(fechaSolo)} (se aplicará jornada ${_inicioJornada}:00–${_finJornada}:00).');
        return;
      }

      final anyDisponible = snap.docs.any((d) {
        final m = d.data() as Map<String, dynamic>;
        return (m['esta_disponible'] ?? true) == true;
      });

      setState(() => _resultadoDia =
          anyDisponible ? 'Disponible ese día.' : 'Día ocupado (todos los bloques están tomados).');
    } catch (e) {
      setState(() => _resultadoDia = 'Error al consultar: $e');
    }
  }

  Future<void> _pickDiaDisponibilidad() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _diaSeleccionado ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _diaSeleccionado = picked);
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
          // ===================== FILTRO POR RANGO =====================
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

          // ===================== LISTA DE CITAS =====================
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

                  DateTime? fin;
                  if (data['cuandoFin'] is Timestamp) {
                    fin = (data['cuandoFin'] as Timestamp).toDate();
                  } else if (inicio != null) {
                    fin = inicio.add(const Duration(minutes: 30));
                  }

                  final fecha = inicio == null ? '—' : DateFormat('dd/MM/yyyy').format(inicio);
                  final horaInicio = inicio == null ? '—' : DateFormat('HH:mm').format(inicio);
                  final horaFin = fin == null ? '—' : DateFormat('HH:mm').format(fin);

                  return Dismissible(
                    key: ValueKey(d.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red.withOpacity(0.15),
                      child: const Icon(Icons.delete_outline),
                    ),
                    confirmDismiss: (_) async {
                      await _deleteWithConfirm(
                        context,
                        docRef: d.reference,
                        titulo: titulo,
                        cuando: inicio,
                      );
                      return false;
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.event_available),
                        title: Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('$fecha  •  $horaInicio - $horaFin  •  $lugar'),
                        trailing: IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteWithConfirm(
                            context,
                            docRef: d.reference,
                            titulo: titulo,
                            cuando: inicio,
                          ),
                        ),
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

          // ===================== DISPONIBILIDAD DE MÉDICOS =====================
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Disponibilidad de médicos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // Chips de médicos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _medicos.map((m) {
                final selected = _medicoSeleccionado == m['id'];
                return ChoiceChip(
                  label: Text(m['nombre']!),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _medicoSeleccionado = m['id'];
                    _resultadoDia = null;
                  }),
                );
              }).toList(),
            ),
          ),

          // Selector de día y botón “Checar día”
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDiaDisponibilidad,
                    icon: const Icon(Icons.today_outlined),
                    label: Text(
                      _diaSeleccionado == null
                          ? 'Elegir día'
                          : _fmtFecha(_diaSeleccionado!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _checarDia,
                  child: const Text('Checar día'),
                ),
              ],
            ),
          ),

          if (_resultadoDia != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_resultadoDia!,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),

          const SizedBox(height: 10),

          // ===================== BLOQUES DE 1 HORA POR DÍA (FILTRANDO OCUPADOS) =====================
          if (_medicoSeleccionado == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Selecciona un médico para ver bloques de disponibilidad.'),
            )
          else if (_diaSeleccionado == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Elige un día para ver la disponibilidad.'),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('disponibilidad_medicos')
                  .where('medicoId', isEqualTo: _medicoSeleccionado)
                  .where('fecha', isEqualTo: Timestamp.fromDate(_onlyDate(_diaSeleccionado!)))
                  .snapshots(),
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

                // Mapa inicio->disponible (true/false)
                final Map<DateTime, bool> estadoPorInicio = {};
                for (final d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  final tsInicio = data['horaInicio'] as Timestamp?;
                  if (tsInicio == null) continue;
                  final start = tsInicio.toDate();
                  final disponible = (data['esta_disponible'] ?? true) as bool;
                  estadoPorInicio[start] = disponible;
                }

                final todosLosBloques = _generarBloquesDeHora(_diaSeleccionado!);

                final bool hayCatalogo = docs.isNotEmpty;
                final visibles = <DateTime>[];
                for (final s in todosLosBloques) {
                  final disponibleFlag = estadoPorInicio[s];
                  if (hayCatalogo) {
                    if (disponibleFlag == true) visibles.add(s);
                  } else if (_inferirSiNoHayCatalogo) {
                    // Si no hay docs, mostramos todos salvo los que explícitamente estén false
                    if (disponibleFlag != false) visibles.add(s);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visibles.isEmpty)
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.event_busy),
                            title: Text('Sin bloques disponibles el ${_fmtFecha(_diaSeleccionado!)}'),
                            subtitle: const Text('Intenta con otro día u otro médico.'),
                          ),
                        )
                      else
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Disponibles el ${_fmtFecha(_diaSeleccionado!)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: visibles.map((s) {
                                final etiqueta =
                                    '${_fmtHora(s)} - ${_fmtHora(s.add(const Duration(hours: 1)))}';
                                return FilterChip(
                                  selected: false,
                                  label: Text(etiqueta),
                                  avatar: const Icon(Icons.schedule, size: 18),
                                  onSelected: (_) async {
                                    // Aquí puedes abrir tu diálogo de crear cita con el bloque prefijado.
                                    // Si prefieres reservar directo, escribe en Firestore aquí.
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Bloque seleccionado: $etiqueta')),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                      // (Opcional) Mostrar también los ocupados para referencia
                      if (estadoPorInicio.values.any((v) => v == false))
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ocupados', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: estadoPorInicio.entries
                                    .where((e) => e.value == false)
                                    .map((e) {
                                  final s = e.key;
                                  final etiqueta =
                                      '${_fmtHora(s)} - ${_fmtHora(s.add(const Duration(hours: 1)))}';
                                  return Chip(
                                    label: Text(etiqueta),
                                    avatar: const Icon(Icons.lock_clock, size: 18),
                                    backgroundColor: Colors.grey.shade200,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
