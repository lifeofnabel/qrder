import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _bg = Color(0xFFF8F6F1);
const Color _card = Color(0xFFFFFEFB);
const Color _ink = Color(0xFF1A1A1A);
const Color _muted = Color(0xFF777777);
const Color _soft = Color(0xFFEEEBE4);
const Color _line = Color(0xFFE7E2D9);
const Color _gold = Color(0xFFD8A75D);
const Color _green = Color(0xFF2E9E5B);
const Color _red = Color(0xFFD83A34);
const Color _orange = Color(0xFFB87512);

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String _filter = 'active';
  String _search = '';
  bool _showUnconfirmedQr = false;

  bool _initializedOrders = false;
  final Set<String> _knownNewOrderIds = {};

  String? get _merchantId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _ordersRef {
    return FirebaseFirestore.instance.collection('orders');
  }

  DocumentReference<Map<String, dynamic>>? get _merchantRef {
    final id = _merchantId;
    if (id == null) return null;
    return FirebaseFirestore.instance.collection('merchants').doc(id);
  }

  String _formatPrice(num value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  void _playNewOrderFeedback(List<OrderData> orders) {
    final relevant = orders.where((order) {
      return order.status == 'new' ||
          order.status == 'preparing' ||
          order.isUnconfirmedQr;
    }).toList();

    final currentIds = relevant.map((e) => e.id).toSet();

    if (!_initializedOrders) {
      _knownNewOrderIds
        ..clear()
        ..addAll(currentIds);

      _initializedOrders = true;
      return;
    }

    final freshIds = currentIds.difference(_knownNewOrderIds);

    if (freshIds.isNotEmpty) {
      _knownNewOrderIds.addAll(freshIds);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                freshIds.length == 1
                    ? 'Neue Bestellung.'
                    : '${freshIds.length} neue Bestellungen.',
              ),
            ),
          );
      });
    }

    _knownNewOrderIds.removeWhere((id) => !currentIds.contains(id));
  }

  List<OrderData> _applyFilter(List<OrderData> orders) {
    var result = orders;

    if (_showUnconfirmedQr) {
      result = result.where((o) => o.isUnconfirmedQr).toList();
    } else {
      switch (_filter) {
        case 'active':
          result = result.where((o) {
            return o.status == 'new' || o.status == 'preparing';
          }).toList();
          break;

        case 'new':
          result = result.where((o) => o.status == 'new').toList();
          break;

        case 'preparing':
          result = result.where((o) => o.status == 'preparing').toList();
          break;

        case 'done':
          result = result.where((o) => o.status == 'done').toList();
          break;

        case 'cancelled':
          result = result.where((o) => o.status == 'cancelled').toList();
          break;

        case 'all':
        default:
          result = result.where((o) => !o.isUnconfirmedQr).toList();
          break;
      }
    }

    final search = _search.trim().toLowerCase();

    if (search.isNotEmpty) {
      result = result.where((order) {
        return order.orderCode.toLowerCase().contains(search) ||
            order.placeLabel.toLowerCase().contains(search) ||
            order.orderType.toLowerCase().contains(search) ||
            order.itemsText.toLowerCase().contains(search);
      }).toList();
    }

    result.sort((a, b) {
      final rankCompare = a.rank.compareTo(b.rank);
      if (rankCompare != 0) return rankCompare;
      return b.createdAt.compareTo(a.createdAt);
    });

    return result;
  }

  Future<void> _setStatus(OrderData order, String status) async {
    try {
      final data = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'new') {
        data['confirmedAt'] = FieldValue.serverTimestamp();
      }

      if (status == 'preparing') {
        data['acceptedAt'] = FieldValue.serverTimestamp();
      }

      if (status == 'done') {
        data['doneAt'] = FieldValue.serverTimestamp();
      }

      if (status == 'cancelled') {
        data['cancelledAt'] = FieldValue.serverTimestamp();
      }

      await _ordersRef.doc(order.id).set(data, SetOptions(merge: true));
    } catch (_) {
      _snack('Status konnte nicht geändert werden.');
    }
  }

  Future<void> _cancelOrder(OrderData order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: _card,
          title: const Text(
            'Bestellung stornieren?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text('${order.orderCode} wird storniert.'),
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
              child: const Text('Stornieren'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await _setStatus(order, 'cancelled');
    }
  }

  void _snack(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _openDetails(OrderData order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _OrderDetailsSheet(
          order: order,
          onConfirmQr: () {
            Navigator.pop(context);
            _setStatus(order, 'new');
          },
          onAccept: () {
            Navigator.pop(context);
            _setStatus(order, 'preparing');
          },
          onDone: () {
            Navigator.pop(context);
            _setStatus(order, 'done');
          },
          onCancel: () {
            Navigator.pop(context);
            _cancelOrder(order);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantId = _merchantId;
    final merchantRef = _merchantRef;

    if (merchantId == null || merchantRef == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Text(
            'Kein Händler eingeloggt.',
            style: TextStyle(
              color: _muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: merchantRef.snapshots(),
          builder: (context, merchantSnapshot) {
            final merchantData = merchantSnapshot.data?.data() ?? {};
            final qrEnabled = merchantData['qrCodeOrder'] as bool? ?? false;
            final realEnabled = merchantData['realOrder'] as bool? ?? false;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _ordersRef
                  .where('merchantId', isEqualTo: merchantId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _CenterMessage(
                    text: 'Bestellungen konnten nicht geladen werden.',
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _ink),
                  );
                }

                final allOrders = snapshot.data!.docs
                    .map((doc) => OrderData.fromDoc(doc))
                    .toList();

                _playNewOrderFeedback(allOrders);

                final visibleOrders = _applyFilter(allOrders);

                final newCount = allOrders.where((o) {
                  return o.status == 'new' || o.isUnconfirmedQr;
                }).length;

                final preparingCount =
                    allOrders.where((o) => o.status == 'preparing').length;

                final doneCount =
                    allOrders.where((o) => o.status == 'done').length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        newCount: newCount,
                        preparingCount: preparingCount,
                        doneCount: doneCount,
                      ),
                      const SizedBox(height: 16),
                      if (!qrEnabled && !realEnabled) ...[
                        const _DisabledOrdersNotice(),
                        const SizedBox(height: 14),
                      ],
                      _ControlBox(
                        filter: _filter,
                        showUnconfirmedQr: _showUnconfirmedQr,
                        onSearchChanged: (value) {
                          setState(() => _search = value);
                        },
                        onFilterChanged: (value) {
                          setState(() {
                            _filter = value;
                            _showUnconfirmedQr = false;
                          });
                        },
                        onUnconfirmedTap: () {
                          setState(() {
                            _showUnconfirmedQr = true;
                            _filter = 'qr';
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Text(
                            'Liste',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${visibleOrders.length}',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (visibleOrders.isEmpty)
                        const _EmptyOrders()
                      else
                        ...visibleOrders.map(
                              (order) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OrderCard(
                              order: order,
                              onTap: () => _openDetails(order),
                              onConfirmQr: order.isUnconfirmedQr
                                  ? () => _setStatus(order, 'new')
                                  : null,
                              onAccept: order.status == 'new'
                                  ? () => _setStatus(order, 'preparing')
                                  : null,
                              onDone: order.status == 'preparing'
                                  ? () => _setStatus(order, 'done')
                                  : null,
                              onCancel: order.status == 'done' ||
                                  order.status == 'cancelled'
                                  ? null
                                  : () => _cancelOrder(order),
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

class OrderData {
  final String id;
  final String orderCode;
  final String orderMode;
  final String orderType;
  final String status;
  final String tableId;
  final String tableName;
  final String tableLabel;
  final String customerNote;
  final num totalPrice;
  final int itemCount;
  final DateTime createdAt;
  final List<OrderItemData> items;

  const OrderData({
    required this.id,
    required this.orderCode,
    required this.orderMode,
    required this.orderType,
    required this.status,
    required this.tableId,
    required this.tableName,
    required this.tableLabel,
    required this.customerNote,
    required this.totalPrice,
    required this.itemCount,
    required this.createdAt,
    required this.items,
  });

  factory OrderData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final rawItems = data['items'];
    final items = <OrderItemData>[];

    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map) {
          items.add(OrderItemData.fromMap(Map<String, dynamic>.from(raw)));
        }
      }
    }

    DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    final rawCreatedAt = data['createdAt'];

    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    }

    final itemCount = data['itemCount'] is int
        ? data['itemCount'] as int
        : items.fold<int>(0, (sum, item) => sum + item.quantity);

    return OrderData(
      id: doc.id,
      orderCode: data['orderCode']?.toString() ?? doc.id,
      orderMode:
      data['orderMode']?.toString() ?? data['mode']?.toString() ?? 'qr',
      orderType: data['orderType']?.toString() ?? 'Abholung',
      status: data['status']?.toString() ?? 'new',
      tableId: data['tableId']?.toString() ?? '',
      tableName: data['tableName']?.toString() ?? '',
      tableLabel: data['tableLabel']?.toString() ?? '',
      customerNote:
      data['customerNote']?.toString() ?? data['wishText']?.toString() ?? '',
      totalPrice: data['totalPrice'] is num ? data['totalPrice'] as num : 0,
      itemCount: itemCount,
      createdAt: createdAt,
      items: items,
    );
  }

  bool get isUnconfirmedQr {
    return status == 'qr_created' || status == 'waiting_at_counter';
  }

  String get placeLabel {
    final table = tableName.trim().isNotEmpty ? tableName : tableLabel;

    if (table.trim().isNotEmpty) return table;

    if (orderType.toLowerCase().contains('mitnehmen')) {
      return 'Abholung';
    }

    return 'Kasse / Abholung';
  }

  String get statusLabel {
    if (isUnconfirmedQr) return 'QR offen';

    switch (status) {
      case 'new':
        return 'Neu';
      case 'preparing':
        return 'Läuft';
      case 'done':
        return 'Fertig';
      case 'cancelled':
        return 'Storniert';
      default:
        return status;
    }
  }

  int get rank {
    if (isUnconfirmedQr) return 0;

    switch (status) {
      case 'new':
        return 1;
      case 'preparing':
        return 2;
      case 'done':
        return 3;
      case 'cancelled':
        return 4;
      default:
        return 9;
    }
  }

  String get itemsText {
    return items.map((e) => e.title).join(' ');
  }

  String get dateText {
    if (createdAt.millisecondsSinceEpoch == 0) return '-';

    final d = createdAt.day.toString().padLeft(2, '0');
    final m = createdAt.month.toString().padLeft(2, '0');
    final y = createdAt.year.toString();

    return '$d.$m.$y';
  }

  String get timeText {
    if (createdAt.millisecondsSinceEpoch == 0) return '-';

    final h = createdAt.hour.toString().padLeft(2, '0');
    final min = createdAt.minute.toString().padLeft(2, '0');

    return '$h:$min';
  }

  String get totalText {
    return '${totalPrice.toStringAsFixed(2).replaceAll('.', ',')} €';
  }
}

class OrderItemData {
  final String itemId;
  final String title;
  final String articleNumber;
  final int quantity;
  final num singlePrice;
  final num totalPrice;
  final List<String> details;

  const OrderItemData({
    required this.itemId,
    required this.title,
    required this.articleNumber,
    required this.quantity,
    required this.singlePrice,
    required this.totalPrice,
    required this.details,
  });

  factory OrderItemData.fromMap(Map<String, dynamic> map) {
    final rawDetails = map['details'] ?? map['selectedOptions'];
    final details = <String>[];

    if (rawDetails is List) {
      for (final raw in rawDetails) {
        if (raw is Map) {
          final group = raw['groupTitle']?.toString() ?? '';
          final option = raw['optionName']?.toString() ??
              raw['name']?.toString() ??
              '';

          if (group.isNotEmpty && option.isNotEmpty) {
            details.add('$group: $option');
          } else if (option.isNotEmpty) {
            details.add(option);
          }
        } else {
          final text = raw.toString().trim();
          if (text.isNotEmpty) details.add(text);
        }
      }
    }

    final quantity = map['quantity'] is int ? map['quantity'] as int : 1;

    final singlePrice = map['singlePrice'] is num
        ? map['singlePrice'] as num
        : map['price'] is num
        ? map['price'] as num
        : 0;

    final totalPrice = map['totalPrice'] is num
        ? map['totalPrice'] as num
        : singlePrice * quantity;

    return OrderItemData(
      itemId: map['itemId']?.toString() ?? map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? map['name']?.toString() ?? 'Artikel',
      articleNumber: map['articleNumber']?.toString() ?? '',
      quantity: quantity,
      singlePrice: singlePrice,
      totalPrice: totalPrice,
      details: details,
    );
  }
}

/* UI */

class _Header extends StatelessWidget {
  final int newCount;
  final int preparingCount;
  final int doneCount;

  const _Header({
    required this.newCount,
    required this.preparingCount,
    required this.doneCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: _soft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.arrow_back_rounded, color: _ink),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _soft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'Live Orders',
                style: TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Bestellungen',
          style: TextStyle(
            color: _ink,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Neu',
                value: newCount.toString(),
                color: _orange,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _StatCard(
                label: 'Läuft',
                value: preparingCount.toString(),
                color: _green,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _StatCard(
                label: 'Fertig',
                value: doneCount.toString(),
                color: _ink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlBox extends StatelessWidget {
  final String filter;
  final bool showUnconfirmedQr;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onUnconfirmedTap;

  const _ControlBox({
    required this.filter,
    required this.showUnconfirmedQr,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onUnconfirmedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Code, Tisch, Artikel suchen...',
              prefixIcon: const Icon(Icons.search_rounded, color: _muted),
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
                borderSide: const BorderSide(color: _ink, width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterButton(
                label: 'Aktiv',
                selected: filter == 'active' && !showUnconfirmedQr,
                onTap: () => onFilterChanged('active'),
              ),
              _FilterButton(
                label: 'Alle',
                selected: filter == 'all' && !showUnconfirmedQr,
                onTap: () => onFilterChanged('all'),
              ),
              _FilterButton(
                label: 'Neu',
                selected: filter == 'new' && !showUnconfirmedQr,
                onTap: () => onFilterChanged('new'),
              ),
              _FilterButton(
                label: 'Läuft',
                selected: filter == 'preparing' && !showUnconfirmedQr,
                onTap: () => onFilterChanged('preparing'),
              ),
              _FilterButton(
                label: 'Fertig',
                selected: filter == 'done' && !showUnconfirmedQr,
                onTap: () => onFilterChanged('done'),
              ),
              _FilterButton(
                label: 'Storno',
                selected: filter == 'cancelled' && !showUnconfirmedQr,
                onTap: () => onFilterChanged('cancelled'),
              ),
              _FilterButton(
                label: 'QR offen',
                selected: showUnconfirmedQr,
                danger: true,
                onTap: onUnconfirmedTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = danger ? _red : _ink;

    return Material(
      color: selected ? activeColor : _soft,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
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

class _OrderCard extends StatelessWidget {
  final OrderData order;
  final VoidCallback onTap;
  final VoidCallback? onConfirmQr;
  final VoidCallback? onAccept;
  final VoidCallback? onDone;
  final VoidCallback? onCancel;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onConfirmQr,
    required this.onAccept,
    required this.onDone,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order);
    final statusBg = _getStatusBg(order);

    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: order.status == 'new' || order.isUnconfirmedQr
                  ? _gold
                  : _line,
              width: order.status == 'new' || order.isUnconfirmedQr ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _OrderIcon(order: order),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${order.dateText} • ${order.timeText}',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 18, color: _muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.placeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    order.totalText,
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                order.items
                    .take(3)
                    .map((item) => '${item.quantity}x ${item.title}')
                    .join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  if (onConfirmQr != null)
                    Expanded(
                      child: _ActionButton(
                        label: 'QR bestätigen',
                        color: _orange,
                        onTap: onConfirmQr!,
                      ),
                    ),
                  if (onAccept != null)
                    Expanded(
                      child: _ActionButton(
                        label: 'Annehmen',
                        color: _ink,
                        onTap: onAccept!,
                      ),
                    ),
                  if (onDone != null)
                    Expanded(
                      child: _ActionButton(
                        label: 'Fertig',
                        color: _green,
                        onTap: onDone!,
                      ),
                    ),
                  if (onCancel != null) ...[
                    const SizedBox(width: 8),
                    _IconButtonBox(
                      icon: Icons.close_rounded,
                      color: _red,
                      onTap: onCancel!,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderData order) {
    if (order.isUnconfirmedQr) return _orange;

    switch (order.status) {
      case 'new':
        return _orange;
      case 'preparing':
        return _green;
      case 'done':
        return _ink;
      case 'cancelled':
        return _red;
      default:
        return _muted;
    }
  }

  Color _getStatusBg(OrderData order) {
    if (order.isUnconfirmedQr) return const Color(0xFFFFF4D8);

    switch (order.status) {
      case 'new':
        return const Color(0xFFFFF4D8);
      case 'preparing':
        return const Color(0xFFEAF7EF);
      case 'done':
        return _soft;
      case 'cancelled':
        return const Color(0xFFF8E2E0);
      default:
        return _soft;
    }
  }
}

class _OrderIcon extends StatelessWidget {
  final OrderData order;

  const _OrderIcon({required this.order});

  @override
  Widget build(BuildContext context) {
    final isQr = order.orderMode.toLowerCase().contains('qr');

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(
        isQr ? Icons.qr_code_2_rounded : Icons.send_rounded,
        color: Colors.white,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButtonBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconButtonBox({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  final OrderData order;
  final VoidCallback onConfirmQr;
  final VoidCallback onAccept;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  const _OrderDetailsSheet({
    required this.order,
    required this.onConfirmQr,
    required this.onAccept,
    required this.onDone,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderCode,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                    decoration: BoxDecoration(
                      color: _soft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoBox(order: order),
              if (order.customerNote.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _NoteBox(text: order.customerNote),
              ],
              const SizedBox(height: 18),
              const Text(
                'Artikel',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ...order.items.map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _DetailItem(item: item),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (order.isUnconfirmedQr)
                    Expanded(
                      child: _ActionButton(
                        label: 'QR bestätigen',
                        color: _orange,
                        onTap: onConfirmQr,
                      ),
                    ),
                  if (order.status == 'new')
                    Expanded(
                      child: _ActionButton(
                        label: 'Annehmen',
                        color: _ink,
                        onTap: onAccept,
                      ),
                    ),
                  if (order.status == 'preparing')
                    Expanded(
                      child: _ActionButton(
                        label: 'Fertig',
                        color: _green,
                        onTap: onDone,
                      ),
                    ),
                  if (order.status != 'done' && order.status != 'cancelled') ...[
                    const SizedBox(width: 8),
                    _IconButtonBox(
                      icon: Icons.close_rounded,
                      color: _red,
                      onTap: onCancel,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final OrderData order;

  const _InfoBox({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          _DetailRow(label: 'Ort', value: order.placeLabel),
          _DetailRow(label: 'Typ', value: order.orderType),
          _DetailRow(label: 'Zeit', value: '${order.dateText} • ${order.timeText}'),
          _DetailRow(label: 'Artikel', value: '${order.itemCount}'),
          _DetailRow(label: 'Gesamt', value: order.totalText),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String text;

  const _NoteBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECD18B)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF7A5215),
          fontSize: 13.5,
          height: 1.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final OrderItemData item;

  const _DetailItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (item.details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.details.join(', '),
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${item.totalPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
            style: const TextStyle(
              color: _gold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledOrdersNotice extends StatelessWidget {
  const _DisabledOrdersNotice();

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
      child: const Text(
        'Bestellfunktionen sind aktuell deaktiviert.',
        style: TextStyle(
          color: Color(0xFF7A5215),
          fontSize: 12.8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: _muted, size: 44),
          SizedBox(height: 12),
          Text(
            'Keine Bestellungen',
            style: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

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