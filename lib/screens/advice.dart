import 'package:flutter/material.dart';

class HealthTipsPage extends StatefulWidget {
  const HealthTipsPage({super.key});

  @override
  State<HealthTipsPage> createState() => _HealthTipsPageState();
}

class _HealthTipsPageState extends State<HealthTipsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedCategory = 'Todos';
  final Set<String> _favorites = {};

  late final List<HealthTip> _tips;
  late final HealthTip _tipOfDay;

  // Categorías disponibles (la primera es "Todos")
  final List<String> _categories = const [
    'Todos',
    'Actividad física',
    'Nutrición',
    'Sueño',
    'Estrés',
    'Hidratación',
    'Hábitos',
    'Prevención',
  ];

  @override
  void initState() {
    super.initState();
    _tips = _seedTips();
    _tipOfDay = _tips[(DateTime.now().day + DateTime.now().month) % _tips.length];
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<HealthTip> _seedTips() {
    return [
      HealthTip(
        id: 't1',
        title: 'Camina 30 minutos al día',
        summary: 'Mejora tu salud cardiovascular y estado de ánimo.',
        details:
            'La caminata moderada durante 30 minutos diarios ayuda a mantener un peso saludable, mejora la circulación y reduce el estrés. Si no puedes hacerlo de corrido, divídelo en bloques de 10 minutos.',
        category: 'Actividad física',
        icon: Icons.directions_walk,
      ),
      HealthTip(
        id: 't2',
        title: 'Plato equilibrado 50/25/25',
        summary: 'Verduras/frutas (50%), proteína (25%), granos integrales (25%).',
        details:
            'Llena la mitad del plato con verduras y frutas coloridas, un cuarto con proteína magra (pollo, pescado, legumbres) y el otro cuarto con cereales integrales (avena, arroz integral).',
        category: 'Nutrición',
        icon: Icons.restaurant,
      ),
      HealthTip(
        id: 't3',
        title: 'Hidratación inteligente',
        summary: 'De 6 a 8 vasos de agua al día, ajusta por clima y actividad.',
        details:
            'Lleva una botella reutilizable. Bebe más si haces ejercicio o hace calor. Observa el color de tu orina: un tono claro suele indicar buena hidratación.',
        category: 'Hidratación',
        icon: Icons.water_drop,
      ),
      HealthTip(
        id: 't4',
        title: 'Rutina de sueño constante',
        summary: 'Duerme 7–9 horas y respeta horarios.',
        details:
            'Acostarte y levantarte a la misma hora mejora la calidad del descanso. Evita pantallas 60 minutos antes de dormir, reduce cafeína por la tarde y procura un cuarto oscuro y fresco.',
        category: 'Sueño',
        icon: Icons.nightlight_round,
      ),
      HealthTip(
        id: 't5',
        title: 'Respiración 4-7-8',
        summary: 'Técnica breve para reducir estrés.',
        details:
            'Inhala 4 segundos, retén 7 y exhala 8. Repite 4 rondas. Útil antes de dormir o en momentos de ansiedad. No sustituye terapia, pero ayuda a regular el sistema nervioso.',
        category: 'Estrés',
        icon: Icons.self_improvement,
      ),
      HealthTip(
        id: 't6',
        title: 'Limita bebidas azucaradas',
        summary: 'Prioriza agua, tés sin azúcar y café moderado.',
        details:
            'Reducir refrescos y jugos industrializados ayuda a controlar peso y salud metabólica. Si te cuesta, empieza diluyendo jugos o eligiendo versiones sin azúcar añadida.',
        category: 'Hábitos',
        icon: Icons.no_drinks,
      ),
      HealthTip(
        id: 't7',
        title: 'Calentamiento y estiramiento',
        summary: 'Previene lesiones y mejora movilidad.',
        details:
            'Antes de ejercitarte, realiza 5–10 minutos de movilidad articular. Al finalizar, estira los grupos musculares trabajados durante 10–20 segundos sin rebotes.',
        category: 'Prevención',
        icon: Icons.health_and_safety,
      ),
      HealthTip(
        id: 't8',
        title: 'Proteína en cada comida',
        summary: 'Mejora saciedad y mantenimiento muscular.',
        details:
            'Incluye huevos, pollo, pescado, legumbres o tofu en tus comidas principales. Ajusta por tus necesidades y consulta a un profesional si tienes enfermedades renales.',
        category: 'Nutrición',
        icon: Icons.set_meal,
      ),
      HealthTip(
        id: 't9',
        title: 'Pausas activas cada 60–90 min',
        summary: 'Evita sedentarismo y rigidez postural.',
        details:
            'Levántate, camina, haz 10 sentadillas o movilidad de cuello/hombros. Pequeñas pausas mejoran circulación y concentración.',
        category: 'Actividad física',
        icon: Icons.timer,
      ),
      HealthTip(
        id: 't10',
        title: 'Sol de la mañana (con cuidado)',
        summary: 'Ayuda al ritmo circadiano y vitamina D.',
        details:
            'Exponte a luz natural por la mañana 10–15 minutos. Usa protección solar si la exposición es prolongada o en horas de alta radiación.',
        category: 'Prevención',
        icon: Icons.wb_sunny,
      ),
      HealthTip(
        id: 't11',
        title: 'Planifica snacks saludables',
        summary: 'Evita picos de hambre y antojos.',
        details:
            'Ten a mano fruta, yogur natural, frutos secos (porciones pequeñas) o palitos de verduras. Evita snacks ultra procesados con azúcares añadidos.',
        category: 'Hábitos',
        icon: Icons.local_grocery_store,
      ),
      HealthTip(
        id: 't12',
        title: 'Higiene del sueño: rutina',
        summary: 'Señales al cerebro para descansar.',
        details:
            'Lee 10 minutos, toma una ducha tibia o realiza una meditación breve. Repite la rutina a diario para asociarla al descanso.',
        category: 'Sueño',
        icon: Icons.menu_book,
      ),
    ];
  }

  List<HealthTip> get _filtered {
    return _tips.where((t) {
      final byCategory = _selectedCategory == 'Todos' || t.category == _selectedCategory;
      final byQuery = _query.isEmpty ||
          t.title.toLowerCase().contains(_query) ||
          t.summary.toLowerCase().contains(_query) ||
          t.details.toLowerCase().contains(_query);
      return byCategory && byQuery;
    }).toList();
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  void _showTipDetail(HealthTip tip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(tip.icon, size: 28, color: Colors.teal[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: _favorites.contains(tip.id) ? 'Quitar de favoritos' : 'Agregar a favoritos',
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleFavorite(tip.id);
                    },
                    icon: Icon(
                      _favorites.contains(tip.id) ? Icons.bookmark : Icons.bookmark_border,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(tip.summary, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              Text(tip.details),
              const SizedBox(height: 16),
              const Divider(),
              Row(
                children: const [
                  Icon(Icons.info_outline, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este contenido es informativo y no sustituye el consejo de un profesional de la salud.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consejos de salud'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Consejo del día (destacado)
          _TipOfDayCard(
            tip: _tipOfDay,
            onTap: () => _showTipDetail(_tipOfDay),
            isFavorite: _favorites.contains(_tipOfDay.id),
            onFav: () => _toggleFavorite(_tipOfDay.id),
          ),
          const SizedBox(height: 16),

          // Buscador
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar (ej. sueño, agua, caminar...)',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF3F6F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),

          // Filtros por categoría
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Lista de consejos filtrados
          ...filtered.map((t) {
            final fav = _favorites.contains(t.id);
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: Icon(t.icon, color: Colors.teal[700]),
                title: Text(t.title),
                subtitle: Text(t.summary),
                onTap: () => _showTipDetail(t),
                trailing: IconButton(
                  tooltip: fav ? 'Quitar de favoritos' : 'Agregar a favoritos',
                  icon: Icon(fav ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: () => _toggleFavorite(t.id),
                ),
              ),
            );
          }),

          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: const [
                  Icon(Icons.search_off, size: 36, color: Colors.black38),
                  SizedBox(height: 8),
                  Text('Sin resultados. Prueba con otra búsqueda o categoría.'),
                ],
              ),
            ),

          const SizedBox(height: 24),
          // Disclaimer final
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recomendaciones generales. Consulta a un profesional de la salud para diagnóstico y tratamiento.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====== MODELO ======
class HealthTip {
  final String id;
  final String title;
  final String summary;
  final String details;
  final String category;
  final IconData icon;

  const HealthTip({
    required this.id,
    required this.title,
    required this.summary,
    required this.details,
    required this.category,
    required this.icon,
  });
}

// ====== WIDGET Consejo del día ======
class _TipOfDayCard extends StatelessWidget {
  final HealthTip tip;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFav;

  const _TipOfDayCard({
    required this.tip,
    required this.onTap,
    required this.isFavorite,
    required this.onFav,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE3F2FD), Color.fromARGB(255, 219, 248, 248)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(tip.icon, size: 40, color: Colors.teal[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Consejo del día',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    tip.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    tip.summary,
                    style: const TextStyle(color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
              icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
              onPressed: onFav,
            ),
          ],
        ),
      ),
    );
  }
}
