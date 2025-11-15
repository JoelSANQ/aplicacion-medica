// lib/medic/Dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('Inicia sesión como médico para ver el dashboard.'),
      );
    }

    // Leemos el documento del médico para obtener su "medicoId"
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .get(),
      builder: (context, snapUser) {
        if (snapUser.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        String? medicoKey;
        if (snapUser.hasData && snapUser.data!.exists) {
          final data = snapUser.data!.data() as Map<String, dynamic>?;
          medicoKey = data?['medicoId']?.toString() ??
              data?['codigoMedico']?.toString() ??
              data?['idMedico']?.toString();
        }

        // 🔁 Fallback para tu caso actual (Dr. Joel)
        medicoKey ??= 'dr_joel';

        return _DashboardContent(medicoKey: medicoKey!);
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final String medicoKey;
  const _DashboardContent({required this.medicoKey});

  String _fmtFecha(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _fmtHora(DateTime d) => DateFormat('HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== TÍTULO =====
              Text(
                'Dashboard de citas',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Resumen en tiempo real de tus citas médicas.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // ===== STATS Y MIS CITAS (solo del médico actual) =====
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('citas')
                    .where('medicoId', isEqualTo: medicoKey)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  final totalCitas = docs.length;

                  int citasProximas = 0;
                  final pacientesAtendidosSet = <String>{};
                  final motivosCounter = <String, int>{};
                  final List<QueryDocumentSnapshot> proximas = [];

                  for (final d in docs) {
                    final data = d.data() as Map<String, dynamic>;

                    final ts = data['cuando'] as Timestamp?;
                    final fecha = ts?.toDate();

                    final pacienteId = data['pacienteId']?.toString();
                    if (pacienteId != null && pacienteId.isNotEmpty) {
                      pacientesAtendidosSet.add(pacienteId);
                    }

                    final motivo =
                        (data['motivo'] ?? data['titulo'] ?? '').toString().trim();
                    if (motivo.isNotEmpty) {
                      motivosCounter[motivo] =
                          (motivosCounter[motivo] ?? 0) + 1;
                    }

                    if (fecha != null && fecha.isAfter(now)) {
                      citasProximas++;
                      proximas.add(d);
                    }
                  }

                  proximas.sort((a, b) {
                    final da =
                        (a['cuando'] as Timestamp?)?.toDate() ?? DateTime(1900);
                    final db =
                        (b['cuando'] as Timestamp?)?.toDate() ?? DateTime(1900);
                    return da.compareTo(db);
                  });

                  final pacientesAtendidos = pacientesAtendidosSet.length;

                  String enfermedadTop = '—';
                  int enfermedadTopCount = 0;
                  motivosCounter.forEach((motivo, count) {
                    if (count > enfermedadTopCount) {
                      enfermedadTop = motivo;
                      enfermedadTopCount = count;
                    }
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === FILA DE 3 CARDS (STATS) ===
                      Row(
                        children: [
                          Expanded(
                            child: _DashboardCard(
                              title: 'Citas creadas',
                              value: '$totalCitas',
                              subtitle: 'Total registradas',
                              icon: Icons.event_note,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DashboardCard(
                              title: 'Citas próximas',
                              value: '$citasProximas',
                              subtitle: 'Pendientes por atender',
                              icon: Icons.schedule,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF43A047), Color(0xFF81C784)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DashboardCard(
                              title: 'Pacientes atendidos',
                              value: '$pacientesAtendidos',
                              subtitle: 'Con al menos 1 cita',
                              icon: Icons.group,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFA726), Color(0xFFFFCC80)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // === CARD ENFERMEDAD MÁS RECURRENTE ===
                      _DashboardCard(
                        title: 'Enfermedad más recurrente',
                        value: enfermedadTop,
                        subtitle: enfermedadTopCount > 0
                            ? 'Total de casos: $enfermedadTopCount'
                            : 'Aún no hay suficientes datos',
                        icon: Icons.local_hospital,
                        height: 110,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8E24AA), Color(0xFFCE93D8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ========= MIS CITAS (LISTA DETALLADA) =========
                      Text(
                        'Mis citas',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      if (docs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('No tienes citas registradas como médico.'),
                        )
                      else
                        Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final motivo =
                                (data['titulo'] ?? data['motivo'] ?? 'Cita')
                                    .toString();
                            final lugar =
                                (data['lugar'] ?? '—').toString();
                            final ts = data['cuando'] as Timestamp?;
                            final fecha = ts?.toDate();
                            DateTime? fin;
                            if (data['cuandoFin'] is Timestamp) {
                              fin = (data['cuandoFin'] as Timestamp).toDate();
                            } else if (fecha != null) {
                              fin = fecha.add(const Duration(hours: 1));
                            }

                            final fechaTxt =
                                fecha == null ? '—' : _fmtFecha(fecha);
                            final horaInicioTxt =
                                fecha == null ? '—' : _fmtHora(fecha);
                            final horaFinTxt =
                                fin == null ? '—' : _fmtHora(fin);

                            final pacienteId =
                                (data['pacienteId'] ?? '').toString();

                            // Helper local para construir la card
                            Widget buildTile(String pacienteNombre) {
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.event_available,
                                    color: Color(0xFF1976D2),
                                  ),
                                  title: Text(
                                    motivo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '$fechaTxt · $horaInicioTxt - $horaFinTxt\n'
                                    'Paciente: $pacienteNombre · Lugar: $lugar',
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            }

                            // Si no hay pacienteId, mostramos texto genérico
                            if (pacienteId.isEmpty) {
                              return buildTile('Paciente sin ID');
                            }

                            // Buscamos el nombre del paciente en la colección "usuarios/{pacienteId}"
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('usuarios')
                                  .doc(pacienteId)
                                  .get(),
                              builder: (ctx, snapPaciente) {
                                if (snapPaciente.connectionState ==
                                    ConnectionState.waiting) {
                                  return buildTile('Cargando...');
                                }

                                String nombrePaciente = pacienteId;
                                if (snapPaciente.hasData &&
                                    snapPaciente.data!.exists) {
                                  final pData = snapPaciente.data!.data()
                                      as Map<String, dynamic>?;
                                  nombrePaciente =
                                      (pData?['nombre'] ?? pacienteId)
                                          .toString();
                                }

                                return buildTile(nombrePaciente);
                              },
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // ===== PACIENTES REGISTRADOS (colección usuarios) =====
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .where('rol', isEqualTo: 'Paciente')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final totalPacientes = snapshot.data!.docs.length;

                  return _DashboardWideCard(
                    title: 'Pacientes registrados',
                    value: '$totalPacientes',
                    subtitle: 'En el sistema',
                    icon: Icons.person,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFAB47BC), Color(0xFF7E57C2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== CARD PEQUEÑA (INDICADORES) =====
class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final double height;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: Icon(icon, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== CARD ANCHA (PACIENTES REGISTRADOS) =====
class _DashboardWideCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;

  const _DashboardWideCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white24,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
