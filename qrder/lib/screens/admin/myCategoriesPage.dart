import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyCategoriesPage extends StatefulWidget {
  const MyCategoriesPage({super.key});

  @override
  State<MyCategoriesPage> createState() => _MyCategoriesPageState();
}

class _MyCategoriesPageState extends State<MyCategoriesPage> {
  static const Color _bg = Color(0xFFF8F6F1);
  static const Color _card = Color(0xFFFFFEFB);
  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _muted = Color(0xFF777777);
  static const Color _soft = Color(0xFFEEEBE4);
  static const Color _line = Color(0xFFE7E2D9);
  static const Color _green = Color(0xFF2F5E1C);
  static const Color _red = Color(0xFFD83A34);

  bool _isSavingOrder = false;

  String? get _merchantId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _categoriesRef {
    final merchantId = _merchantId;
    if (merchantId == null) return null;

    return FirebaseFirestore.instance
        .collection('merchants')
        .doc(merchantId)
        .collection('itemCategories');
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  void _showSnack(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  Future<void> _addCategory() async {
    final ref = _categoriesRef;
    final merchantId = _merchantId;

    if (ref == null || merchantId == null) {
      _showSnack('Kein Händler gefunden.');
      return;
    }

    final result = await _openCategorySheet();

    if (result == null) return;

    final name = result.name.trim();
    final description = result.description.trim();
    final normalizedName = _normalize(name);

    if (normalizedName.isEmpty) {
      _showSnack('Bitte gültigen Namen eingeben.');
      return;
    }

    final docRef = ref.doc(normalizedName);
    final doc = await docRef.get();
    final oldData = doc.data();

    if (doc.exists && oldData?['isActive'] != false) {
      _showSnack('Diese Kategorie gibt es schon.');
      return;
    }

    await docRef.set({
      'id': normalizedName,
      'merchantId': merchantId,
      'name': name,
      'normalizedName': normalizedName,
      'description': description,
      'sortOrder': DateTime.now().millisecondsSinceEpoch,
      'isActive': true,
      'createdAt': oldData?['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _showSnack('Kategorie hinzugefügt.');
  }

  Future<void> _editCategory(CategoryData category) async {
    final ref = _categoriesRef;
    if (ref == null) return;

    final result = await _openCategorySheet(
      name: category.name,
      description: category.description,
      title: 'Kategorie bearbeiten',
      buttonText: 'Speichern',
    );

    if (result == null) return;

    final name = result.name.trim();
    final description = result.description.trim();

    if (name.isEmpty) {
      _showSnack('Name darf nicht leer sein.');
      return;
    }

    await ref.doc(category.id).update({
      'name': name,
      'normalizedName': _normalize(name),
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _showSnack('Kategorie gespeichert.');
  }

  Future<void> _deactivateCategory(CategoryData category) async {
    final ref = _categoriesRef;
    if (ref == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: _card,
          title: const Text('Kategorie deaktivieren?'),
          content: Text(
            '"${category.name}" wird nicht gelöscht, sondern nur ausgeblendet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Deaktivieren'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await ref.doc(category.id).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _showSnack('Kategorie deaktiviert.');
  }

  Future<void> _moveCategory({
    required List<CategoryData> categories,
    required int oldIndex,
    required int newIndex,
  }) async {
    final ref = _categoriesRef;
    if (ref == null) return;

    if (newIndex < 0 || newIndex >= categories.length) return;

    final copy = [...categories];
    final item = copy.removeAt(oldIndex);
    copy.insert(newIndex, item);

    setState(() => _isSavingOrder = true);

    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < copy.length; i++) {
      batch.update(ref.doc(copy[i].id), {
        'sortOrder': i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    if (!mounted) return;
    setState(() => _isSavingOrder = false);
  }

  Future<_CategorySheetResult?> _openCategorySheet({
    String name = '',
    String description = '',
    String title = 'Neue Kategorie',
    String buttonText = 'Hinzufügen',
  }) async {
    final nameController = TextEditingController(text: name);
    final descriptionController = TextEditingController(text: description);

    final result = await showModalBottomSheet<_CategorySheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            18,
            24,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: _line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              _SheetField(
                controller: nameController,
                label: 'Name',
                hintText: 'z. B. Wraps',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 12),
              _SheetField(
                controller: descriptionController,
                label: 'Beschreibung optional',
                hintText: 'z. B. Gerollte Spezialitäten',
                icon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final cleanName = nameController.text.trim();

                    if (cleanName.isEmpty) return;

                    Navigator.pop(
                      context,
                      _CategorySheetResult(
                        name: cleanName,
                        description: descriptionController.text.trim(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ref = _categoriesRef;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Kategorien',
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: _ink),
        actions: [
          IconButton(
            onPressed: _addCategory,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ref == null
            ? const Center(child: Text('Kein Händler gefunden.'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: ref.orderBy('sortOrder').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Kategorien konnten nicht geladen werden.'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _ink),
              );
            }

            final categories = snapshot.data!.docs
                .map((doc) => CategoryData.fromDoc(doc))
                .where((cat) => cat.isActive)
                .toList();

            if (categories.isEmpty) {
              return _EmptyCategories(onAdd: _addCategory);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopInfo(
                    count: categories.length,
                    isSavingOrder: _isSavingOrder,
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final category = categories[index];

                      return _CategoryCard(
                        category: category,
                        isFirst: index == 0,
                        isLast: index == categories.length - 1,
                        onEdit: () => _editCategory(category),
                        onDelete: () => _deactivateCategory(category),
                        onMoveUp: () => _moveCategory(
                          categories: categories,
                          oldIndex: index,
                          newIndex: index - 1,
                        ),
                        onMoveDown: () => _moveCategory(
                          categories: categories,
                          oldIndex: index,
                          newIndex: index + 1,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _addCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Kategorie hinzufügen',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class CategoryData {
  final String id;
  final String name;
  final String description;
  final int sortOrder;
  final bool isActive;

  const CategoryData({
    required this.id,
    required this.name,
    required this.description,
    required this.sortOrder,
    required this.isActive,
  });

  factory CategoryData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return CategoryData(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'Ohne Name',
      description: data['description']?.toString() ?? '',
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] as int : 999999,
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}

class _CategorySheetResult {
  final String name;
  final String description;

  const _CategorySheetResult({
    required this.name,
    required this.description,
  });
}

class _TopInfo extends StatelessWidget {
  final int count;
  final bool isSavingOrder;

  const _TopInfo({
    required this.count,
    required this.isSavingOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E2D9)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEBE4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.category_outlined,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Kategorien',
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSavingOrder
                      ? 'Reihenfolge wird gespeichert...'
                      : 'Sortieren, bearbeiten, deaktivieren.',
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
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

class _CategoryCard extends StatelessWidget {
  final CategoryData category;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _CategoryCard({
    required this.category,
    required this.isFirst,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFEFB),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE7E2D9)),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  _MiniIconButton(
                    icon: Icons.keyboard_arrow_up_rounded,
                    onTap: isFirst ? null : onMoveUp,
                  ),
                  const SizedBox(height: 6),
                  _MiniIconButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: isLast ? null : onMoveDown,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description.isEmpty
                          ? 'Keine Beschreibung'
                          : category.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF777777),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.visibility_off_rounded,
                  color: Color(0xFFD83A34),
                ),
              ),
            ],
          ),
        ),
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
    final disabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFFF1EFEA)
              : const Color(0xFFEEEBE4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: disabled
              ? const Color(0xFFB8B8B8)
              : const Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final int maxLines;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF777777)),
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
    );
  }
}

class _EmptyCategories extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyCategories({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.category_outlined,
              size: 46,
              color: Color(0xFF777777),
            ),
            const SizedBox(height: 14),
            const Text(
              'Noch keine Kategorien',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Erstelle z. B. Wraps, Bowls oder Getränke.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF777777),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Kategorie hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}