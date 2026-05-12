import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'qrCodePage.dart';

const Color _bg = Color(0xFFF8F6F1);
const Color _card = Color(0xFFFFFEFB);
const Color _ink = Color(0xFF1A1A1A);
const Color _muted = Color(0xFF777777);
const Color _soft = Color(0xFFEEEBE4);
const Color _line = Color(0xFFE7E2D9);
const Color _gold = Color(0xFFD8A75D);
const Color _green = Color(0xFF2E9E5B);
const Color _red = Color(0xFFD83A34);

class ShoppingBasketPage extends StatefulWidget {
  const ShoppingBasketPage({
    super.key,
    required this.merchantId,
    required this.cartItems,
  });

  final String merchantId;
  final List<dynamic> cartItems;

  @override
  State<ShoppingBasketPage> createState() => _ShoppingBasketPageState();
}

class _ShoppingBasketPageState extends State<ShoppingBasketPage> {
  final TextEditingController _wishController = TextEditingController();

  String _orderType = 'Vor Ort';
  String? _selectedTableId;
  String? _selectedTableLabel;

  bool _isSubmittingQr = false;
  bool _isSubmittingReal = false;

  late List<_BasketItemData> _items;

  DocumentReference<Map<String, dynamic>> get _merchantRef {
    return FirebaseFirestore.instance
        .collection('merchants')
        .doc(widget.merchantId);
  }

  CollectionReference<Map<String, dynamic>> get _tablesRef {
    return _merchantRef.collection('tables');
  }

