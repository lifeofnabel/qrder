import 'package:flutter/material.dart';
import '../admin/orderPage.dart';
import 'qrCodePage.dart';

class ShoppingBasketPage extends StatefulWidget {
  const ShoppingBasketPage({super.key});

  @override
  State<ShoppingBasketPage> createState() => _ShoppingBasketPageState();
}

class _ShoppingBasketPageState extends State<ShoppingBasketPage> {
  final TextEditingController _wishController = TextEditingController();

  String _orderType = 'Vor Ort';

  final List<Map<String, dynamic>> _basketItems = [
    {
      'id': 'W101',
      'title': 'Hähnchenwrap',
      'price': 5.0,
      'details': ['Soße: Knoblauch', 'Brot: Standard'],
    },
    {
      'id': 'M401',
      'title': 'Wrap Menü',
      'price': 9.0,
      'details': ['Wrap: Hähnchenwrap', 'Side: Pommes', 'Getränk: Cola'],
    },
    {
      'id': 'G301',
      'title': 'Ayran',
      'price': 2.0,
      'details': [],
    },
  ];

  @override
  void dispose() {
    _wishController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    double total = 0;
    for (final item in _basketItems) {
      total += (item['price'] as num).toDouble();
    }
    return total;
  }

  void _removeItem(int index) {
    final articleName = _basketItems[index]['title'];

    setState(() {
      _basketItems.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$articleName entfernt.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openOrderDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderPage(
          orderCode: 'BASKET-PREVIEW',
          customerName: 'Demo Kunde',
          tableOrType: _orderType,
          orderItems: _basketItems.map((item) {
            final title = item['title'] as String;
            final details = (item['details'] as List).cast<String>();
            if (details.isEmpty) return title;
            return '$title\n- ${details.join('\n- ')}';
          }).toList(),
          totalPrice: '${_totalPrice.toStringAsFixed(2)} €',
        ),
      ),
    );
  }

  void _goToQrCodePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QrCodePage(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isEmpty = _basketItems.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F1),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Warenkorb',
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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hier siehst du alle ausgewählten Artikel, kannst Wünsche ergänzen und dann weiter zum QR-Code gehen.',
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),

              if (isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFCF9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE7E2D9),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Dein Warenkorb ist aktuell leer.',
                    style: TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                ...List.generate(_basketItems.length, (index) {
                  final item = _basketItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _BasketItemCard(
                      articleId: item['id'],
                      title: item['title'],
                      price: item['price'].toDouble(),
                      details: (item['details'] as List).cast<String>(),
                      onDelete: () => _removeItem(index),
                    ),
                  );
                }),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bestellart',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _OrderTypeButton(
                            title: 'Vor Ort',
                            selected: _orderType == 'Vor Ort',
                            onTap: () {
                              setState(() {
                                _orderType = 'Vor Ort';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OrderTypeButton(
                            title: 'Mitnehmen',
                            selected: _orderType == 'Mitnehmen',
                            onTap: () {
                              setState(() {
                                _orderType = 'Mitnehmen';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Wunschtext',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _wishController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'z. B. ohne Zwiebeln, extra knusprig, bitte schnell ...',
                        hintStyle: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF3F0E9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0DBD2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0DBD2),
                          ),
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
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Gesamtsumme',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_totalPrice.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isEmpty ? null : _goToQrCodePage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F5E1C),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFAAB79F),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Weiter zum QR-Code',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const SizedBox(height: 12),

            ],
          ),
        ),
      ),
    );
  }
}

class _BasketItemCard extends StatelessWidget {
  final String articleId;
  final String title;
  final double price;
  final List<String> details;
  final VoidCallback onDelete;

  const _BasketItemCard({
    required this.articleId,
    required this.title,
    required this.price,
    required this.details,
    required this.onDelete,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontWeight: FontWeight.w700,
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
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${price.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...details.map(
                        (detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $detail',
                        style: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFD83A34),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTypeButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _OrderTypeButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1A1A1A)
              : const Color(0xFFEEEBE4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF555555),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}