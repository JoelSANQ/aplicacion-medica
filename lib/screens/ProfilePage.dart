import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _logFirebase(); // imprime el projectId/appId para verificar el enlace
  }

  void _logFirebase() {
    try {
      final o = Firebase.app().options;
      // Mira esto en el panel "Debug Console" de VSCode/Android Studio
      // Debe coincidir con tu proyecto de Firebase
      // (p. ej. projectId=doctorappointment-xxxx)
      // ignore: avoid_print
      print('[FIREBASE] projectId=${o.projectId} appId=${o.appId}');
    } catch (_) {}
  }

  // ===== FUNCIÓN GUARDAR =====
  Future<void> _guardarPerfil(BuildContext context) async {
    final user = _auth.currentUser;
    final nombre = nombreCtrl.text.trim();
    final telefono = telefonoCtrl.text.trim();
    final enfermedades = enfermedadesCtrl.text.trim();

    if (nombre.isEmpty && telefono.isEmpty && enfermedades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos antes de guardar')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // 👉 Si NO existe "usuarios", Firestore la crea automáticamente con este write
      await FirebaseFirestore.instance.collection('usuarios').add({
        'nombre': nombre,
        'telefono': telefono,
        'enfermedades': enfermedades,
        'email': user?.email,
        'uid': user?.uid,
        'creadoEn': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado exitosamente ✅')),
      );

      nombreCtrl.clear();
      telefonoCtrl.clear();
      enfermedadesCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Botón de comprobación: escribe `debug_write/ping`
  Future<void> _testWrite() async {
    try {
      final now = DateTime.now().toIso8601String();
      await FirebaseFirestore.instance
          .collection('debug_write')
          .doc('ping')
          .set({'when': now});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test write OK: $now')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test write falló: $e')),
      );
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    telefonoCtrl.dispose();
    enfermedadesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.currentUser?.email ?? 'Usuario sin sesión';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Correo: $email', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            // Campos
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: enfermedadesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Enfermedades',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Botón Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : () => _guardarPerfil(context),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar información'),
              ),
            ),
            const SizedBox(height: 8),

            // Botón de prueba (escritura de sanity check)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _testWrite,
                child: const Text('Test write (debug_write/ping)'),
              ),
            ),
            const SizedBox(height: 16),

            // 🔎 Mostrar registros guardados
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Perfiles guardados:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .orderBy('creadoEn', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text('No hay perfiles guardados todavía.');
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final nombre = data['nombre'] ?? '';
                      final telefono = data['telefono'] ?? '';
                      final enfermedades = data['enfermedades'] ?? '';
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(nombre.isEmpty ? '(Sin nombre)' : nombre),
                        subtitle: Text(
                          'Tel: $telefono\nEnfermedades: $enfermedades',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
