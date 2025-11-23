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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    }
  }

  void _openInfo(BuildContext context, String title, String description) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _InfoPage(title: title, description: description),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    try {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (r) => false,
      );
    } catch (_) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Usuario';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFE6FAFC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================
                    //        HEADER
                    // ==========================
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 35,
                          backgroundColor: kLight,
                          child: Icon(
                            Icons.person,
                            color: kPrimary,
                            size: 38,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Usuario',
                                style: TextStyle(
                                  color: kTextDark,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Perfil',
                                style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ==========================
                    //   SECCIÓN DE OPCIONES
                    //   OCUPA TODO EL ESPACIO
                    // ==========================
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AJUSTES DE CUENTA',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _SettingsItem(
                            icon: Icons.person_outline,
                            title: 'Perfil',
                            onTap: () => _goProfile(context),
                          ),
                          const _DividerLine(),

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
                          const _DividerLine(),

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
                          const _DividerLine(),

                          _SettingsItem(
                            icon: Icons.info_outline,
                            title: 'Acerca De Nosotros',
                            onTap: () => _openInfo(
                              context,
                              'Acerca De Nosotros',
                              'DoctorAppointmentApp es una aplicación diseñada para mejorar la experiencia '
                                  'de los pacientes al gestionar sus citas médicas y su información personal.',
                            ),
                          ),

                          const SizedBox(height: 32),

                          const Text(
                            'CUENTA',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _SettingsItem(
                            icon: Icons.logout,
                            title: 'Cerrar sesion',
                            isDestructive: true,
                            onTap: () => _logout(context),
                          ),

                          const SizedBox(height: 16),

                          // Empuja todo hacia arriba y hace que
                          // la sección use TODO el alto disponible.
                          const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconBg =
        isDestructive ? const Color(0xFFFFEBEE) : SettingsPage.kLight;

    final Color iconColor =
        isDestructive ? Colors.red.shade400 : SettingsPage.kPrimary;

    final TextStyle textStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: isDestructive ? Colors.red.shade500 : SettingsPage.kTextDark,
      fontSize: 15,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: iconBg,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: textStyle,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.transparent : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 0,
      thickness: 0.6,
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          description,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: SettingsPage.kTextDark,
          ),
        ),
      ),
    );
  }
}
