// lib/screens/Medics_available.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DoctorAvailabilitySection extends StatefulWidget {
  const DoctorAvailabilitySection({super.key});

  @override
  State<DoctorAvailabilitySection> createState() => _DoctorAvailabilitySectionState();
}

class _DoctorAvailabilitySectionState extends State<DoctorAvailabilitySection> {
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
  String? _resultadoDia;

  String _fmtFecha(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _fmtHora(DateTime d) => DateFormat('HH:mm').format(d);
  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  final int _inicioJornada = 8;  // 08:00
  final int _finJornada = 20;    // 20:00 (exclusivo)
  List<DateTime> _generarBloquesDeHora(DateTime day) =>
      [for (var h = _inicioJornada; h < _finJornada; h++) DateTime(day.year, day.month, day.day, h)];

  Future<void> _checarDia() async {
    if (_medicoSeleccionado == null || _diaSeleccionado == null) {
      setState(() => _resultadoDia = 'Selecciona médico y fecha.');
      return;
    }
    final fechaSolo = _onlyDate(_diaSeleccionado!);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('disponibilidad_medicos')
          .where('medicoId', isEqualTo: _medicoSeleccionado)
          .where('fecha', isEqualTo: Timestamp.fromDate(fechaSolo))
          .get();

      if (snap.docs.isEmpty) {
        setState(() => _resultadoDia =
            'Sin registros para ${_fmtFecha(fechaSolo)}. Se mostrarán bloques de ${_inicioJornada}:00 a ${_finJornada}:00 como disponibles.');
        return;
      }

      final anyDisponible = snap.docs.any((d) {
        final m = d.data() as Map<String, dynamic>;
        return (m['esta_disponible'] ?? true) == true;
      });

      setState(() => _resultadoDia =
          anyDisponible ? 'Hay disponibilidad ese día.' : 'Día ocupado (todos los bloques tomados).');
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    _diaSeleccionado == null ? 'Elegir día' : _fmtFecha(_diaSeleccionado!),
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
            child: Text(_resultadoDia!, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),

        const SizedBox(height: 10),

        // Bloques 1h (disponibles/ocupados)
        if (!(_medicoSeleccionado != null && _diaSeleccionado != null))
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Selecciona médico y día para ver la disponibilidad.'),
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

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: todosLosBloques.map((s) {
                        final disponible = estadoPorInicio[s] ?? true;
                        final etiqueta =
                            '${_fmtHora(s)} - ${_fmtHora(s.add(const Duration(hours: 1)))}';
                        return FilterChip(
                          label: Text(etiqueta),
                          avatar: Icon(
                            disponible ? Icons.check_circle : Icons.lock_clock,
                            color: disponible ? Colors.green : Colors.red,
                          ),
                          selected: false,
                          backgroundColor:
                              disponible ? Colors.green.shade50 : Colors.red.shade50,
                          onSelected: (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  disponible
                                      ? 'Bloque disponible: $etiqueta'
                                      : 'Bloque reservado: $etiqueta',
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 6),
                        Text('Disponible'),
                        SizedBox(width: 16),
                        Icon(Icons.lock_clock, size: 16, color: Colors.red),
                        SizedBox(width: 6),
                        Text('Ocupado'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
