// lib/screens/appointment_home.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'LoginPage.dart';
import 'package:app/routes.dart';
import 'package:app/screens/messages.dart';
import 'Settings.dart';
import 'package:app/screens/MYAPPOINTMENTS.DART'; // MyAppointmentsPage
import 'create_appointment_dialog.dart';
import 'package:app/medic/Dashboard.dart';

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
  int _navIndex = 0; // 0=Inicio, 1=Mensajes, 2=?, 3=?

  // paleta verdosa
  static const Color kBgMint = Color(0xFFE8F5E9);
  static const Color kCardMintStart = Color(0xFFB2DFDB);
  static const Color kCardMintEnd = Color(0xFFE0F2F1);
  static const Color kButtonTeal = Color(0xFF0F766E);
  static const Color kButtonTealLight = Color(0xFF14B8A6);
  static const Color kSpecialistStart = Color(0xFFE0F2F1);
  static const Color kSpecialistEnd = Color(0xFFC8E6C9);

  // rol actual del usuario
  String? _role; // 'Paciente' o 'Medico'
  bool _loadingRole = true;

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
                colors: [kSpecialistStart, kSpecialistEnd],
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

  Future<void> _logoutToLogin(BuildContext ctx) async {
    await FirebaseAuth.instance.signOut();
    if (ctx.mounted) {
      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Seguro que deseas cerrar tu sesión en DoctorAppointmentApp?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _logoutToLogin(context);
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _role = 'Paciente';
        _loadingRole = false;
      });
      return;
    }

    String? role;

    try {
      // Primero intentamos en "usuarios"
      final docUsuarios =
          await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (docUsuarios.exists) {
        final data = docUsuarios.data();
        role = (data?['role'] ?? data?['rol'])?.toString();
      }

      // Si no encontramos ahí, probamos en "users"
      if (role == null || role.isEmpty) {
        final docUsers =
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (docUsers.exists) {
          final data = docUsers.data();
          role = (data?['role'] ?? data?['rol'])?.toString();
        }
      }
    } catch (_) {
      // si hay error, lo tratamos como Paciente para no tronar
    }

    setState(() {
      _role = role?.isNotEmpty == true ? role : 'Paciente';
      _loadingRole = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Usuario';

    if (_loadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isMedico =
        _role == 'Medico' || _role == 'Médico'; // soporta ambas tildes/variantes

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
                  colors: [kCardMintStart, kCardMintEnd],
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
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 28, color: kButtonTeal),
                  ),
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF064E3B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '¿En qué podemos ayudarte hoy?',
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                            ),
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

        // ===== BOTONES ACCIÓN SEGÚN ROL =====
        if (!isMedico) ...[
          // 🟣 PACIENTE: Crear cita + Mis citas
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showCreateAppointmentDialog(context),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text(
                    'Crear cita',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonTealLight ,
                    foregroundColor: Colors.white,
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
                  onPressed: () => setState(() => _navIndex = 2), // tab 2 -> Mis citas
                  icon: const Icon(Icons.calendar_month),
                  label: const Text(
                    'Mis citas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonTealLight,
                    foregroundColor: Colors.white,
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
        ] else ...[
          // 🩺 MÉDICO: solo botón centrado "Mis citas" → Dashboard (tab 2)
          Center(
            child: SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _navIndex = 2), // tab 2 -> Dashboard
                icon: const Icon(Icons.calendar_month),
                label: const Text(
                  'Mis citas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kButtonTeal,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: 10),

        // "Consejos de salud" (para ambos roles)
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: 220,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.consejos),
              icon: const Icon(Icons.lightbulb_outline, size: 20),
              label: const Text(
                'Consejos de salud',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonTealLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // ===== ESPECIALISTAS Y ATAJOS: SOLO PACIENTES =====
        if (!isMedico) ...[
          const SizedBox(height: 30),
          const Text('Especialistas y atajos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ScrollConfiguration(
            behavior: _MyScrollBehavior(),
            child: SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  // 🔹 MÉDICOS QUE VENGAN DE FIRESTORE (rol = "Medico")
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('usuarios')
                        .where('rol', isEqualTo: 'Medico')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const SizedBox.shrink();

                      return Row(
                        children: docs.map((d) {
                          final data = d.data() as Map<String, dynamic>;
                          final nombre = (data['nombre'] ?? 'Médico').toString();
                          return _buildEspecialistaCard(
                            nombre,
                            'Médico',
                            Icons.person_outline,
                            () {
                              showCreateAppointmentDialog(
                                context,
                                motivoSugerido: 'Consulta con $nombre',
                                medicoIdSugerido: d.id,
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),

                  // ——— Especialistas "de demo" que ya tenías ———
                  _buildEspecialistaCard('Dr. López', 'Cardiólogo', Icons.favorite, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Chequeo cardiológico',
                      medicoIdSugerido: 'dr_lopez',
                    );
                  }),
                  _buildEspecialistaCard('Dra. Martínez', 'Pediatra', Icons.child_care, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Revisión pediátrica',
                      medicoIdSugerido: 'dra_martinez',
                    );
                  }),
                  _buildEspecialistaCard('Dr. Ramírez', 'Dentista', Icons.medical_services, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Dolor de muela',
                      medicoIdSugerido: 'dr_ramirez',
                    );
                  }),
                  _buildEspecialistaCard('Dra. Gómez', 'Dermatóloga', Icons.face, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Acné / erupciones',
                      medicoIdSugerido: 'dra_gomez',
                    );
                  }),
                  _buildEspecialistaCard('Dr. Pérez', 'Nutriólogo', Icons.local_dining, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Plan de nutrición / control de peso',
                      medicoIdSugerido: 'dr_perez',
                    );
                  }),
                  _buildEspecialistaCard('Dra. Ruiz', 'Oftalmóloga', Icons.visibility, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Revisión de la vista',
                      medicoIdSugerido: 'dra_ruiz',
                    );
                  }),
                  _buildEspecialistaCard('Dr. Castro', 'Neurólogo', Icons.psychology, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Migrañas / dolores de cabeza',
                      medicoIdSugerido: 'dr_castro',
                    );
                  }),

                  // ——— Síntomas comunes ———
                  _buildEspecialistaCard(
                      'Gripe / Resfriado', 'Consulta general', Icons.local_hospital, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Síntomas de gripe o resfriado',
                    );
                  }),
                  _buildEspecialistaCard('Fiebre', 'Evaluación', Icons.thermostat, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Fiebre persistente',
                    );
                  }),
                  _buildEspecialistaCard(
                      'Dolor de garganta', 'Otorrino/GP', Icons.healing, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Dolor de garganta',
                    );
                  }),
                  _buildEspecialistaCard('Alergias', 'Tratamiento', Icons.spa, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Alergias estacionales',
                    );
                  }),
                  _buildEspecialistaCard(
                      'Dolor de estómago', 'Gastro', Icons.restaurant, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Dolor de estómago / náuseas',
                    );
                  }),
                  _buildEspecialistaCard(
                      'Diarrea/Vómito', 'Gastro', Icons.warning_amber, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Diarrea o vómito agudo',
                    );
                  }),
                  _buildEspecialistaCard(
                      'Dolor de espalda', 'Fisio/Ortopedia', Icons.fitness_center, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Dolor de espalda baja',
                    );
                  }),
                  _buildEspecialistaCard(
                      'Ansiedad / Estrés', 'Salud mental', Icons.psychology_alt, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Ansiedad / manejo del estrés',
                    );
                  }),
                  _buildEspecialistaCard('Hipertensión', 'Control', Icons.monitor_heart, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Control de presión arterial',
                      medicoIdSugerido: 'dr_lopez',
                    );
                  }),
                  _buildEspecialistaCard('Diabetes', 'Seguimiento', Icons.medication, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Control de diabetes',
                    );
                  }),
                  _buildEspecialistaCard(
                      'Infección urinaria', 'Urología', Icons.water_drop, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Síntomas de infección urinaria',
                    );
                  }),
                  _buildEspecialistaCard(
                      'Salud femenina', 'Gineco', Icons.pregnant_woman, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Consulta ginecológica',
                    );
                  }),
                  _buildEspecialistaCard(
                      'Salud infantil', 'Pediatría', Icons.child_care, () {
                    showCreateAppointmentDialog(
                      context,
                      motivoSugerido: 'Síntomas comunes del niño',
                      medicoIdSugerido: 'dra_martinez',
                    );
                  }),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),
        const Text('Próximas citas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        if (user == null)
          const Text('Por favor Inicia sesión para ver tus citas.')
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
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Text('No tienes citas próximas.');

              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final titulo =
                      (data['titulo']?.toString() ?? data['motivo']?.toString() ?? 'Cita médica');
                  final lugar = data['lugar']?.toString() ?? '—';
                  final ts = data['cuando'] as Timestamp?;
                  final dt = ts?.toDate();
                  final fecha = dt == null ? '—' : DateFormat('dd/MM/yyyy').format(dt);
                  final hora = dt == null ? '—' : DateFormat('hh:mm a').format(dt);

                  return Card(
                    color: const Color(0xFFF1FAF5),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: const Icon(Icons.medical_services_outlined,
                          color: kButtonTeal),
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

        const SizedBox(height: 8),

        // botón pequeño que abre pop-up de cierre de sesión
        Center(
          child: TextButton.icon(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );

    // ===== Cuerpos de otras pestañas =====
    final messagesBody = const MessagesPage();
    final scheduleBody = const MyAppointmentsPage();
    final settingsBody = const SettingsPage();
    final dashboardBody = const DashboardPage();

    // páginas según rol
    final List<Widget> pagesPaciente = [
      homeBody,       // 0
      messagesBody,   // 1
      scheduleBody,   // 2 -> Mis citas
      settingsBody,   // 3
    ];

    final List<Widget> pagesMedico = [
      homeBody,       // 0
      messagesBody,   // 1
      dashboardBody,  // 2 -> Dashboard
      settingsBody,   // 3
    ];

    final pages = isMedico ? pagesMedico : pagesPaciente;

    int currentIndex = _navIndex;
    if (currentIndex >= pages.length) {
      currentIndex = 0;
    }

    final currentBody = pages[currentIndex];

    // AppBar visible / no visible
    final bool hideAppBar = isMedico
        ? (currentIndex == 3) // Médico: solo Ajustes sin AppBar
        : (currentIndex == 2 || currentIndex == 3); // Paciente: Mis citas y Ajustes

    return Scaffold(
      backgroundColor: kBgMint,
      appBar: hideAppBar
          ? null
          : AppBar(
              title: const Text('Citas Médicas'),
              backgroundColor: kButtonTeal,
            ),
      body: currentBody,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => _navIndex = i),

        backgroundColor: const Color.fromARGB(255, 10, 111, 114),
        elevation: 8,
        selectedItemColor: const Color.fromARGB(255, 67, 175, 166),
        unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),

        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),

        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,

        items: isMedico
            ? const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Inicio'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_outline),
                    activeIcon: Icon(Icons.chat_bubble),
                    label: 'Mensajes'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_customize_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'Dashboard'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    activeIcon: Icon(Icons.settings),
                    label: 'Ajustes'),
              ]
            : const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Inicio'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_outline),
                    activeIcon: Icon(Icons.chat_bubble),
                    label: 'Mensajes'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month_outlined),
                    activeIcon: Icon(Icons.calendar_month),
                    label: 'Mis citas'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    activeIcon: Icon(Icons.settings),
                    label: 'Ajustes'),
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
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
