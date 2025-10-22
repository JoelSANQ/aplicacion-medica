import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/routes.dart';
import 'ProfilePage.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Colores principales
  static const Color kPrimary = Color(0xFF00BCD4);
  static const Color kLight = Color(0xFFE0F7FA);
  static const Color kTextDark = Color(0xFF0D2A2E);

  void _goProfile(BuildContext context) {
    try {
      Navigator.pushNamed(context, AppRoutes.profile);
    } catch (_) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    }
  }

  void _openInfo(BuildContext context, String title, String description) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _InfoPage(title: title, description: description)),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    try {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
    } catch (_) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Usuario';

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFE6FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: kLight,
                  child: Icon(Icons.person, color: kPrimary, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usuario',
                        style: TextStyle(
                          color: kTextDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text('Perfil', style: TextStyle(color: Colors.black45)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Opciones
          _SettingsItem(
            icon: Icons.person_outline,
            title: 'Perfil',
            onTap: () => _goProfile(context),
          ),
          _DividerCard(),

          _SettingsItem(
            icon: Icons.notifications_none,
            title: 'Notificaciones',
            onTap: () => _openInfo(
              context,
              'Notificaciones',
              'Las notificaciones te mantendrán informado sobre tus citas próximas, '
              'recordatorios de salud y consejos médicos relevantes.',
            ),
          ),
          _DividerCard(),

          _SettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacidad',
            onTap: () => _openInfo(
              context,
              'Privacidad',
              'Tu información personal se maneja con total confidencialidad. '
              'Nunca será compartida sin tu consentimiento.',
            ),
          ),
          _DividerCard(),

          _SettingsItem(
            icon: Icons.info_outline,
            title: 'Acerca De Nosotros',
            onTap: () => _openInfo(
              context,
              'Acerca De Nosotros',
              'DoctorAppointmentApp es una aplicación diseñada para mejorar la experiencia de los pacientes '
              'al gestionar sus citas médicas y su información personal.',
            ),
          ),

          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFFFEBEE),
                child: Icon(Icons.logout, color: Colors.red.shade400),
              ),
              title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: SettingsPage.kLight,
          child: Icon(icon, color: SettingsPage.kPrimary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _DividerCard extends StatelessWidget {
  const _DividerCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Divider(height: 0),
    );
  }
}

class _InfoPage extends StatelessWidget {
  final String title;
  final String description;

  const _InfoPage({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsPage.kLight,
      appBar: AppBar(
        backgroundColor: SettingsPage.kPrimary,
        foregroundColor: Colors.white,
        title: Text(title),
        elevation: 0,
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Text(
          description,
          style: const TextStyle(fontSize: 15, height: 1.45, color: SettingsPage.kTextDark),
        ),
      ),
    );
  }
}
