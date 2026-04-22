import 'package:flutter/material.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String _selectedFilter = 'Alle';
  String _searchText = '';

  final List<Map<String, dynamic>> _orders = [
    {
      'orderId': '#1001',
      'customer': 'Tisch 4',
      'date': '21.04.2026',
      'time': '18:42',
      'status': 'Abgeschlossen',
      'total': '24,50 €',
      'items': ['2x Shawarma Wrap', '1x Pommes', '2x Ayran'],
    },
    {
      'orderId': '#1002',
      'customer': 'Tisch 2',
      'date': '21.04.2026',
      'time': '19:05',
      'status': 'Offen',
      'total': '13,00 €',
      'items': ['1x Falafel Wrap', '1x Cola'],
    },
    {
      'orderId': '#1003',
      'customer': 'Tisch 7',
      'date': '20.04.2026',
      'time': '20:11',
      'status': 'Storniert',
      'total': '31,00 €',
      'items': ['2x Halloumi Wrap', '1x Hummus Teller', '2x Wasser'],
    },
    {
      'orderId': '#1004',
      'customer': 'Takeaway',
      'date': '20.04.2026',
      'time': '17:28',
      'status': 'Abgeschlossen',
      'total': '18,50 €',
      'items': ['1x Couscous Bowl', '1x Mozzarella Bowl', '1x Cola'],
    },
    {
      'orderId': '#1005',
      'customer': 'Tisch 1',
      'date': '19.04.2026',
      'time': '21:02',
      'status': 'Abgeschlossen',
      'total': '42,00 €',
      'items': ['3x Shawarma Wrap', '2x Pommes', '3x Wasser'],
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    return _orders.where((order) {
      final matchesFilter =
          _selectedFilter == 'Alle' || order['status'] == _selectedFilter;

      final matchesSearch =
          _searchText.isEmpty ||
              order['orderId']
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              order['customer']
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              order['date']
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Abgeschlossen':
        return const Color(0xFF4F6B52);
      case 'Offen':
        return const Color(0xFF9A6A10);
      case 'Storniert':
        return const Color(0xFF8A4A4A);
      default:
        return const Color(0xFF777777);
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'Abgeschlossen':
        return const Color(0xFFE6F0E7);
      case 'Offen':
        return const Color(0xFFF6ECD9);
      case 'Storniert':
        return const Color(0xFFF4E1E1);
      default:
        return const Color(0xFFEEEBE4);
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDFCF9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final items = order['items'] as List<dynamic>;

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
              const SizedBox(height: 20),
              Text(
                'Bestellung ${order['orderId']}',
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _DetailRow(label: 'Kunde / Ort', value: order['customer']),
              _DetailRow(label: 'Datum', value: order['date']),
              _DetailRow(label: 'Uhrzeit', value: order['time']),
              _DetailRow(label: 'Status', value: order['status']),
              _DetailRow(label: 'Gesamt', value: order['total']),
              const SizedBox(height: 18),
              const Text(
                'Artikel',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...items.map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Schließen',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F1),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Order History',
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hier findest du vergangene Bestellungen, ihren Status und die wichtigsten Infos auf einen Blick.',
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
                      'Suche',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                        });
                      },
                      style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nach Bestellnummer, Tisch oder Datum suchen',
                        hintStyle: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF888888),
                          size: 20,
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

                    const SizedBox(height: 18),

                    const Text(
                      'Filter',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _FilterChipButton(
                          label: 'Alle',
                          selected: _selectedFilter == 'Alle',
                          onTap: () {
                            setState(() {
                              _selectedFilter = 'Alle';
                            });
                          },
                        ),
                        _FilterChipButton(
                          label: 'Abgeschlossen',
                          selected: _selectedFilter == 'Abgeschlossen',
                          onTap: () {
                            setState(() {
                              _selectedFilter = 'Abgeschlossen';
                            });
                          },
                        ),
                        _FilterChipButton(
                          label: 'Offen',
                          selected: _selectedFilter == 'Offen',
                          onTap: () {
                            setState(() {
                              _selectedFilter = 'Offen';
                            });
                          },
                        ),
                        _FilterChipButton(
                          label: 'Storniert',
                          selected: _selectedFilter == 'Storniert',
                          onTap: () {
                            setState(() {
                              _selectedFilter = 'Storniert';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  const Text(
                    'Bestellungen',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${orders.length} Einträge',
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (orders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFCF9),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFE7E2D9),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Keine passenden Bestellungen gefunden.',
                    style: TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 15,
                    ),
                  ),
                )
              else
                ...orders.map(
                      (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _OrderHistoryCard(
                      orderId: order['orderId'],
                      customer: order['customer'],
                      date: order['date'],
                      time: order['time'],
                      total: order['total'],
                      status: order['status'],
                      statusColor: _statusColor(order['status']),
                      statusBgColor: _statusBgColor(order['status']),
                      onTap: () => _showOrderDetails(order),
                    ),
                  ),
                ),

              const SizedBox(height: 18),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _TrustChip(icon: '🧾', label: 'Alte Orders'),
                  _TrustChip(icon: '🔎', label: 'Schnell suchen'),
                  _TrustChip(icon: '📦', label: 'Details ansehen'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  final String orderId;
  final String customer;
  final String date;
  final String time;
  final String total;
  final String status;
  final Color statusColor;
  final Color statusBgColor;
  final VoidCallback onTap;

  const _OrderHistoryCard({
    required this.orderId,
    required this.customer,
    required this.date,
    required this.time,
    required this.total,
    required this.status,
    required this.statusColor,
    required this.statusBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFDFCF9),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    orderId,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                customer,
                style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Color(0xFF999999),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$date • $time',
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    total,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1A1A1A)
              : const Color(0xFFEEEBE4),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF555555),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final String icon;
  final String label;

  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEBE4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}