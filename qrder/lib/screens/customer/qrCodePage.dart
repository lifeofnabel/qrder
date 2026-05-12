import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'restaurantPage.dart';

const Color _bg = Color(0xFFF8F6F1);
const Color _card = Color(0xFFFFFEFB);
const Color _ink = Color(0xFF1A1A1A);
const Color _muted = Color(0xFF777777);
const Color _soft = Color(0xFFEEEBE4);
const Color _line = Color(0xFFE7E2D9);
const Color _gold = Color(0xFFD8A75D);
const Color _green = Color(0xFF2F5E1C);
const Color _red = Color(0xFFD83A34);

class QrCodePage extends StatefulWidget {
  const QrCodePage({
    super.key,
    required this.merchantId,
    required this.restaurantName,
    required this.orderMode, // qr oder real
    required this.orderType,
    required this.items,
    required this.totalPrice,
    this.tableId,
    this.tableName,
    this.customerNote = '',
    this.merchantLogoUrl = '',
    this.googleMapsUrl = '',
  });

  final String merchantId;
  final String restaurantName;
  final String orderMode;
  final String orderType;
  final List<Map<String, dynamic>> items;
  final num totalPrice;

  final String? tableId;
  final String? tableName;
  final String customerNote;

  final String merchantLogoUrl;
  final String googleMapsUrl;

  @override
  State<QrCodePage> createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  bool _isCreating = true;
  String? _error;

  String _orderId = '';
  String _orderCode = '';
  String _qrLink = '';

  @override
  void initState() {
    super.initState();
    _createOrderOnce();
  }

  Future<void> _createOrderOnce() async {
    try {
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();

      final orderId = orderRef.id;
      final orderCode = _makeOrderCode(widget.restaurantName, orderId);
      final qrLink = 'https://qrder.app/order/$orderId';

      final isRealOrder = widget.orderMode == 'real';

      await orderRef.set({
        'id': orderId,
        'merchantId': widget.merchantId,
        'merchantName': widget.restaurantName,
        'merchantLogoUrl': widget.merchantLogoUrl,
        'merchantGoogleMaps': widget.googleMapsUrl,

        'orderCode': orderCode,
        'qrLink': qrLink,

        'orderMode': widget.orderMode,
        'orderType': widget.orderType,

        'tableId': widget.tableId ?? '',
        'tableName': widget.tableName ?? '',

        'items': widget.items,
        'customerNote': widget.customerNote.trim(),
        'totalPrice': widget.totalPrice,

        'paymentStatus': 'pay_at_counter',
        'paymentText': 'An der Kasse bezahlen',

        'status': isRealOrder ? 'new' : 'waiting_at_counter',

        'isPaid': false,
        'isArchived': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _orderId = orderId;
        _orderCode = orderCode;
        _qrLink = qrLink;
        _isCreating = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isCreating = false;
      });
    }
  }

  String _makeOrderCode(String restaurantName, String orderId) {
    final cleanLetters = restaurantName
        .replaceAll(RegExp(r'[^A-Za-zÄÖÜäöüß]'), '')
        .toUpperCase()
        .padRight(3, 'Q');

    final prefix = cleanLetters.substring(0, 3);

    final hash = orderId.codeUnits.fold<int>(0, (sum, char) => sum + char);
    final number = (hash * 7 + DateTime.now().millisecondsSinceEpoch) % 10000;

    return '$prefix-${number.toString().padLeft(4, '0')}';
  }

