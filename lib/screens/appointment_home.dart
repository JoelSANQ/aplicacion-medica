// lib/screens/appointment_home.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'LoginPage.dart';
import 'package:app/routes.dart'; // si no usas rutas, puedes quitar este import
import 'package:app/screens/messages.dart';
import 'Settings.dart';
import 'package:app/screens/APPOINTMENTS.DART'; // MyAppointmentsPage

class _MyScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class AppointmentHomePage extends StatefulWidget {
  const AppointmentHomePage({super.key});

  @override
  State<AppointmentHomePage> createState() => _AppointmentHomePageState();
}

class _AppointmentHomePageState extends State<AppointmentHomePage> {
  int _navIndex = 0; // 0=Inicio, 1=Mensajes, 2=Calendario, 3=Ajustes

  // ===== UI helper: tarjeta de especialista/atajo =====
  Widget _buildEspecialistaCard(
    String nombre,
    String especialidad,
    IconData icono,
    VoidCallback onTap,
  ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE3F2FD), Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 34, color: Colors.teal[700]),
                const SizedBox(height: 8),
                Text(
                  nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  especialidad,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== utilidades fecha =====
  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  String _dispDocId(String medicoId, DateTime inicio) {
    final f = DateFormat('yyyyMMdd_HHmm').format(inicio);
    return '${medicoId}_$f';
  }

  // ===== Crear cita y crear instancia en disponibilidad_medicos (solo horaInicio) =====
  Future<void> _openCreateAppointment({
    String? motivoSugerido,
    String? lugarSugerido,
    String? medicoIdSugerido,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesión para crear una cita.')),
        );
      }
      return;
    }

    final tituloCtrl = TextEditingController(text: motivoSugerido ?? '');
    final lugarCtrl = TextEditingController(text: lugarSugerido ?? '');

    DateTime? fecha;      // solo fecha (sin hora)
    TimeOfDay? hora;      // solo hora
    String? selMedicoId = medicoIdSugerido;

    // Catálogo simple (puedes sustituir por tu colección /medicos)
    const medicos = <Map<String, String>>[
      {'id': 'dr_lopez', 'nombre': 'Dr. López'},        // Cardiólogo
      {'id': 'dra_martinez', 'nombre': 'Dra. Martínez'},// Pediatra
      {'id': 'dr_ramirez', 'nombre': 'Dr. Ramírez'},    // Dentista
      {'id': 'dra_gomez', 'nombre': 'Dra. Gómez'},      // Dermatóloga
      {'id': 'dr_perez', 'nombre': 'Dr. Pérez'},        // Nutriólogo
      {'id': 'dra_ruiz', 'nombre': 'Dra. Ruiz'},        // Oftalmóloga
      {'id': 'dr_castro', 'nombre': 'Dr. Castro'},      // Neurólogo
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (innerCtx, setSheet) {
              final fechaTxt = (fecha == null)
                  ? 'Elegir fecha'
                  : DateFormat('dd/MM/yyyy').format(fecha!);
              final horaTxt = (hora == null)
                  ? 'Elegir hora'
                  : '${hora!.hour.toString().padLeft(2, '0')}:${hora!.minute.toString().padLeft(2, '0')}';

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Crear cita',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

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
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Guardar cita'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7E57C2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final motivo = tituloCtrl.text.trim();
                          final lugar = lugarCtrl.text.trim();

                          if (motivo.isEmpty ||
                              lugar.isEmpty ||
                              selMedicoId == null ||
                              fecha == null ||
                              hora == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Completa motivo, lugar, médico, fecha y hora.'),
                                ),
                              );
                            }
                            return;
                          }

                          // Combinar fecha + hora en un DateTime inicio + fin (30min para tu UI)
                          final DateTime inicio = DateTime(
                            fecha!.year,
                            fecha!.month,
                            fecha!.day,
                            hora!.hour,
                            hora!.minute,
                          );
                          final DateTime fin = inicio.add(const Duration(minutes: 30));
                          final DateTime soloDia = DateTime(inicio.year, inicio.month, inicio.day);

                          final String dispId = _dispDocId(selMedicoId!, inicio);
                          final dispRef = FirebaseFirestore.instance
                              .collection('disponibilidad_medicos')
                              .doc(dispId);

                          try {
                            // ====== Validar disponibilidad existente (mismo médico+día+hora) ======
                            final existing = await dispRef.get();
                            if (existing.exists) {
                              final data = existing.data() as Map<String, dynamic>;
                              final ocupado = (data['esta_disponible'] ?? false) == false;
                              if (ocupado) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ese horario ya está ocupado. Elige otra hora.'),
                                    ),
                                  );
                                }
                                return;
                              }
                            }

                            // ====== 1) Crear/actualizar bloque en disponibilidad_medicos (SOLO horaInicio) ======
                            await dispRef.set({
                              'medicoId': selMedicoId,
                              'fecha': Timestamp.fromDate(soloDia),
                              'horaInicio': Timestamp.fromDate(inicio),
                              'esta_disponible': false, // se reserva con esta cita
                            }, SetOptions(merge: true));

                            // ====== 2) Guardar la cita del usuario ======
                            await FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(uid)
                                .collection('citas')
                                .add({
                              'pacienteId': uid,
                              'medicoId': selMedicoId,
                              'motivo': motivo,
                              'titulo': motivo, // compat con UI
                              'lugar': lugar,
                              'cuando': Timestamp.fromDate(inicio),
                              'cuandoFin': Timestamp.fromDate(fin), // opcional para tu UI
                              'creadoEn': FieldValue.serverTimestamp(),
                            });

                            // (Opcional) ====== 3) Guardar en "citas" global ======
                            await FirebaseFirestore.instance.collection('citas').add({
                              'pacienteId': uid,
                              'medicoId': selMedicoId,
                              'motivo': motivo,
                              'lugar': lugar,
                              'cuando': Timestamp.fromDate(inicio),
                              'cuandoFin': Timestamp.fromDate(fin),
                              'creadoEn': FieldValue.serverTimestamp(),
                            });

                            if (!innerCtx.mounted) return;
                            Navigator.pop(innerCtx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cita creada ✅ (bloque reservado)')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
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

  Future<void> _logoutToLogin(BuildContext ctx) async {
    await FirebaseAuth.instance.signOut();
    if (ctx.mounted) {
      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Usuario';

    // ======= CONTENIDO HOME (pestaña 0) =======
    final homeBody = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // BIENVENIDA (tap a Perfil)
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color.fromARGB(255, 219, 248, 248)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: (user == null)
                          ? const Stream.empty()
                          : FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(user.uid)
                              .snapshots(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data() as Map<String, dynamic>?;
                        final nombre = (data?['nombre'] ?? '').toString().trim();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenido ${nombre.isNotEmpty ? nombre : ''}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            const Text('¿En qué podemos ayudarte hoy?',
                                style: TextStyle(fontSize: 14, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // BOTONES ACCIÓN
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openCreateAppointment,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Crear cita',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  elevation: 6,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                // Para evitar depender de rutas, cambiamos de pestaña al Calendario
                onPressed: () => setState(() => _navIndex = 2),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Mis citas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  elevation: 6,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      
        const SizedBox(height: 10),

        // ⚠️ No se toca el botón "Consejos de salud"
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: 220,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.consejos),
              icon: const Icon(Icons.lightbulb_outline, size: 20),
              label: const Text('Consejos de salud',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),
        const Text('Especialistas y atajos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Carrusel Especialistas + Síntomas
        ScrollConfiguration(
          behavior: _MyScrollBehavior(),
          child: SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                // ——— Especialistas ———
                _buildEspecialistaCard('Dr. López', 'Cardiólogo', Icons.favorite, () {
                  _openCreateAppointment(motivoSugerido: 'Chequeo cardiológico', medicoIdSugerido: 'dr_lopez');
                }),
                _buildEspecialistaCard('Dra. Martínez', 'Pediatra', Icons.child_care, () {
                  _openCreateAppointment(motivoSugerido: 'Revisión pediátrica', medicoIdSugerido: 'dra_martinez');
                }),
                _buildEspecialistaCard('Dr. Ramírez', 'Dentista', Icons.medical_services, () {
                  _openCreateAppointment(motivoSugerido: 'Dolor de muela', medicoIdSugerido: 'dr_ramirez');
                }),
                _buildEspecialistaCard('Dra. Gómez', 'Dermatóloga', Icons.face, () {
                  _openCreateAppointment(motivoSugerido: 'Acné / erupciones', medicoIdSugerido: 'dra_gomez');
                }),
                _buildEspecialistaCard('Dr. Pérez', 'Nutriólogo', Icons.local_dining, () {
                  _openCreateAppointment(motivoSugerido: 'Plan de nutrición / control de peso', medicoIdSugerido: 'dr_perez');
                }),
                _buildEspecialistaCard('Dra. Ruiz', 'Oftalmóloga', Icons.visibility, () {
                  _openCreateAppointment(motivoSugerido: 'Revisión de la vista', medicoIdSugerido: 'dra_ruiz');
                }),
                _buildEspecialistaCard('Dr. Castro', 'Neurólogo', Icons.psychology, () {
                  _openCreateAppointment(motivoSugerido: 'Migrañas / dolores de cabeza', medicoIdSugerido: 'dr_castro');
                }),

                // ——— Síntomas / Enfermedades comunes ———
                _buildEspecialistaCard('Gripe / Resfriado', 'Consulta general', Icons.local_hospital, () {
                  _openCreateAppointment(motivoSugerido: 'Síntomas de gripe o resfriado');
                }),
                _buildEspecialistaCard('Fiebre', 'Evaluación', Icons.thermostat, () {
                  _openCreateAppointment(motivoSugerido: 'Fiebre persistente');
                }),
                _buildEspecialistaCard('Dolor de garganta', 'Otorrino/GP', Icons.healing, () {
                  _openCreateAppointment(motivoSugerido: 'Dolor de garganta');
                }),
                _buildEspecialistaCard('Alergias', 'Tratamiento', Icons.spa, () {
                  _openCreateAppointment(motivoSugerido: 'Alergias estacionales');
                }),
                _buildEspecialistaCard('Dolor de estómago', 'Gastro', Icons.restaurant, () {
                  _openCreateAppointment(motivoSugerido: 'Dolor de estómago / náuseas');
                }),
                _buildEspecialistaCard('Diarrea/Vómito', 'Gastro', Icons.warning_amber, () {
                  _openCreateAppointment(motivoSugerido: 'Diarrea o vómito agudo');
                }),
                _buildEspecialistaCard('Dolor de espalda', 'Fisio/Ortopedia', Icons.fitness_center, () {
                  _openCreateAppointment(motivoSugerido: 'Dolor de espalda baja');
                }),
                _buildEspecialistaCard('Ansiedad / Estrés', 'Salud mental', Icons.psychology_alt, () {
                  _openCreateAppointment(motivoSugerido: 'Ansiedad / manejo del estrés');
                }),
                _buildEspecialistaCard('Hipertensión', 'Control', Icons.monitor_heart, () {
                  _openCreateAppointment(motivoSugerido: 'Control de presión arterial', medicoIdSugerido: 'dr_lopez');
                }),
                _buildEspecialistaCard('Diabetes', 'Seguimiento', Icons.medication, () {
                  _openCreateAppointment(motivoSugerido: 'Control de diabetes');
                }),
                _buildEspecialistaCard('Infección urinaria', 'Urología', Icons.water_drop, () {
                  _openCreateAppointment(motivoSugerido: 'Síntomas de infección urinaria');
                }),
                _buildEspecialistaCard('Salud femenina', 'Gineco', Icons.pregnant_woman, () {
                  _openCreateAppointment(motivoSugerido: 'Consulta ginecológica');
                }),
                _buildEspecialistaCard('Salud infantil', 'Pediatría', Icons.child_care, () {
                  _openCreateAppointment(motivoSugerido: 'Síntomas comunes del niño', medicoIdSugerido: 'dra_martinez');
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        const Text('Próximas citas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if (user == null)
          const Text('Inicia sesión para ver tus citas.')
        else
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .collection('citas')
                .orderBy('cuando')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Text('No tienes citas próximas.');

              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final titulo = (data['titulo']?.toString() ?? data['motivo']?.toString() ?? 'Cita médica');
                  final lugar = data['lugar']?.toString() ?? '—';
                  final ts = data['cuando'] as Timestamp?;
                  final dt = ts?.toDate();
                  final fecha = dt == null ? '—' : DateFormat('dd/MM/yyyy').format(dt);
                  final hora = dt == null ? '—' : DateFormat('hh:mm a').format(dt);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: const Icon(Icons.medical_services_outlined),
                      title: Text(titulo),
                      subtitle: Text('$fecha  •  $hora  •  $lugar'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {},
                    ),
                  );
                }).toList(),
              );
            },
          ),

        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _logoutToLogin(context),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );

    // Cuerpos de otras pestañas
    final messagesBody = const MessagesPage();
    final scheduleBody = const MyAppointmentsPage(); // lista/eliminar con rango
    final settingsBody = const SettingsPage();

    Widget currentBody;
    switch (_navIndex) {
      case 1:
        currentBody = messagesBody;
        break;
      case 2:
        currentBody = scheduleBody;
        break;
      case 3:
        currentBody = settingsBody;
        break;
      default:
        currentBody = homeBody;
    }

    // Evitar doble AppBar en pestaña Calendario (index 2) y Ajustes (index 3 si quieres)
    return Scaffold(
      appBar: (_navIndex == 2 || _navIndex == 3) ? null : AppBar(title: const Text('Citas Médicas')),
      body: currentBody,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedItemColor: const Color(0xFF7E57C2),
        unselectedItemColor: Colors.black45,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendario'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.black45),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
