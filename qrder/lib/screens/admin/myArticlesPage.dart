import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'underPages/editArticlePage.dart';

const Color _bg = Color(0xFFF8F6F1);
const Color _card = Color(0xFFFFFEFB);
const Color _ink = Color(0xFF1A1A1A);
const Color _muted = Color(0xFF777777);
const Color _soft = Color(0xFFEEEBE4);
const Color _line = Color(0xFFE7E2D9);
const Color _green = Color(0xFF1A1A1A);
const Color _red = Color(0xFFD83A34);
const Color _gold = Color(0xFFD8A75D);

class MyArticlesPage extends StatefulWidget {
  const MyArticlesPage({super.key});

  @override
  State<MyArticlesPage> createState() => _MyArticlesPageState();
}

class _MyArticlesPageState extends State<MyArticlesPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategoryId = 'all';
  String _selectedStatus = 'all';
  String _searchText = '';

  String? get _merchantId => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _merchantRef {
    final merchantId = _merchantId;
    if (merchantId == null) return null;
    return FirebaseFirestore.instance.collection('merchants').doc(merchantId);
  }

  CollectionReference<Map<String, dynamic>>? get _categoriesRef {
    return _merchantRef?.collection('itemCategories');
  }

  CollectionReference<Map<String, dynamic>>? get _itemsRef {
    return _merchantRef?.collection('items');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0,00 €';

    final number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;

    return '${number.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  List<ArticleData> _filterArticles(List<ArticleData> articles) {
    var filtered = articles;

    if (_selectedCategoryId != 'all') {
      filtered = filtered
          .where((article) => article.categoryId == _selectedCategoryId)
          .toList();
    }

    if (_selectedStatus == 'available') {
      filtered = filtered.where((article) => article.isAvailable).toList();
    }

    if (_selectedStatus == 'unavailable') {
      filtered = filtered.where((article) => !article.isAvailable).toList();
    }

    if (_selectedStatus == 'options') {
      filtered = filtered.where((article) => article.optionGroupCount > 0).toList();
    }

    if (_selectedStatus == 'menu') {
      filtered = filtered.where((article) => article.isMenuItem).toList();
    }

    final search = _searchText.trim().toLowerCase();

    if (search.isNotEmpty) {
      filtered = filtered.where((article) {
        final haystack = [
          article.name,
          article.articleNumber,
          article.description,
          article.categoryName,
          ...article.tags,
        ].join(' ').toLowerCase();

        return haystack.contains(search);
      }).toList();
    }

    return filtered;
  }

  Future<CategoryData> _createDefaultCategory() async {
    final ref = _categoriesRef;

    if (ref == null) {
      throw Exception('Kein Händler gefunden.');
    }

    final doc = ref.doc();

    await doc.set({
      'id': doc.id,
      'name': 'Allgemein',
      'description': '',
      'sortOrder': 1,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return CategoryData(
      id: doc.id,
      name: 'Allgemein',
      isActive: true,
      sortOrder: 1,
    );
  }

  Future<void> _addArticle({
    required List<CategoryData> categories,
  }) async {
    CategoryData category;

    if (categories.isEmpty) {
      category = await _createDefaultCategory();
    } else {
      category = _selectedCategoryId == 'all'
          ? categories.first
          : categories.firstWhere(
            (cat) => cat.id == _selectedCategoryId,
        orElse: () => categories.first,
      );
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditArticlePage(
          articleId: '',
          initialName: '',
          initialPrice: '',
          initialCategory: category.name,
        ),
      ),
    );
  }

  void _openEditArticle({
    required ArticleData article,
    required String categoryName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditArticlePage(
          articleId: article.docId,
          initialName: article.name,
          initialPrice: _formatPrice(article.price),
          initialCategory: categoryName,
        ),
      ),
    );
  }

  Future<void> _deactivateArticle(ArticleData article) async {
    final ref = _itemsRef;
    if (ref == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Artikel ausblenden?',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '"${article.name}" wird nicht endgültig gelöscht, sondern nur deaktiviert.',
            style: const TextStyle(
              color: _muted,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
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

    await ref.doc(article.docId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Artikel ausgeblendet.')),
      );
  }

  Future<void> _toggleAvailability(ArticleData article) async {
    final ref = _itemsRef;
    if (ref == null) return;

    await ref.doc(article.docId).update({
      'isAvailable': !article.isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _duplicateArticle(ArticleData article) async {
    final ref = _itemsRef;
    if (ref == null) return;

    final newDoc = ref.doc();

    await newDoc.set({
      ...article.rawData,
      'id': newDoc.id,
      'name': '${article.name} Kopie',
      'title': '${article.name} Kopie',
      'articleNumber': '',
      'sortOrder': DateTime.now().millisecondsSinceEpoch,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Artikel kopiert.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesRef = _categoriesRef;
    final itemsRef = _itemsRef;

    return Scaffold(
      backgroundColor: _bg,
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

            final categoryStillExists = _selectedCategoryId == 'all' ||
                categories.any((cat) => cat.id == _selectedCategoryId);

            if (!categoryStillExists) {
              _selectedCategoryId = 'all';
            }

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

                final allArticles = itemSnapshot.data!.docs
                    .map((doc) => ArticleData.fromDoc(doc))
                    .where((article) => article.isActive)
                    .toList()
                  ..sort((a, b) {
                    final aNumber =
                        int.tryParse(a.articleNumber) ?? 999999;
                    final bNumber =
                        int.tryParse(b.articleNumber) ?? 999999;

                    if (aNumber != bNumber) {
                      return aNumber.compareTo(bNumber);
                    }

                    return a.name.compareTo(b.name);
                  });

                final filteredArticles = _filterArticles(allArticles);

                final availableCount =
                    allArticles.where((a) => a.isAvailable).length;
                final unavailableCount = allArticles.length - availableCount;
                final optionCount =
                    allArticles.where((a) => a.optionGroupCount > 0).length;
                final menuCount =
                    allArticles.where((a) => a.isMenuItem).length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopBar(
                        onBack: () => Navigator.pop(context),
                        onAdd: () => _addArticle(categories: categories),
                      ),

                      const SizedBox(height: 18),

                      _HeroCard(
                        totalCount: allArticles.length,
                        availableCount: availableCount,
                        unavailableCount: unavailableCount,
                        optionCount: optionCount,
                        menuCount: menuCount,
                      ),

                      const SizedBox(height: 14),

                      _FilterBox(
                        categories: categories,
                        selectedCategoryId: _selectedCategoryId,
                        selectedStatus: _selectedStatus,
                        searchController: _searchController,
                        onCategoryChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedCategoryId = value);
                        },
                        onStatusChanged: (value) {
                          setState(() => _selectedStatus = value);
                        },
                        onSearchChanged: (value) {
                          setState(() => _searchText = value);
                        },
                      ),

                      const SizedBox(height: 14),

                      _QuickAddBox(
                        onAddArticle: () => _addArticle(categories: categories),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Text(
                            '${filteredArticles.length} angezeigt',
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          if (_searchText.isNotEmpty ||
                              _selectedCategoryId != 'all' ||
                              _selectedStatus != 'all')
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchText = '';
                                  _selectedCategoryId = 'all';
                                  _selectedStatus = 'all';
                                });
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('Filter zurücksetzen'),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      if (filteredArticles.isEmpty)
                        EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'Keine Artikel',
                          text: allArticles.isEmpty
                              ? 'Lege deinen ersten Artikel an.'
                              : 'Für diese Auswahl gibt es keine Artikel.',
                          buttonText: 'Artikel hinzufügen',
                          onTap: () => _addArticle(categories: categories),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredArticles.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final article = filteredArticles[index];

                            final categoryName = categories
                                .firstWhere(
                                  (cat) => cat.id == article.categoryId,
                              orElse: () => CategoryData(
                                id: article.categoryId,
                                name: article.categoryName.isEmpty
                                    ? 'Kategorie'
                                    : article.categoryName,
                                isActive: true,
                                sortOrder: 999999,
                              ),
                            )
                                .name;

                            return ArticleCard(
                              article: article,
                              priceText: _formatPrice(article.price),
                              originalPriceText:
                              article.originalPrice == null
                                  ? null
                                  : _formatPrice(article.originalPrice),
                              onEdit: () => _openEditArticle(
                                article: article,
                                categoryName: categoryName,
                              ),
                              onDelete: () => _deactivateArticle(article),
                              onToggleAvailability: () =>
                                  _toggleAvailability(article),
                            );
                          },
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
  final bool isActive;
  final int sortOrder;

  const CategoryData({
    required this.id,
    required this.name,
    required this.isActive,
    required this.sortOrder,
  });

  factory CategoryData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return CategoryData(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'Ohne Name',
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] as int : 999999,
    );
  }
}

class ArticleData {
  final String docId;
  final String id;
  final String articleNumber;
  final String name;
  final String description;
  final String imageUrl;
  final String categoryId;
  final String categoryName;
  final dynamic price;
  final dynamic originalPrice;
  final bool isActive;
  final bool isAvailable;
  final bool isMenuItem;
  final int optionGroupCount;
  final List<String> tags;
  final Map<String, dynamic> rawData;

  const ArticleData({
    required this.docId,
    required this.id,
    required this.articleNumber,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.originalPrice,
    required this.isActive,
    required this.isAvailable,
    required this.isMenuItem,
    required this.optionGroupCount,
    required this.tags,
    required this.rawData,
  });

  factory ArticleData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final rawGroups = data['optionGroups'] ?? data['selectionGroups'];
    final groupCount = rawGroups is List ? rawGroups.length : 0;

    final rawTags = data['tags'];
    final tags = rawTags is List
        ? rawTags
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList()
        : <String>[];

    final categoryName = data['categoryName']?.toString() ?? '';

    final name =
        data['name']?.toString() ?? data['title']?.toString() ?? 'Ohne Name';

    final isMenu = data['isMenuItem'] as bool? ??
        categoryName.toLowerCase().contains('menü') ||
            categoryName.toLowerCase().contains('menu') ||
            name.toLowerCase().contains('menü') ||
            name.toLowerCase().contains('menu');

    return ArticleData(
      docId: doc.id,
      id: data['id']?.toString() ?? doc.id,
      articleNumber: data['articleNumber']?.toString() ?? '',
      name: name,
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      categoryId: data['categoryId']?.toString() ?? '',
      categoryName: categoryName,
      price: data['price'],
      originalPrice: data['originalPrice'],
      isActive: data['isActive'] as bool? ?? true,
      isAvailable: data['isAvailable'] as bool? ?? true,
      isMenuItem: isMenu,
      optionGroupCount: groupCount,
      tags: tags,
      rawData: data,
    );
  }
}

/* UI */

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onAdd;

  const _TopBar({
    required this.onBack,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: _soft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Artikel',
            style: TextStyle(
              color: _ink,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
        IconButton(
          onPressed: onAdd,
          style: IconButton.styleFrom(
            backgroundColor: _ink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int totalCount;
  final int availableCount;
  final int unavailableCount;
  final int optionCount;
  final int menuCount;

  const _HeroCard({
    required this.totalCount,
    required this.availableCount,
    required this.unavailableCount,
    required this.optionCount,
    required this.menuCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(30),
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
            Icons.restaurant_menu_rounded,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(height: 18),
          Text(
            '$totalCount Artikel',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Preise, Bilder, Kategorien, Menüs und Auswahloptionen pflegen.',
            style: TextStyle(
              color: Color(0xFFD8D8D8),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 17),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HeroChip(text: '$availableCount verfügbar'),
              HeroChip(text: '$unavailableCount aus'),
              HeroChip(text: '$optionCount mit Optionen'),
              HeroChip(text: '$menuCount Menüs'),
            ],
          ),
        ],
      ),
    );
  }
}

class HeroChip extends StatelessWidget {
  final String text;

  const HeroChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
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

class _FilterBox extends StatelessWidget {
  final List<CategoryData> categories;
  final String selectedCategoryId;
  final String selectedStatus;
  final TextEditingController searchController;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSearchChanged;

  const _FilterBox({
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedStatus,
    required this.searchController,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = selectedCategoryId == 'all' ||
        categories.any((cat) => cat.id == selectedCategoryId)
        ? selectedCategoryId
        : 'all';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suchen & filtern',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Artikel suchen...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: _soft,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(color: Color(0xFFE0DBD2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(color: Color(0xFFE0DBD2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: _ink,
                  width: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFE0DBD2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: safeValue,
                isExpanded: true,
                dropdownColor: _card,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: [
                  const DropdownMenuItem<String>(
                    value: 'all',
                    child: Text(
                      'Alle Kategorien',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  ...categories.map(
                        (category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(
                        category.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
                onChanged: onCategoryChanged,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                StatusFilterChip(
                  label: 'Alle',
                  value: 'all',
                  selectedValue: selectedStatus,
                  onTap: onStatusChanged,
                ),
                StatusFilterChip(
                  label: 'Verfügbar',
                  value: 'available',
                  selectedValue: selectedStatus,
                  onTap: onStatusChanged,
                ),
                StatusFilterChip(
                  label: 'Aus',
                  value: 'unavailable',
                  selectedValue: selectedStatus,
                  onTap: onStatusChanged,
                ),
                StatusFilterChip(
                  label: 'Optionen',
                  value: 'options',
                  selectedValue: selectedStatus,
                  onTap: onStatusChanged,
                ),
                StatusFilterChip(
                  label: 'Menüs',
                  value: 'menu',
                  selectedValue: selectedStatus,
                  onTap: onStatusChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatusFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onTap;

  const StatusFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? _ink : _soft,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? _ink : _line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddBox extends StatelessWidget {
  final VoidCallback onAddArticle;

  const _QuickAddBox({
    required this.onAddArticle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onAddArticle,
        style: ElevatedButton.styleFrom(
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Artikel hinzufügen',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class ArticleCard extends StatelessWidget {
  final ArticleData article;
  final String priceText;
  final String? originalPriceText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const ArticleCard({
    super.key,
    required this.article,
    required this.priceText,
    required this.originalPriceText,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = article.imageUrl.trim().isNotEmpty;

    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: article.isAvailable ? _line : const Color(0xFFF1B1AC),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: hasImage
                          ? Image.network(
                        article.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_outlined),
                      )
                          : const Icon(
                        Icons.image_outlined,
                        color: _muted,
                        size: 32,
                      ),
                    ),
                    if (article.articleNumber.isNotEmpty)
                      Positioned(
                        left: 7,
                        bottom: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _ink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article.articleNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.categoryName.isEmpty
                          ? 'Ohne Kategorie'
                          : article.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (article.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        article.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        MiniChip(text: priceText, dark: true),
                        if (originalPriceText != null &&
                            originalPriceText != '0,00 €')
                          MiniChip(text: 'alt $originalPriceText', gold: true),
                        MiniChip(
                          text: article.isAvailable ? 'verfügbar' : 'aus',
                          red: !article.isAvailable,
                          green: article.isAvailable,
                        ),
                        if (article.isMenuItem) const MiniChip(text: 'Menü'),
                        if (article.optionGroupCount > 0)
                          MiniChip(text: '${article.optionGroupCount} Optionen'),
                        ...article.tags.take(2).map((tag) => MiniChip(text: tag)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ink,
                              side: const BorderSide(color: Color(0xFFE0DBD2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            icon: const Icon(Icons.edit_rounded, size: 17),
                            label: const Text(
                              'Bearbeiten',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _MiniIconButton(
                          icon: article.isAvailable
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: article.isAvailable ? _green : _red,
                          onTap: onToggleAvailability,
                        ),
                        _MiniIconButton(
                          icon: Icons.delete_outline_rounded,
                          color: _red,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
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
  final Color color;
  final VoidCallback onTap;

  const _MiniIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 21),
    );
  }
}

class MiniChip extends StatelessWidget {
  final String text;
  final bool dark;
  final bool red;
  final bool green;
  final bool gold;

  const MiniChip({
    super.key,
    required this.text,
    this.dark = false,
    this.red = false,
    this.green = false,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = _soft;
    Color fg = _ink;

    if (dark) {
      bg = _ink;
      fg = Colors.white;
    }

    if (red) {
      bg = const Color(0xFFF8E2E0);
      fg = _red;
    }

    if (green) {
      bg = const Color(0xFFEAF7EF);
      fg = _green;
    }

    if (gold) {
      bg = const Color(0xFFFFF4D8);
      fg = const Color(0xFF8A5A00);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String? buttonText;
  final VoidCallback? onTap;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.buttonText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 46, color: _muted),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (buttonText != null && onTap != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  buttonText!,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

