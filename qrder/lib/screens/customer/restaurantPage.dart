import 'package:flutter/material.dart';
import 'shoppingBasketPage.dart';

class RestaurantPage extends StatefulWidget {
  const RestaurantPage({super.key});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  String _selectedCategory = 'Alle';
  int _cartCount = 0;

  final List<String> _categories = [
    'Alle',
    'Wraps',
    'Bowls',
    'Getränke',
    'Menüs',
  ];

  final List<Map<String, dynamic>> _articles = [
    {
      'id': 'W101',
      'title': 'Hähnchenwrap',
      'price': 5.0,
      'category': 'Wraps',
      'hasOptions': true,
      'optionsTitle': 'Soße wählen',
      'options': ['Knoblauch', 'Scharf', 'Cocktail'],
      'requiresAddon': false,
    },
    {
      'id': 'W102',
      'title': 'Falafel Wrap',
      'price': 5.0,
      'category': 'Wraps',
      'hasOptions': true,
      'optionsTitle': 'Soße wählen',
      'options': ['Tahini', 'Scharf', 'Cocktail'],
      'requiresAddon': false,
    },
    {
      'id': 'B201',
      'title': 'Chicken Bowl',
      'price': 8.5,
      'category': 'Bowls',
      'hasOptions': true,
      'optionsTitle': 'Soße wählen',
      'options': ['Knoblauch', 'Scharf', 'Cocktail'],
      'requiresAddon': false,
    },
    {
      'id': 'G301',
      'title': 'Cola',
      'price': 2.5,
      'category': 'Getränke',
      'hasOptions': false,
      'requiresAddon': false,
    },
    {
      'id': 'M401',
      'title': 'Wrap Menü',
      'price': 9.0,
      'category': 'Menüs',
      'hasOptions': true,
      'optionsTitle': 'Wrap wählen',
      'options': ['Hähnchenwrap', 'Falafel Wrap', 'Halloumi Wrap'],
      'requiresAddon': true,
      'addonTitle': 'Side wählen',
      'addons': ['Pommes', 'Süßkartoffel'],
    },
  ];

  List<Map<String, dynamic>> get _filteredArticles {
    if (_selectedCategory == 'Alle') return _articles;
    return _articles
        .where((article) => article['category'] == _selectedCategory)
        .toList();
  }

  void _addSimpleToCart(Map<String, dynamic> article) {
    setState(() {
      _cartCount++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${article['title']} wurde zum Korb hinzugefügt.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _handleAddToCart(Map<String, dynamic> article) async {
    final bool hasOptions = article['hasOptions'] == true;
    final bool requiresAddon = article['requiresAddon'] == true;

    if (!hasOptions && !requiresAddon) {
      _addSimpleToCart(article);
      return;
    }

    String? selectedOption;
    String? selectedAddon;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFDFCF9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<String> options =
                (article['options'] as List?)?.cast<String>() ?? [];
            final List<String> addons =
                (article['addons'] as List?)?.cast<String>() ?? [];

            final bool canAdd =
                (!hasOptions || selectedOption != null) &&
                    (!requiresAddon || selectedAddon != null);

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D3C9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    article['title'],
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${article['price']} €',
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (hasOptions) ...[
                    Text(
                      article['optionsTitle'] ?? 'Option wählen',
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...options.map(
                          (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ChoiceTile(
                          title: option,
                          selected: selectedOption == option,
                          onTap: () {
                            setModalState(() {
                              selectedOption = option;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (requiresAddon) ...[
                    Text(
                      article['addonTitle'] ?? 'Zusatz wählen',
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...addons.map(
                          (addon) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ChoiceTile(
                          title: addon,
                          selected: selectedAddon == addon,
                          onTap: () {
                            setModalState(() {
                              selectedAddon = addon;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: canAdd
                          ? () {
                        Navigator.pop(context);
                        _addSimpleToCart(article);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFBEB8AE),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Zum Korb hinzufügen',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
    );
  }

  void _openBasket() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShoppingBasketPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final articles = _filteredArticles;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F1),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Column(
          children: const [
            Text(
              'Babel Imbiss',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'powered by Qrder',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final selected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF1A1A1A)
                                    : const Color(0xFFEEEBE4),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF555555),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: articles.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.74,
                    ),
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return _RestaurantArticleCard(
                        articleId: article['id'],
                        title: article['title'],
                        price: article['price'].toString(),
                        onAdd: () => _handleAddToCart(article),
                      );
                    },
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _openBasket,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shopping_basket_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$_cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantArticleCard extends StatelessWidget {
  final String articleId;
  final String title;
  final String price;
  final VoidCallback onAdd;

  const _RestaurantArticleCard({
    required this.articleId,
    required this.title,
    required this.price,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE7E2D9),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEBE4),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 38,
                      color: Color(0xFF777777),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$price €',
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
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

class _ChoiceTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1A1A1A)
              : const Color(0xFFF3F0E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF1A1A1A),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}