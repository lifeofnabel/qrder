import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'editArticlePage.dart';

class MyArticlesPage extends StatefulWidget {
  const MyArticlesPage({super.key});

  @override
  State<MyArticlesPage> createState() => _MyArticlesPageState();
}

class _MyArticlesPageState extends State<MyArticlesPage> {
  static const Color _bg = Color(0xFFF8F6F1);
  static const Color _card = Color(0xFFFFFEFB);
  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _muted = Color(0xFF777777);
  static const Color _soft = Color(0xFFEEEBE4);
  static const Color _line = Color(0xFFE7E2D9);
  static const Color _green = Color(0xFF2F5E1C);
  static const Color _red = Color(0xFFD83A34);
  static const Color _gold = Color(0xFFD8A75D);

  String? _selectedCategoryId;

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

  String _formatPrice(dynamic value) {
    if (value == null) return '0,00 €';

    final number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;

    return '${number.toStringAsFixed(2).replaceAll('.', ',')} €';
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

  void _addArticle(CategoryData category) {
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

  Future<void> _deactivateArticle(ArticleData article) async {
    final ref = _itemsRef;
    if (ref == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: _card,
          title: const Text('Artikel ausblenden?'),
          content: Text(
            '"${article.name}" wird nicht gelöscht, sondern nur deaktiviert.',
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Artikel ausgeblendet.')),
    );
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
          'Artikel',
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: _ink),
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

            if (categories.isEmpty) {
              return _EmptyState(
                icon: Icons.category_outlined,
                title: 'Keine Kategorien',
                text: 'Erstelle zuerst Kategorien wie Wraps, Bowls oder Getränke.',
                buttonText: null,
                onTap: null,
              );
            }

            final selectedExists = categories.any(
                  (category) => category.id == _selectedCategoryId,
            );

            if (_selectedCategoryId == null || !selectedExists) {
              _selectedCategoryId = categories.first.id;
            }

            final selectedCategory = categories.firstWhere(
                  (category) => category.id == _selectedCategoryId,
              orElse: () => categories.first,
            );

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: itemsRef
                  .where('categoryId', isEqualTo: selectedCategory.id)
                  .snapshots(),
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
                    .where((article) => article.isActive)
                    .toList()
                  ..sort((a, b) {
                    final aNumber = int.tryParse(a.articleNumber) ?? 999999;
                    final bNumber = int.tryParse(b.articleNumber) ?? 999999;

                    if (aNumber != bNumber) {
                      return aNumber.compareTo(bNumber);
                    }

                    return a.name.compareTo(b.name);
                  });

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopCard(
                        articleCount: articles.length,
                        categoryCount: categories.length,
                      ),
                      const SizedBox(height: 14),
                      _CategorySelector(
                        categories: categories,
                        selectedCategoryId: selectedCategory.id,
                        onChanged: (id) {
                          if (id == null) return;
                          setState(() => _selectedCategoryId = id);
                        },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => _addArticle(selectedCategory),
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
                            'Artikel hinzufügen',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (articles.isEmpty)
                        _EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'Keine Artikel',
                          text: 'In dieser Kategorie gibt es noch keine Artikel.',
                          buttonText: 'Ersten Artikel erstellen',
                          onTap: () => _addArticle(selectedCategory),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: articles.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final article = articles[index];

                            return _ArticleCard(
                              article: article,
                              priceText: _formatPrice(article.price),
                              originalPriceText:
                              article.originalPrice == null
                                  ? null
                                  : _formatPrice(article.originalPrice),
                              onEdit: () => _openEditArticle(
                                article: article,
                                categoryName: selectedCategory.name,
                              ),
                              onDelete: () => _deactivateArticle(article),
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

class CategoryData {
  final String id;
  final String name;
  final bool isActive;

  const CategoryData({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory CategoryData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return CategoryData(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'Ohne Name',
      isActive: data['isActive'] as bool? ?? true,
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
  final dynamic price;
  final dynamic originalPrice;
  final bool isActive;
  final bool isAvailable;
  final int optionGroupCount;

  const ArticleData({
    required this.docId,
    required this.id,
    required this.articleNumber,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.originalPrice,
    required this.isActive,
    required this.isAvailable,
    required this.optionGroupCount,
  });

  factory ArticleData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final rawGroups = data['optionGroups'] ?? data['selectionGroups'];
    final groupCount = rawGroups is List ? rawGroups.length : 0;

    return ArticleData(
      docId: doc.id,
      id: data['id']?.toString() ?? doc.id,
      articleNumber: data['articleNumber']?.toString() ?? '',
      name: data['name']?.toString() ??
          data['title']?.toString() ??
          'Ohne Name',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      price: data['price'],
      originalPrice: data['originalPrice'],
      isActive: data['isActive'] as bool? ?? true,
      isAvailable: data['isAvailable'] as bool? ?? true,
      optionGroupCount: groupCount,
    );
  }
}

class _TopCard extends StatelessWidget {
  final int articleCount;
  final int categoryCount;

  const _TopCard({
    required this.articleCount,
    required this.categoryCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color(0xFFFFFEFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFFE7E2D9)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Color(0xFFEEEBE4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$articleCount Artikel',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$categoryCount Kategorien · Optionen möglich',
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
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

class _CategorySelector extends StatelessWidget {
  final List<CategoryData> categories;
  final String selectedCategoryId;
  final ValueChanged<String?> onChanged;

  const _CategorySelector({
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = categories.any((category) => category.id == selectedCategoryId)
        ? selectedCategoryId
        : categories.first.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0DBD2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          dropdownColor: const Color(0xFFFFFEFB),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(
                category.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final ArticleData article;
  final String priceText;
  final String? originalPriceText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ArticleCard({
    required this.article,
    required this.priceText,
    required this.originalPriceText,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = article.imageUrl.trim().isNotEmpty;

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
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEBE4),
                  borderRadius: BorderRadius.circular(18),
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
                        color: Color(0xFF777777),
                        size: 30,
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
                            color: const Color(0xFF1A1A1A),
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
                        color: Color(0xFF1A1A1A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      article.description.isEmpty
                          ? 'Keine Beschreibung'
                          : article.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _MiniChip(
                          text: priceText,
                          dark: true,
                        ),
                        if (originalPriceText != null &&
                            originalPriceText != '0,00 €')
                          _MiniChip(
                            text: 'alt $originalPriceText',
                            gold: true,
                          ),
                        _MiniChip(
                          text: article.isAvailable ? 'verfügbar' : 'aus',
                          red: !article.isAvailable,
                        ),
                        if (article.optionGroupCount > 0)
                          _MiniChip(
                            text: '${article.optionGroupCount} Optionen',
                          ),
                      ],
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
                    onPressed: onDelete,
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

class _MiniChip extends StatelessWidget {
  final String text;
  final bool dark;
  final bool red;
  final bool gold;

  const _MiniChip({
    required this.text,
    this.dark = false,
    this.red = false,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFEEEBE4);
    Color fg = const Color(0xFF1A1A1A);

    if (dark) {
      bg = const Color(0xFF1A1A1A);
      fg = Colors.white;
    }

    if (red) {
      bg = const Color(0xFFF8E2E0);
      fg = const Color(0xFFD83A34);
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String? buttonText;
  final VoidCallback? onTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.text,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E2D9)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF777777), size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (buttonText != null && onTap != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(buttonText!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}