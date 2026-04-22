import 'package:flutter/material.dart';

class MyArticlesAvailabilityPage extends StatefulWidget {
  const MyArticlesAvailabilityPage({super.key});

  @override
  State<MyArticlesAvailabilityPage> createState() =>
      _MyArticlesAvailabilityPageState();
}

class _MyArticlesAvailabilityPageState
    extends State<MyArticlesAvailabilityPage> {
  String _selectedCategory = 'Kategorie 1';

  final Map<String, List<Map<String, dynamic>>> _categoryItems = {
    'Kategorie 1': [
      {
        'id': 'A-101',
        'name': 'Shawarma Wrap',
        'available': true,
      },
      {
        'id': 'A-102',
        'name': 'Falafel Wrap',
        'available': false,
      },
      {
        'id': 'A-103',
        'name': 'Halloumi Wrap',
        'available': true,
      },
    ],
    'Kategorie 2': [
      {
        'id': 'B-201',
        'name': 'Pommes',
        'available': true,
      },
      {
        'id': 'B-202',
        'name': 'Hummus Teller',
        'available': true,
      },
      {
        'id': 'B-203',
        'name': 'Couscous Bowl',
        'available': false,
      },
    ],
    'Kategorie 3': [
      {
        'id': 'C-301',
        'name': 'Cola',
        'available': true,
      },
      {
        'id': 'C-302',
        'name': 'Ayran',
        'available': false,
      },
      {
        'id': 'C-303',
        'name': 'Wasser',
        'available': true,
      },
    ],
  };

  List<Map<String, dynamic>> get _currentItems =>
      _categoryItems[_selectedCategory] ?? [];

  void _toggleAvailability(int index, bool value) {
    setState(() {
      _currentItems[index]['available'] = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Artikel aktiviert.' : 'Artikel deaktiviert.',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F1),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Verfügbarkeit',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF1A1A1A),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wähle eine Kategorie und aktiviere oder deaktiviere einzelne Artikel.',
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFCF9),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: const Color(0xFFE7E2D9),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategorie',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE0DBD2),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF777777),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          dropdownColor: const Color(0xFFFDFCF9),
                          items: const [
                            DropdownMenuItem(
                              value: 'Kategorie 1',
                              child: Text('Kategorie 1'),
                            ),
                            DropdownMenuItem(
                              value: 'Kategorie 2',
                              child: Text('Kategorie 2'),
                            ),
                            DropdownMenuItem(
                              value: 'Kategorie 3',
                              child: Text('Kategorie 3'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Artikel',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 14),

              ...List.generate(_currentItems.length, (index) {
                final item = _currentItems[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _AvailabilityItemCard(
                    articleId: item['id'],
                    articleName: item['name'],
                    isAvailable: item['available'],
                    onChanged: (value) => _toggleAvailability(index, value),
                  ),
                );
              }),

              const SizedBox(height: 16),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _TrustChip(icon: '🗂️', label: 'Kategorien'),
                  _TrustChip(icon: '👁️', label: 'Schnelle Übersicht'),
                  _TrustChip(icon: '⚡', label: 'Direkt umschalten'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityItemCard extends StatelessWidget {
  final String articleId;
  final String articleName;
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const _AvailabilityItemCard({
    required this.articleId,
    required this.articleName,
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE7E2D9),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEBE4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: Color(0xFF7A7A7A),
                    size: 30,
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      articleId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  articleName,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAvailable ? 'Aktuell verfügbar' : 'Aktuell nicht verfügbar',
                  style: TextStyle(
                    color: isAvailable
                        ? const Color(0xFF4F6B52)
                        : const Color(0xFF8A6A6A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isAvailable,
            onChanged: onChanged,
            activeColor: const Color(0xFF1A1A1A),
          ),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final String icon;
  final String label;

  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEBE4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}