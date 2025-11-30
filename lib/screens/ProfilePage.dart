import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/theme/app_colors.dart';

/// ProfilePage que usa un ÚNICO documento por usuario: usuarios/{uid}
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();
  final TextEditingController enfermedadesCtrl = TextEditingController();
  final TextEditingController rolCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _uid; // uid del usuario autenticado

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final user = _auth.currentUser;
    _uid = user?.uid;

    if (_uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_uid)
          .get();

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        nombreCtrl.text = (data['nombre'] ?? '').toString();
        telefonoCtrl.text = (data['telefono'] ?? '').toString();
        enfermedadesCtrl.text = (data['enfermedades'] ?? '').toString();
        rolCtrl.text = (data['rol'] ?? '').toString();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando perfil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guardar(BuildContext pageContext) async {
    if (_uid == null) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para guardar tu perfil.')),
      );
      return;
    }

    final nombre = nombreCtrl.text.trim();
    final telefono = telefonoCtrl.text.trim();
    final enfermedades = enfermedadesCtrl.text.trim();
    final rol = rolCtrl.text.trim();

    if (nombre.isEmpty && telefono.isEmpty && enfermedades.isEmpty) {
      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(content: Text('Completa al menos un campo')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_uid) // <-- MISMO DOC SIEMPRE
          .set({
        'uid': _uid,
        'email': _auth.currentUser?.email,
        'nombre': nombre,
        'telefono': telefono,
        'enfermedades': enfermedades,
        'rol': rol,
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // <-- ACTUALIZA, NO DUPLICA

      if (!mounted) return;
      ScaffoldMessenger.of(pageContext).showSnackBar(
        const SnackBar(content: Text('Perfil guardado ✅')),
      );
      FocusScope.of(pageContext).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(pageContext).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    telefonoCtrl.dispose();
    enfermedadesCtrl.dispose();
    rolCtrl.dispose();
    super.dispose();
  }

  // ===== TextField con estilo mint, label arriba y campo cómodo =====
  Widget _mintField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18, // altura del campo
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(
            color: AppColors.buttonTeal,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ===== Bottom sheet para editar perfil =====
  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgMint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final bottom = MediaQuery.of(sheetCtx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const Text(
                  'Editar perfil',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),

                _mintField(
                  controller: nombreCtrl,
                  label: 'Nombre completo',
                ),
                const SizedBox(height: 12),

                _mintField(
                  controller: telefonoCtrl,
                  label: 'Teléfono',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                _mintField(
                  controller: enfermedadesCtrl,
                  label: 'Enfermedades',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                _mintField(
                  controller: rolCtrl,
                  label: 'Rol (Paciente / Médico)',
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            await _guardar(context);
                            if (mounted) Navigator.pop(sheetCtx);
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.buttonTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 3,
                    ),
                    icon: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text(
                      'Guardar cambios',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Sin sesión
    if (_uid == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay usuario autenticado.\nInicia sesión para ver y guardar tu perfil.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgMint,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppColors.buttonTeal,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== HEADER TIPO CARD CON AVATAR =====
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.bgMint,
                  child: Icon(Icons.person, size: 40, color: AppColors.buttonTeal),
                ),
                const SizedBox(height: 10),
                Text(
                  nombreCtrl.text.isNotEmpty ? nombreCtrl.text : 'Usuario',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _auth.currentUser?.email ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),

                // Tarjetitas tipo "balance / orders / spent"
                Row(
                  children: [
                    Expanded(
                      child: _miniStatCard(
                        icon: Icons.badge_outlined,
                        label: 'Rol',
                        value: rolCtrl.text.isEmpty ? '—' : rolCtrl.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _miniStatCard(
                        icon: Icons.phone_android,
                        label: 'Teléfono',
                        value: telefonoCtrl.text.isEmpty ? '—' : telefonoCtrl.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _miniStatCard(
                        icon: Icons.favorite_border,
                        label: 'Salud',
                        value: enfermedadesCtrl.text.isEmpty
                            ? 'Sin datos'
                            : 'Ver detalle',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ===== BOTÓN EDITAR PERFIL =====
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openEditSheet,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.white,
                foregroundColor: AppColors.buttonTeal,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar perfil'),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Tus datos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          // Solo TU documento (no toda la colección)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(_uid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return Text('Error: ${snap.error}');
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.data!.exists) {
                return const Text('Aún no hay datos guardados para este usuario.');
              }
              final data = snap.data!.data() as Map<String, dynamic>;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Nombre'),
                      subtitle: Text((data['nombre'] ?? '').toString()),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Teléfono'),
                      subtitle: Text((data['telefono'] ?? '').toString()),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.medical_information_outlined),
                      title: const Text('Enfermedades'),
                      subtitle: Text(
                        (data['enfermedades'] ?? '').toString().isEmpty
                            ? 'Sin información registrada'
                            : (data['enfermedades'] ?? '').toString(),
                      ),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Rol'),
                      subtitle: Text((data['rol'] ?? '').toString()),
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

  // ===== mini cards tipo "Balance / Orders / Total" =====
  Widget _miniStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.buttonTeal,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
