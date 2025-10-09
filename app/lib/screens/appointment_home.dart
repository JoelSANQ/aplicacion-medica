import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 👇 Importa LoginPage desde main.dart para poder navegar de vuelta al login
import '../main.dart';

class AppointmentHomePage extends StatelessWidget {
  const AppointmentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Usuario';

    final citas = [
      {'titulo': 'Consulta general', 'fecha': '12/10/2025', 'hora': '10:30 AM', 'lugar': 'Clínica Azul'},
      {'titulo': 'Odontología', 'fecha': '18/10/2025', 'hora': '01:00 PM', 'lugar': 'Dental Smile'},
      {'titulo': 'Nutrición', 'fecha': '25/10/2025', 'hora': '09:15 AM', 'lugar': 'Centro Vital'},
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment App'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _logoutToLogin(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
                      const Text('Bienvenido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(email, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => noImpl('Crear cita'),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Crear cita'),
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
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => noImpl('Configuración'),
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Configuración'),
          ),
          const SizedBox(height: 20),

          const Text('Próximas citas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ...citas.map((c) => Card(
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
              )),
          const SizedBox(height: 24),

          // Botón extra de cerrar sesión (mismo comportamiento)
          OutlinedButton.icon(
            onPressed: () => _logoutToLogin(context),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
