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
  static const Color _gold = Color(0xFFD8A75D);

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

  CollectionReference<Map<String, dynamic>>? get _itemsRef {
    final merchantId = _merchantId;
    if (merchantId == null) return null;

    return FirebaseFirestore.instance
        .collection('merchants')
        .doc(merchantId)
        .collection('items');
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

    final result = await _openCategorySheet(
      title: 'Neue Kategorie',
      buttonText: 'Hinzufügen',
    );

    if (result == null) return;

    final name = result.name.trim();
    final description = result.description.trim();

    if (name.isEmpty) {
      _showSnack('Bitte Namen eingeben.');
      return;
    }

    final id = _normalize(name);

    if (id.isEmpty) {
      _showSnack('Ungültiger Kategoriename.');
      return;
    }

    final docRef = ref.doc(id);
    final doc = await docRef.get();
    final oldData = doc.data();

    if (doc.exists && oldData?['isActive'] != false) {
      _showSnack('Diese Kategorie gibt es schon.');
      return;
    }

    await docRef.set({
      'id': id,
      'merchantId': merchantId,
      'name': name,
      'normalizedName': id,
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
      title: 'Kategorie bearbeiten',
      buttonText: 'Speichern',
      name: category.name,
      description: category.description,
    );

    if (result == null) return;

    final name = result.name.trim();

    if (name.isEmpty) {
      _showSnack('Name darf nicht leer sein.');
      return;
    }

    await ref.doc(category.id).update({
      'name': name,
      'normalizedName': _normalize(name),
      'description': result.description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _showSnack('Kategorie gespeichert.');
  }

  Future<void> _hideCategory(CategoryData category, int itemCount) async {
    final ref = _categoriesRef;
    if (ref == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: _card,
          title: const Text('Kategorie ausblenden?'),
          content: Text(
            itemCount > 0
                ? '"${category.name}" hat $itemCount Artikel. Die Kategorie wird nur ausgeblendet, nicht gelöscht.'
                : '"${category.name}" wird ausgeblendet, nicht gelöscht.',
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
              child: const Text('Ausblenden'),
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

    _showSnack('Kategorie ausgeblendet.');
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

  int _countItemsForCategory({
    required String categoryId,
    required List<ArticleData> articles,
  }) {
    return articles.where((item) => item.categoryId == categoryId).length;
  }

  Future<_CategorySheetResult?> _openCategorySheet({
    required String title,
    required String buttonText,
    String name = '',
    String description = '',
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
                      fontWeight: FontWeight.w900,
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
    final categoriesRef = _categoriesRef;
    final itemsRef = _itemsRef;

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
        child: categoriesRef == null || itemsRef == null
            ? const Center(child: Text('Kein Händler gefunden.'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: categoriesRef.orderBy('sortOrder').snapshots(),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.hasError) {
              return const Center(
                child: Text('Kategorien konnten nicht geladen werden.'),
              );
            }

            if (!categorySnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _ink),
              );
            }

            final categories = categorySnapshot.data!.docs
                .map((doc) => CategoryData.fromDoc(doc))
                .where((category) => category.isActive)
                .toList();

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: itemsRef.snapshots(),
              builder: (context, itemSnapshot) {
                if (itemSnapshot.hasError) {
                  return const Center(
                    child: Text('Artikel konnten nicht geladen werden.'),
                  );
                }

                if (!itemSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _ink),
                  );
                }

                final articles = itemSnapshot.data!.docs
                    .map((doc) => ArticleData.fromDoc(doc))
                    .where((item) => item.isActive)
                    .toList();

                final uncategorizedCount = articles
                    .where(
                      (item) => !categories.any(
                        (cat) => cat.id == item.categoryId,
                  ),
                )
                    .length;

                if (categories.isEmpty) {
                  return _EmptyCategories(onAdd: _addCategory);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroCard(
                        categoryCount: categories.length,
                        articleCount: articles.length,
                        uncategorizedCount: uncategorizedCount,
                        isSavingOrder: _isSavingOrder,
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final category = categories[index];

                          final itemCount = _countItemsForCategory(
                            categoryId: category.id,
                            articles: articles,
                          );

                          return _CategoryCard(
                            index: index,
                            category: category,
                            itemCount: itemCount,
                            isFirst: index == 0,
                            isLast: index == categories.length - 1,
                            onEdit: () => _editCategory(category),
                            onHide: () =>
                                _hideCategory(category, itemCount),
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
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/* DATA */

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

class ArticleData {
  final String id;
  final String categoryId;
  final bool isActive;

  const ArticleData({
    required this.id,
    required this.categoryId,
    required this.isActive,
  });

  factory ArticleData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return ArticleData(
      id: data['id']?.toString() ?? doc.id,
      categoryId: data['categoryId']?.toString() ?? '',
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

/* UI */

class _HeroCard extends StatelessWidget {
  final int categoryCount;
  final int articleCount;
  final int uncategorizedCount;
  final bool isSavingOrder;

  const _HeroCard({
    required this.categoryCount,
    required this.articleCount,
    required this.uncategorizedCount,
    required this.isSavingOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.category_rounded,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 18),
          Text(
            '$categoryCount Kategorien',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isSavingOrder
                ? 'Reihenfolge wird gespeichert...'
                : 'Sortiere dein Menü so, wie Kunden es sehen sollen.',
            style: const TextStyle(
              color: Color(0xFFD8D8D8),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(text: '$articleCount Artikel'),
              if (uncategorizedCount > 0)
                _HeroChip(
                  text: '$uncategorizedCount ohne Kategorie',
                  red: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String text;
  final bool red;

  const _HeroChip({
    required this.text,
    this.red = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: red ? const Color(0xFFD83A34) : Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final int index;
  final CategoryData category;
  final int itemCount;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onHide;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _CategoryCard({
    required this.index,
    required this.category,
    required this.itemCount,
    required this.isFirst,
    required this.isLast,
    required this.onEdit,
    required this.onHide,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFEFB),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE7E2D9)),
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
              Column(
                children: [
                  _MoveButton(
                    icon: Icons.keyboard_arrow_up_rounded,
                    onTap: isFirst ? null : onMoveUp,
                  ),
                  const SizedBox(height: 6),
                  _MoveButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: isLast ? null : onMoveDown,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEBE4),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category.description.isEmpty
                          ? 'Keine Beschreibung'
                          : category.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MiniChip(
                      text: '$itemCount Artikel',
                      gold: itemCount == 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF777777),
                    ),
                  ),
                  IconButton(
                    onPressed: onHide,
                    icon: const Icon(
                      Icons.visibility_off_rounded,
                      color: Color(0xFFD83A34),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MoveButton({
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
          color:
          disabled ? const Color(0xFFF1EFEA) : const Color(0xFFEEEBE4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color:
          disabled ? const Color(0xFFB8B8B8) : const Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String text;
  final bool gold;

  const _MiniChip({
    required this.text,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: gold ? const Color(0xFFFFF4D8) : const Color(0xFFEEEBE4),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: gold ? const Color(0xFF8A5A00) : const Color(0xFF1A1A1A),
          fontSize: 10.8,
          fontWeight: FontWeight.w900,
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
              size: 48,
              color: Color(0xFF777777),
            ),
            const SizedBox(height: 14),
            const Text(
              'Keine Kategorien',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Erstelle zuerst Kategorien wie Wraps, Bowls oder Getränke.',
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