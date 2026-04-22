import 'package:flutter/material.dart';
import 'editArticlePage.dart';

class MyArticlesPage extends StatefulWidget {
  const MyArticlesPage({super.key});

  @override
  State<MyArticlesPage> createState() => _MyArticlesPageState();
}

class _MyArticlesPageState extends State<MyArticlesPage> {
  String _selectedCategory = 'Wraps';

  final Map<String, List<Map<String, dynamic>>> _articlesByCategory = {
    'Wraps': [
      {
        'id': 'A-101',
        'name': 'Shawarma Wrap',
        'price': '8,50 €',
      },
      {
        'id': 'A-102',
        'name': 'Falafel Wrap',
        'price': '7,50 €',
      },
    ],
    'Bowls': [
      {
        'id': 'B-201',
        'name': 'Couscous Bowl',
        'price': '9,50 €',
      },
      {
        'id': 'B-202',
        'name': 'Mozzarella Bowl',
        'price': '9,00 €',
      },
    ],
    'Getränke': [
      {
        'id': 'C-301',
        'name': 'Cola',
        'price': '2,50 €',
      },
      {
        'id': 'C-302',
        'name': 'Ayran',
        'price': '2,00 €',
      },
    ],
  };

  List<Map<String, dynamic>> get _currentArticles =>
      _articlesByCategory[_selectedCategory] ?? [];

  void _addArticle() {
    setState(() {
      _currentArticles.add({
        'id': 'NEW-${_currentArticles.length + 1}',
        'name': 'Neuer Artikel',
        'price': '0,00 €',
      });
    });
  }

  void _editArticle(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_currentArticles[index]['name']} bearbeiten kommt später.'),
      ),
    );
  }

  void _deleteArticle(int index) {
    final articleName = _currentArticles[index]['name'];

    setState(() {
      _currentArticles.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$articleName gelöscht.'),
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
        title: const Text(
          'My Articles',
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
                'Hier verwaltest du die Artikel innerhalb einer Kategorie.',
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
                      'Kategorie wählen',
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
                          dropdownColor: const Color(0xFFFDFCF9),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: _articlesByCategory.keys.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _addArticle,
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
                          'Neuen Artikel hinzufügen',
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
              const SizedBox(height: 24),
              ...List.generate(_currentArticles.length, (index) {
                final article = _currentArticles[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ArticleCard(
                    articleId: article['id'],
                    articleName: article['name'],
                    price: article['price'],
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditArticlePage(
                            articleId: article['id'],
                            initialName: article['name'],
                            initialPrice: article['price'],
                            initialCategory: _selectedCategory,
                          ),
                        ),
                      );
                    },
                    onDelete: () => _deleteArticle(index),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final String articleId;
  final String articleName;
  final String price;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ArticleCard({
    required this.articleId,
    required this.articleName,
    required this.price,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  price,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A1A1A),
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Bearbeiten'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD83A34),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Löschen'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}