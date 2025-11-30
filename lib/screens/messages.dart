import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // 👈 Necesario para PointerDeviceKind
import 'package:app/theme/app_colors.dart';

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

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      if (_chats.isNotEmpty) {
        final last = _chats.removeLast();
        _chats.insert(0, last);
      }
    });
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar doctor o especialidad...',
                prefixIcon: const Icon(Icons.search, size: 26),
                filled: true,
                fillColor: AppColors.bgMint,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // 💬 Lista con pull-to-refresh usando mouse (drag)
          Expanded(
            child: ScrollConfiguration(
              behavior: const MaterialScrollBehavior().copyWith(
                // 👇 Habilita drag con mouse (y otros dispositivos)
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.invertedStylus,
                  PointerDeviceKind.unknown,
                },
              ),
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                edgeOffset: 0,
                displacement: 60,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: chatsFiltered.length,
                  itemBuilder: (context, index) {
                    final chat = chatsFiltered[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardMintStart,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.buttonTeal,
                          child: Text(
                            chat['avatar']!,
                            style: const TextStyle(fontSize: 24, color: Colors.white),
                          ),
                        ),
                        title: Text(
                          chat['name']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
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
                      ),
                    );
                  },
                ),
              ),
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
        child: Text(
          'Aquí aparecerán los mensajes del chat',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
      ),
    );
  }
}
