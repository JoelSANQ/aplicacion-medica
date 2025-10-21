import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ProfilePage.dart';
import 'LoginPage.dart';
import 'advice.dart';
import 'package:app/routes.dart';
import 'package:app/screens/messages.dart';

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
  int _navIndex = 0; // 0=Home, 1=Messages, 2=Schedule, 3=Settings

  // ===== Helper: Card de especialista (clicable) =====
  Widget _buildEspecialistaCard(
    String nombre,
    String especialidad,
    IconData icono,
    VoidCallback onTap,
  ) {
    return Container(
      width: 140,
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
                Icon(icono, size: 36, color: Colors.teal[700]),
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Usuario';

    final citas = [
      {'titulo': 'Consulta general', 'fecha': '12/10/2025', 'hora': '10:30 AM', 'lugar': 'Clínica Azul'},
    ];

    void noImpl(String name) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name: funcionalidad no implementada')),
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

    // ======= CONTENIDO HOME (pestaña 0) =======
    final homeBody = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // BIENVENIDA (tappable a Perfil)
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
               Navigator.pushNamed(context, AppRoutes.profile);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color.fromARGB(255, 219, 248, 248)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bienvenido',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(email, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => noImpl('Crear cita'),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Crear cita', style: TextStyle(fontWeight: FontWeight.bold), ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => noImpl('Mis citas'),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Mis citas'),
              ),
            ),
          ],
        ),
     const SizedBox(width: 10, height: 12),

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
const Text('Especialistas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
        // Carrusel Especialistas
        ScrollConfiguration(
          behavior: _MyScrollBehavior(),
          child: SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildEspecialistaCard('Dr. López', 'Cardiólogo', Icons.favorite,
                    () => noImpl('Perfil Dr. López')),
                _buildEspecialistaCard('Dra. Martínez', 'Pediatra', Icons.child_care,
                    () => noImpl('Perfil Dra. Martínez')),
                _buildEspecialistaCard('Dr. Ramírez', 'Dentista', Icons.medical_services,
                    () => noImpl('Perfil Dr. Ramírez')),
                _buildEspecialistaCard('Dra. Gómez', 'Dermatóloga', Icons.face,
                    () => noImpl('Perfil Dra. Gómez')),
                _buildEspecialistaCard('Dr. Pérez', 'Nutriólogo', Icons.local_dining,
                    () => noImpl('Perfil Dr. Pérez')),
                _buildEspecialistaCard('Dra. Ruiz', 'Oftalmóloga', Icons.visibility,
                    () => noImpl('Perfil Dra. Ruiz')),
                _buildEspecialistaCard('Dr. Castro', 'Neurólogo', Icons.psychology,
                    () => noImpl('Perfil Dr. Castro')),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        const Text('Próximas citas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        ...citas.map(
          (c) => Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: const Icon(Icons.medical_services_outlined),
              title: Text(c['titulo']!),
              subtitle: Text('${c['fecha']}  •  ${c['hora']}  •  ${c['lugar']}'),
              trailing: IconButton(
                onPressed: () => noImpl('Ver detalle'),
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        OutlinedButton.icon(
          onPressed: () => _logoutToLogin(context),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );

    // Cuerpos simples para otras pestañas (placeholders)
    final messagesBody = const MessagesPage(
    );
    final scheduleBody = _PlaceholderTab(
      icon: Icons.calendar_month,
      title: 'Calendario',
      subtitle: 'Tu calendario y recordatorios de citas.',
    );
    final settingsBody =  const ProfilePage()
    ;

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

return Scaffold(
  appBar: _navIndex == 3 ? null : AppBar(title: const Text('Citas Médicas')),
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
);  }
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
