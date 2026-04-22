import 'package:flutter/material.dart';

class MyCategoriesPage extends StatefulWidget {
  const MyCategoriesPage({super.key});

  @override
  State<MyCategoriesPage> createState() => _MyCategoriesPageState();
}

class _MyCategoriesPageState extends State<MyCategoriesPage> {
  final List<TextEditingController> _categoryControllers = [
    TextEditingController(text: 'Wraps'),
    TextEditingController(text: 'Bowls'),
    TextEditingController(text: 'Getränke'),
  ];

  @override
  void dispose() {
    for (final controller in _categoryControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _moveUp(int index) {
    if (index == 0) return;

    setState(() {
      final controller = _categoryControllers.removeAt(index);
      _categoryControllers.insert(index - 1, controller);
    });
  }

  void _moveDown(int index) {
    if (index == _categoryControllers.length - 1) return;

    setState(() {
      final controller = _categoryControllers.removeAt(index);
      _categoryControllers.insert(index + 1, controller);
    });
  }

  void _removeCategory(int index) {
    if (_categoryControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mindestens eine Kategorie muss bleiben.'),
        ),
      );
      return;
    }

    setState(() {
      final controller = _categoryControllers.removeAt(index);
      controller.dispose();
    });
  }

  void _addNewCategory() {
    setState(() {
      _categoryControllers.add(
        TextEditingController(
          text: 'Neue Kategorie ${_categoryControllers.length + 1}',
        ),
      );
    });
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kategorien gespeichert.'),
      ),
    );
  }

  void _cancelChanges() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F1),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'My Categories',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hier kannst du Kategorien hinzufügen, umbenennen, löschen und sortieren.',
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
                  children: [
                    ...List.generate(_categoryControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CategoryItemCard(
                          controller: _categoryControllers[index],
                          isFirst: index == 0,
                          isLast: index == _categoryControllers.length - 1,
                          onMoveUp: () => _moveUp(index),
                          onMoveDown: () => _moveDown(index),
                          onRemove: () => _removeCategory(index),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _addNewCategory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F5E1C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          'Neue Kategorie hinzufügen',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Speichern',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _cancelChanges,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Abbrechen',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItemCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  const _CategoryItemCard({
    required this.controller,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE7E2D9),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Column(
            children: [
              _MiniIconButton(
                icon: Icons.keyboard_arrow_up_rounded,
                onTap: isFirst ? null : onMoveUp,
              ),
              const SizedBox(height: 8),
              _MiniIconButton(
                icon: Icons.keyboard_arrow_down_rounded,
                onTap: isLast ? null : onMoveDown,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Kategoriename',
                filled: true,
                fillColor: const Color(0xFFF3F0E9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE0DBD2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE0DBD2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A1A1A),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: onRemove,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD83A34),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Löschen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDisabled
              ? const Color(0xFFF1EFEA)
              : const Color(0xFFEEEBE4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDisabled
              ? const Color(0xFFB8B8B8)
              : const Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}