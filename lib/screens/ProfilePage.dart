import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _guardar() async {
    if (_uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión para guardar tu perfil.')),
      );
      return;
    }

    final nombre = nombreCtrl.text.trim();
    final telefono = telefonoCtrl.text.trim();
    final enfermedades = enfermedadesCtrl.text.trim();

    if (nombre.isEmpty && telefono.isEmpty && enfermedades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
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
        'actualizadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // <-- ACTUALIZA, NO DUPLICA

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado ✅')),
      );
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
    super.dispose();
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
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Encabezado
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.person, size: 28, color: Color(0xFF1565C0)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _auth.currentUser?.email ?? 'Usuario',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      const Text('Perfil', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text('Editar datos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

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
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _guardar,
              icon: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),

          const Text('Tus Datos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Solo TU documento (no toda la colección)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(_uid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return Text('Error: ${snap.error}');
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (!snap.data!.exists) {
                return const Text('Aún no hay datos guardados para este usuario.');
              }
              final data = snap.data!.data() as Map<String, dynamic>;
              return Container(
                decoration: BoxDecoration(
                  boxShadow: const [BoxShadow(color: Colors.black12,)],
                  borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFE3F2FD), Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),),
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Nombre: ${data['nombre'] ?? ''}\n'
                  'Teléfono: ${data['telefono'] ?? ''}\n'
                  'Enfermedades: ${data['enfermedades'] ?? ''}',
                  style: const TextStyle(height: 1.4),
                  
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
