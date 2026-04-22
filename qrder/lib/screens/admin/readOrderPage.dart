import 'package:flutter/material.dart';
import 'orderPage.dart';

class ReadOrderPage extends StatefulWidget {
  const ReadOrderPage({super.key});

  @override
  State<ReadOrderPage> createState() => _ReadOrderPageState();
}

class _ReadOrderPageState extends State<ReadOrderPage> {
  final TextEditingController _prefixController =
  TextEditingController(text: 'BAB');
  final TextEditingController _numberController =
  TextEditingController(text: '12345');

  @override
  void dispose() {
    _prefixController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  void _readOrder() {
    final prefix = _prefixController.text.trim().toUpperCase();
    final number = _numberController.text.trim();

    if (prefix.isEmpty || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Prefix und Nummer eingeben.'),
        ),
      );
      return;
    }

    if (prefix.length < 2 || prefix.length > 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prefix muss 2 bis 4 Buchstaben haben.'),
        ),
      );
      return;
    }

    if (number.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Die Nummer muss genau 5 Ziffern haben.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderPage(
          orderCode: '$prefix-$number',
          customerName: 'Demo Kunde',
          tableOrType: 'Tisch 4',
          orderItems: const [
            '1x Hähnchenwrap',
            '1x Pommes',
            '1x Cola',
            'Soße: Knoblauch',
          ],
          totalPrice: '11,00 €',
        ),
      ),
    );
  }

  void _simulateScan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OrderPage(
          orderCode: 'BAB-54321',
          customerName: 'Scan Kunde',
          tableOrType: 'Takeaway',
          orderItems: [
            '1x Falafel Wrap',
            '1x Süßkartoffel',
            '1x Ayran',
            'Soße: Scharf',
          ],
          totalPrice: '13,50 €',
        ),
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
          'Bestellung lesen',
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
                'Hier kannst du eine Bestellung per Kamera lesen oder optional manuell über Prefix und Code öffnen.',
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
                      'Kamera',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _simulateScan,
                      child: Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEBE4),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFE0DBD2),
                            width: 1,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 52,
                              color: Color(0xFF777777),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Kamera Platzhalter',
                              style: TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Später scannt die Kamera automatisch und öffnet direkt die Bestellung.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF777777),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _simulateScan,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A1A1A),
                          side: const BorderSide(
                            color: Color(0xFFDDDDDD),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.center_focus_strong_rounded),
                        label: const Text(
                          'Scan simulieren',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
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
                      'Optional manuell',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Der Laden kann einen festen Prefix haben. Dazu kommt die 5-stellige Nummer der Bestellung.',
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _StyledInput(
                            controller: _prefixController,
                            hintText: 'BAB',
                            maxLength: 4,
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _StyledInput(
                            controller: _numberController,
                            hintText: '12345',
                            maxLength: 5,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _readOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Bestellung lesen',
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

              const SizedBox(height: 20),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _TrustChip(icon: '📷', label: 'Scan bereit'),
                  _TrustChip(icon: '⌨️', label: 'Manuell möglich'),
                  _TrustChip(icon: '⚡', label: 'Schnell öffnen'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _StyledInput({
    required this.controller,
    required this.hintText,
    this.maxLength,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 15,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F0E9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
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