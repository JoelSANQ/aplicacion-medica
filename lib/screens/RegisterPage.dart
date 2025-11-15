import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 Firestore

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  /// 'Paciente' o 'Medico'
  String _selectedRole = 'Paciente';

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona un rol (Paciente o Médico)")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final user = cred.user;

      // 👇 Guardar rol en colección "users" en Firestore
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'email': _email.text.trim(),
          'role': _selectedRole, // 'Paciente' o 'Medico'
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cuenta creada correctamente. Inicia sesión."),
          ),
        );
        Navigator.of(context).pop(); // vuelve al LoginPage
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case "email-already-in-use":
          message = "Ese correo ya está registrado";
          break;
        case "invalid-email":
          message = "Correo inválido";
          break;
        case "weak-password":
          message = "Contraseña muy débil";
          break;
        default:
          message = "Error: ${e.message}";
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Crear cuenta")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Correo electrónico",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Ingresa tu correo";
                    if (!v.contains("@")) return "Correo inválido";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure1,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure1 ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Ingresa una contraseña";
                    }
                    if (v.length < 6) return "Mínimo 6 caracteres";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    labelText: "Confirmar contraseña",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure2 ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Confirma tu contraseña";
                    }
                    if (v != _password.text) {
                      return "Las contraseñas no coinciden";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // 🔹 Selección de rol (Paciente / Médico) con 2 botones
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Selecciona tu rol",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () {
                                setState(() => _selectedRole = 'Paciente');
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _selectedRole == 'Paciente'
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade200,
                          foregroundColor:
                              _selectedRole == 'Paciente'
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                        child: const Text("Paciente"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () {
                                setState(() => _selectedRole = 'Medico');
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _selectedRole == 'Medico'
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade200,
                          foregroundColor:
                              _selectedRole == 'Medico'
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                        child: const Text("Médico"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: Text(_loading ? "Creando..." : "Crear cuenta"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}