  @override
  void initState() {
    super.initState();

    _items = widget.cartItems
        .map((item) => _BasketItemData.fromDynamic(item))
        .where((item) => item.title.trim().isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _wishController.dispose();
    super.dispose();
  }

  num get _totalPrice {
    return _items.fold<num>(0, (sum, item) => sum + item.totalPrice);
  }

  int get _totalQuantity {
    return _items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  String _formatPrice(num value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  void _removeItem(int index) {
    final title = _items[index].title;

    setState(() {
      _items.removeAt(index);
    });

    _showSnack('$title entfernt.');
  }

  void _showSnack(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  String _merchantNameFrom(Map<String, dynamic> data) {
    final shopName = data['shopName']?.toString().trim() ?? '';
    final name = data['name']?.toString().trim() ?? '';
    final businessName = data['businessName']?.toString().trim() ?? '';

    if (shopName.isNotEmpty) return shopName;
    if (name.isNotEmpty) return name;
    if (businessName.isNotEmpty) return businessName;

    return 'Restaurant';
  }

  String _googleMapsFrom(Map<String, dynamic> data) {
    final googleMaps = data['googleMaps']?.toString().trim() ?? '';
    final googleMapsUrl = data['googleMapsUrl']?.toString().trim() ?? '';

    if (googleMaps.isNotEmpty) return googleMaps;
    if (googleMapsUrl.isNotEmpty) return googleMapsUrl;

    return '';
  }

  Future<void> _submitOrder({
    required bool realOrder,
    required Map<String, dynamic> merchantData,
  }) async {
    if (_items.isEmpty) {
      _showSnack('Dein Warenkorb ist leer.');
      return;
    }

    if (realOrder && _selectedTableLabel == null) {
      _showSnack('Bitte zuerst einen Tisch / Platz auswählen.');
      return;
    }

    setState(() {
      if (realOrder) {
        _isSubmittingReal = true;
      } else {
        _isSubmittingQr = true;
      }
    });

    try {
      final restaurantName = _merchantNameFrom(merchantData);
      final logoUrl = merchantData['logoUrl']?.toString() ?? '';
      final googleMapsUrl = _googleMapsFrom(merchantData);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QrCodePage(
            merchantId: widget.merchantId,
            restaurantName: restaurantName,
            merchantLogoUrl: logoUrl,
            googleMapsUrl: googleMapsUrl,
            orderMode: realOrder ? 'real' : 'qr',
            orderType: _orderType,
            tableId: realOrder ? _selectedTableId : null,
            tableName: realOrder ? _selectedTableLabel : null,
            customerNote: _wishController.text.trim(),
            totalPrice: _totalPrice,
            items: _items.map((item) => item.toMap()).toList(),
          ),
        ),
      );
    } catch (_) {
      _showSnack('Bestellung konnte nicht vorbereitet werden.');
    }

    if (mounted) {
      setState(() {
        _isSubmittingQr = false;
        _isSubmittingReal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _items.isEmpty;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _merchantRef.snapshots(),
          builder: (context, merchantSnapshot) {
            if (merchantSnapshot.hasError) {
              return const _CenterMessage(
                text: 'Restaurantdaten konnten nicht geladen werden.',
              );
            }

            if (!merchantSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _ink),
              );
            }

            final merchantData = merchantSnapshot.data?.data() ?? {};

            final isActive = merchantData['isActive'] as bool? ?? true;
            final qrCodeOrder =
                (merchantData['qrCodeOrder'] as bool? ?? false) && isActive;
            final realOrder =
                (merchantData['realOrder'] as bool? ?? false) && isActive;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _tablesRef.snapshots(),
              builder: (context, tableSnapshot) {
                final tables = (tableSnapshot.data?.docs ?? [])
                    .map((doc) => _TableData.fromDoc(doc))
                    .where((table) => table.label.trim().isNotEmpty)
                    .toList()
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                if (_selectedTableId != null &&
                    !tables.any((table) => table.id == _selectedTableId)) {
                  _selectedTableId = null;
                  _selectedTableLabel = null;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topBar(context),

                      const SizedBox(height: 22),

                      const Text(
                        'Warenkorb',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.9,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Prüfe deine Bestellung. Danach kannst du sie per QR-Code zeigen oder direkt senden.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 14.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 18),

                      if (!isActive) ...[
                        const _ClosedNotice(),
                        const SizedBox(height: 14),
                      ],

                      if (isEmpty)
                        const _EmptyBasketCard()
                      else
                        ...List.generate(_items.length, (index) {
                          final item = _items[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BasketItemCard(
                              item: item,
                              onDelete: () => _removeItem(index),
                            ),
                          );
                        }),

                      const SizedBox(height: 8),

                      _SectionCard(
                        title: 'Bestellart',
                        subtitle: 'Wie möchtest du bestellen?',
                        child: Row(
                          children: [
                            Expanded(
                              child: _OrderTypeButton(
                                title: 'Vor Ort',
                                icon: Icons.storefront_rounded,
                                selected: _orderType == 'Vor Ort',
                                onTap: () {
                                  setState(() {
                                    _orderType = 'Vor Ort';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _OrderTypeButton(
                                title: 'Mitnehmen',
                                icon: Icons.shopping_bag_outlined,
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
                      ),

                      const SizedBox(height: 14),

                      if (realOrder)
                        _SectionCard(
                          title: 'Tisch / Platz',
                          subtitle:
                          'Für direkte Bestellung muss das Restaurant wissen, wo du sitzt.',
                          child: _TableDropdown(
                            tables: tables,
                            value: _selectedTableId,
                            onChanged: (table) {
                              setState(() {
                                _selectedTableId = table?.id;
                                _selectedTableLabel = table?.label;
                              });
                            },
                          ),
                        ),

                      if (realOrder) const SizedBox(height: 14),

                      _SectionCard(
                        title: 'Wunschtext',
                        subtitle: 'Optional. Zum Beispiel: ohne Zwiebeln.',
                        child: TextField(
                          controller: _wishController,
                          minLines: 3,
                          maxLines: 5,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText:
                            'z. B. ohne Zwiebeln, extra scharf, getrennt einpacken ...',
                            hintStyle: const TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: _soft,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: _line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: _line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: _ink,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _TotalCard(
                        totalQuantity: _totalQuantity,
                        totalPrice: _formatPrice(_totalPrice),
                      ),

                      const SizedBox(height: 16),

                      if (!qrCodeOrder && !realOrder) ...[
                        const _DemoOnlyNotice(),
                        const SizedBox(height: 14),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: _SubmitButton(
                              title: 'QR-Code',
                              subtitle: 'An Kasse zeigen',
                              icon: Icons.qr_code_2_rounded,
                              enabled: !isEmpty && qrCodeOrder,
                              loading: _isSubmittingQr,
                              onTap: () => _submitOrder(
                                realOrder: false,
                                merchantData: merchantData,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SubmitButton(
                              title: 'Direkt senden',
                              subtitle: 'Zum Tablet',
                              icon: Icons.send_rounded,
                              enabled: !isEmpty &&
                                  realOrder &&
                                  _selectedTableId != null,
                              loading: _isSubmittingReal,
                              onTap: () => _submitOrder(
                                realOrder: true,
                                merchantData: merchantData,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (realOrder && _selectedTableId == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'Für „Direkt senden“ bitte zuerst einen Tisch / Platz auswählen.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
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

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: _soft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _ink,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            'Qrder',
            style: TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

/* DATA */

class _BasketItemData {
  final String itemId;
  final String articleNumber;
  final String title;
  final num basePrice;
  final num singlePrice;
  final int quantity;
  final List<String> details;

  const _BasketItemData({
    required this.itemId,
    required this.articleNumber,
    required this.title,
    required this.basePrice,
    required this.singlePrice,
    required this.quantity,
    required this.details,
  });

  num get totalPrice => singlePrice * quantity;

  factory _BasketItemData.fromDynamic(dynamic raw) {
    try {
      final selectedOptions = raw.selectedOptions as List<dynamic>;

      final details = selectedOptions
          .map((option) {
        final groupTitle = option.groupTitle?.toString() ?? '';
        final optionName = option.optionName?.toString() ?? '';
        final price = option.price is num ? option.price as num : 0;

        final priceText = price > 0
            ? ' (+${price.toStringAsFixed(2).replaceAll('.', ',')} €)'
            : '';

        if (groupTitle.isEmpty) return '$optionName$priceText';
        return '$groupTitle: $optionName$priceText';
      })
          .where((text) => text.trim().isNotEmpty)
          .toList();

      final singlePrice = raw.singlePrice is num
          ? raw.singlePrice as num
          : raw.totalPrice is num
          ? raw.totalPrice as num
          : 0;

      return _BasketItemData(
        itemId: raw.itemId?.toString() ?? '',
        articleNumber: raw.articleNumber?.toString() ?? '',
        title: raw.title?.toString() ?? '',
        basePrice: raw.basePrice is num ? raw.basePrice as num : 0,
        singlePrice: singlePrice,
        quantity: raw.quantity is int ? raw.quantity as int : 1,
        details: details,
      );
    } catch (_) {
      if (raw is Map) {
        final rawDetails = raw['details'] ?? raw['selectedOptions'];

        return _BasketItemData(
          itemId: raw['id']?.toString() ?? raw['itemId']?.toString() ?? '',
          articleNumber: raw['articleNumber']?.toString() ?? '',
          title: raw['title']?.toString() ?? raw['name']?.toString() ?? '',
          basePrice: raw['basePrice'] is num ? raw['basePrice'] as num : 0,
          singlePrice: raw['singlePrice'] is num
              ? raw['singlePrice'] as num
              : raw['totalPrice'] is num
              ? raw['totalPrice'] as num
              : raw['price'] is num
              ? raw['price'] as num
              : 0,
          quantity: raw['quantity'] is int ? raw['quantity'] as int : 1,
          details: rawDetails is List
              ? rawDetails.map((e) {
            if (e is Map) {
              final group = e['groupTitle']?.toString() ?? '';
              final option = e['optionName']?.toString() ??
                  e['name']?.toString() ??
                  '';
              if (group.isEmpty) return option;
              return '$group: $option';
            }
            return e.toString();
          }).toList()
              : [],
        );
      }

      return const _BasketItemData(
        itemId: '',
        articleNumber: '',
        title: '',
        basePrice: 0,
        singlePrice: 0,
        quantity: 1,
        details: [],
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'articleNumber': articleNumber,
      'title': title,
      'basePrice': basePrice,
      'singlePrice': singlePrice,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'details': details,
    };
  }
}

class _TableData {
  final String id;
  final String label;
  final int sortOrder;

  const _TableData({
    required this.id,
    required this.label,
    required this.sortOrder,
  });

  factory _TableData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final label = data['label']?.toString() ??
        data['name']?.toString() ??
        data['title']?.toString() ??
        data['bezeichnung']?.toString() ??
        data['Bezeichnung']?.toString() ??
        doc.id;

    final rawSort = data['sortOrder'];

    return _TableData(
      id: doc.id,
      label: label,
      sortOrder: rawSort is int ? rawSort : 999999,
    );
  }
}

/* UI */

class _CenterMessage extends StatelessWidget {
  final String text;

  const _CenterMessage({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _muted,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ClosedNotice extends StatelessWidget {
  const _ClosedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8E2E0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1B1AC)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _red,
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dieses Restaurant ist gerade geschlossen. Bestellen ist aktuell nicht möglich.',
              style: TextStyle(
                color: _red,
                fontSize: 12.8,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBasketCard extends StatelessWidget {
  const _EmptyBasketCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            color: _muted,
            size: 38,
          ),
          SizedBox(height: 12),
          Text(
            'Dein Warenkorb ist leer.',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Geh zurück und füge ein Gericht hinzu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BasketItemCard extends StatelessWidget {
  final _BasketItemData item;
  final VoidCallback onDelete;

  const _BasketItemCard({
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final idText = item.articleNumber.trim().isNotEmpty
        ? item.articleNumber
        : item.itemId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
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
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
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
                if (idText.trim().isNotEmpty)
                  Text(
                    '#$idText',
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.singlePrice.toStringAsFixed(2).replaceAll('.', ',')} € pro Stück',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...item.details.map(
                        (detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '• $detail',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Text(
                  'Summe: ${item.totalPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: _muted,
              fontSize: 12.7,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _OrderTypeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OrderTypeButton({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _ink : _soft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : _ink,
                size: 18,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : _ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
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

class _TableDropdown extends StatelessWidget {
  final List<_TableData> tables;
  final String? value;
  final ValueChanged<_TableData?> onChanged;

  const _TableDropdown({
    required this.tables,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8C98E)),
        ),
        child: const Text(
          'Noch keine Plätze/Tische hinterlegt. Bitte an der Kasse melden.',
          style: TextStyle(
            color: Color(0xFF7A5215),
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final safeValue =
    value != null && tables.any((table) => table.id == value)
        ? value
        : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      items: tables.map((table) {
        return DropdownMenuItem<String>(
          value: table.id,
          child: Text(
            table.label,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (id) {
        if (id == null) {
          onChanged(null);
          return;
        }

        final selected = tables.firstWhere((table) => table.id == id);
        onChanged(selected);
      },
      decoration: InputDecoration(
        hintText: 'Tisch / Platz auswählen',
        prefixIcon: const Icon(
          Icons.table_restaurant_outlined,
          color: _muted,
        ),
        filled: true,
        fillColor: _soft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _ink,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final int totalQuantity;
  final String totalPrice;

  const _TotalCard({
    required this.totalQuantity,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: Colors.white,
            size: 23,
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gesamtsumme',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '$totalQuantity Artikel',
                style: const TextStyle(
                  color: Color(0xFFD8D8D8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            totalPrice,
            style: const TextStyle(
              color: _gold,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoOnlyNotice extends StatelessWidget {
  const _DemoOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8C98E)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF8A5A13),
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Diese Seite dient aktuell nur zur Präsentation. Bitte wende dich zum Bestellen direkt an die Kasse.',
              style: TextStyle(
                color: Color(0xFF7A5215),
                fontSize: 12.8,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _SubmitButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = title == 'Direkt senden' ? _green : _ink;

    return Material(
      color: enabled ? activeColor : const Color(0xFFC8C1B7),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled && !loading ? onTap : null,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: loading
              ? const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.4,
              ),
            ),
          )
              : Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE8E8E8),
                        fontSize: 11.3,
                        fontWeight: FontWeight.w700,
                      ),
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