  String _formatPrice(num value) {
    return '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  Future<void> _openGoogleMaps() async {
    final raw = widget.googleMapsUrl.trim();

    if (raw.isEmpty) {
      _showSnack('Kein Google-Maps-Link hinterlegt.');
      return;
    }

    final uri = raw.startsWith('http://') || raw.startsWith('https://')
        ? Uri.parse(raw)
        : Uri.parse('https://$raw');

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok) {
      _showSnack('Google Maps konnte nicht geöffnet werden.');
    }
  }

  void _goBackToShop() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantPage(merchantId: widget.merchantId),
      ),
          (route) => false,
    );
  }

  void _showSnack(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isRealOrder = widget.orderMode == 'real';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _ink),
        title: Column(
          children: [
            Text(
              widget.restaurantName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'powered by Qrder',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isCreating
            ? const Center(
          child: CircularProgressIndicator(color: _ink),
        )
            : _error != null
            ? _ErrorState(
          error: _error!,
          onBack: () => Navigator.pop(context),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StatusNotice(isRealOrder: isRealOrder),

              const SizedBox(height: 18),

              Text(
                isRealOrder
                    ? 'Bestellung gesendet'
                    : 'QR-Code Bestellung',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                isRealOrder
                    ? 'Deine Bestellung wurde an das Restaurant übermittelt.'
                    : 'Zeige diesen QR-Code an der Kasse. Dort wird deine Bestellung geöffnet.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 14.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              _QrCard(
                qrLink: _qrLink,
                orderCode: _orderCode,
                totalPrice: _formatPrice(widget.totalPrice),
                orderType: widget.orderType,
                tableName: widget.tableName ?? '',
                isRealOrder: isRealOrder,
              ),

              const SizedBox(height: 16),

              _PaymentBox(),

              const SizedBox(height: 16),

              _ItemsBox(items: widget.items),

              const SizedBox(height: 20),

              if (widget.googleMapsUrl.trim().isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _openGoogleMaps,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text(
                      'Route / Bewertung öffnen',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

              if (widget.googleMapsUrl.trim().isNotEmpty)
                const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _goBackToShop,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  icon: const Icon(Icons.storefront_rounded),
                  label: const Text(
                    'Neue Bestellung starten',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Bestell-ID: $_orderId',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  final bool isRealOrder;

  const _StatusNotice({
    required this.isRealOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRealOrder ? const Color(0xFFEAF7EF) : const Color(0xFFFFF4D8),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: isRealOrder ? const Color(0xFFCDEBD8) : const Color(0xFFECD18B),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRealOrder
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            color: isRealOrder ? _green : const Color(0xFF8A5A00),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isRealOrder
                  ? 'Hinweis: Die Bestellung ist beim Restaurant angekommen.'
                  : 'Hinweis: Bitte zeige den QR-Code an der Kasse und bezahle dort.',
              style: const TextStyle(
                color: _ink,
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

class _QrCard extends StatelessWidget {
  final String qrLink;
  final String orderCode;
  final String totalPrice;
  final String orderType;
  final String tableName;
  final bool isRealOrder;

  const _QrCard({
    required this.qrLink,
    required this.orderCode,
    required this.totalPrice,
    required this.orderType,
    required this.tableName,
    required this.isRealOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!isRealOrder)
            Container(
              width: 238,
              height: 238,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: _line),
              ),
              child: QrImageView(
                data: qrLink,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
                foregroundColor: _ink,
              ),
            )
          else
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(34),
              ),
              child: const Icon(
                Icons.done_rounded,
                color: Colors.white,
                size: 70,
              ),
            ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: _line),
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Bestellcode', value: orderCode),
                const SizedBox(height: 10),
                _InfoRow(label: 'Preis', value: totalPrice),
                const SizedBox(height: 10),
                _InfoRow(label: 'Bestellart', value: orderType),
                if (tableName.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoRow(label: 'Platz', value: tableName),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(23),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.payments_outlined,
            color: Colors.white,
            size: 25,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Bitte an der Kasse bezahlen.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsBox extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _ItemsBox({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bestellung',
            style: TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            final title =
                item['title']?.toString() ?? item['name']?.toString() ?? 'Artikel';

            final quantityRaw = item['quantity'];
            final quantity = quantityRaw is num ? quantityRaw.toInt() : 1;

            final totalRaw = item['totalPrice'] ?? item['price'];
            final total = totalRaw is num ? totalRaw : 0;

            final optionsRaw = item['selectedOptions'] ?? item['details'];
            final options = optionsRaw is List ? optionsRaw : [];

            return Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${quantity}x',
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
                            title,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (options.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              options
                                  .map((e) {
                                if (e is Map) {
                                  return e['optionName']?.toString() ??
                                      e['name']?.toString() ??
                                      '';
                                }
                                return e.toString();
                              })
                                  .where((e) => e.trim().isNotEmpty)
                                  .join(', '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${total.toStringAsFixed(2).replaceAll('.', ',')} €',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onBack;

  const _ErrorState({
    required this.error,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: _red,
                size: 46,
              ),
              const SizedBox(height: 14),
              const Text(
                'Bestellung konnte nicht erstellt werden.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onBack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Zurück',
                    style: TextStyle(fontWeight: FontWeight.w900),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}