import 'package:flutter/material.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final List<Map<String, String>> _chats = [
    {
      'name': 'Dr. López',
      'specialty': 'Cardiólogo',
      'lastMsg': 'Su cita está confirmada para mañana.',
      'time': '10:32 AM',
      'avatar': '❤️'
    },
    {
      'name': 'Dra. Martínez',
      'specialty': 'Pediatra',
      'lastMsg': 'Envíame los resultados cuando los tengas.',
      'time': '09:15 AM',
      'avatar': '🩺'
    },
    {
      'name': 'Dr. Ramírez',
      'specialty': 'Dentista',
      'lastMsg': 'Recuerde no comer antes de la revisión.',
      'time': 'Ayer',
      'avatar': '🦷'
    },
    {
      'name': 'Dra. Gómez',
      'specialty': 'Dermatóloga',
      'lastMsg': 'Le enviaré una crema recomendada.',
      'time': 'Lun',
      'avatar': '💊'
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatsFiltered = _chats
        .where((c) =>
            c['name']!.toLowerCase().contains(_query) ||
            c['specialty']!.toLowerCase().contains(_query) ||
            c['lastMsg']!.toLowerCase().contains(_query))
        .toList();

    return Scaffold(
      body: Column(
        children: [
          // 🔍 Buscador
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar doctor o especialidad...',
                prefixIcon: const Icon(Icons.search, size: 26),
                filled: true,
                fillColor: const Color(0xFFF3F6F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // 💬 Lista de chats más grande
          Expanded(
            child: ListView.builder(
              itemCount: chatsFiltered.length,
              itemBuilder: (context, index) {
                final chat = chatsFiltered[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFEDE7F6),
                    child: Text(chat['avatar']!, style: const TextStyle(fontSize: 24)),
                  ),
                  title: Text(
                    chat['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    chat['lastMsg']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                  trailing: Text(
                    chat['time']!,
                    style: const TextStyle(color: Colors.black45, fontSize: 14),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailPage(
                        doctor: chat['name']!,
                        specialty: chat['specialty']!,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatDetailPage extends StatelessWidget {
  final String doctor;
  final String specialty;

  const ChatDetailPage({
    super.key,
    required this.doctor,
    required this.specialty,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doctor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(specialty, style: const TextStyle(fontSize: 15, color: Colors.white70)),
          ],
        ),
      ),
      body: const Center(
        child: Text('Aquí aparecerán los mensajes del chat',
            style: TextStyle(color: Colors.black54, fontSize: 16)),
      ),
    );
  }
}
