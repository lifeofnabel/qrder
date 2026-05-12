import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  static const Color _bg = Color(0xFFF8F6F1);
  static const Color _card = Color(0xFFFFFEFB);
  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _muted = Color(0xFF777777);
  static const Color _soft = Color(0xFFEEEBE4);
  static const Color _line = Color(0xFFE7E2D9);
  static const Color _red = Color(0xFFD83A34);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingAreas = true;
  bool _obscurePassword = true;

  String _selectedArea = '';
  List<String> _areas = [];

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chooser')
          .doc('areas')
          .get();

      final raw = doc.data()?['name'];

      if (raw is List) {
        _areas = raw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        _areas.sort();
      }
    } catch (_) {
      _areas = [];
    }

    if (mounted) {
      setState(() => _isLoadingAreas = false);
    }
  }

  Map<String, dynamic> _defaultOpeningHours() {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    return {
      for (final day in days)
        day: {
          'open': '10:00',
          'close': '20:00',
          'closed': false,
        },
    };
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final businessName = _businessNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_selectedArea.trim().isEmpty) {
      _showSnack('Bitte Stadtteil auswählen.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('merchants').doc(uid).set({
        'id': uid,

        // Name: alles gleich, damit deine anderen Seiten sauber funktionieren
        'businessName': businessName,
        'shopName': businessName,
        'name': businessName,

        // Ansprechpartner
        'ownerName': _ownerNameController.text.trim(),

        // Öffentliche Infos
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'area': _selectedArea,
        'phone': _phoneController.text.trim(),
        'email': email,

        // Bilder
        'logoUrl': '',
        'coverUrl': '',

        // Links
        'website': '',
        'websiteUrl': '',
        'catalog': '',
        'instagram': '',
        'instagramUrl': '',
        'tiktok': '',
        'facebook': '',
        'googleMaps': '',

        // Status
        'isActive': true,
        'isPublic': true,

        // Qrder Settings
        'pageStyle': 'classic',
        'qrCodeOrder': true,
        'realOrder': false,

        // Kategorien / Typen
        'shopTypes': [],

        // Zeiten
        'openingHours': _defaultOpeningHours(),

        // Meta
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showSnack('Partnerkonto erstellt.');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'Registrierung fehlgeschlagen.';

      if (e.code == 'email-already-in-use') {
        message = 'Diese E-Mail wird bereits genutzt.';
      } else if (e.code == 'weak-password') {
        message = 'Passwort ist zu schwach.';
      } else if (e.code == 'invalid-email') {
        message = 'E-Mail ist ungültig.';
      }

      _showSnack(message);
    } catch (_) {
      _showSnack('Etwas ist schiefgelaufen.');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field fehlt';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'E-Mail fehlt';
    if (!text.contains('@') || !text.contains('.')) {
      return 'E-Mail ungültig';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Passwort fehlt';
    if (text.length < 6) return 'Mindestens 6 Zeichen';

    return null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _topBar(),
                const SizedBox(height: 22),
                _hero(),
                const SizedBox(height: 16),

                _SectionCard(
                  title: 'Geschäftsdaten',
                  subtitle: 'Basisdaten für deine öffentliche Qrder-Seite.',
                  children: [
                    _Input(
                      controller: _businessNameController,
                      label: 'Geschäftsname',
                      hint: 'z. B. City Grill Frankfurt',
                      icon: Icons.storefront_outlined,
                      validator: (v) => _required(v, 'Geschäftsname'),
                    ),
                    const SizedBox(height: 13),
                    _Input(
                      controller: _ownerNameController,
                      label: 'Ansprechpartner',
                      hint: 'Name vom Inhaber / Kontakt',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => _required(v, 'Ansprechpartner'),
                    ),
                    const SizedBox(height: 13),
                    _Input(
                      controller: _descriptionController,
                      label: 'Kurzbeschreibung',
                      hint: 'z. B. Burger, Bowls, Kaffee & Snacks',
                      icon: Icons.notes_rounded,
                      maxLines: 2,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _SectionCard(
                  title: 'Kontakt & Standort',
                  subtitle: 'Damit Kunden dich finden und erreichen.',
                  children: [
                    _Input(
                      controller: _addressController,
                      label: 'Adresse',
                      hint: 'z. B. Musterstraße 12, 60311 Frankfurt',
                      icon: Icons.location_on_outlined,
                      validator: (v) => _required(v, 'Adresse'),
                    ),
                    const SizedBox(height: 13),
                    _AreaDropdown(
                      value: _selectedArea.isEmpty ? null : _selectedArea,
                      areas: _areas,
                      loading: _isLoadingAreas,
                      onChanged: (value) {
                        setState(() {
                          _selectedArea = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 13),
                    _Input(
                      controller: _phoneController,
                      label: 'Telefon',
                      hint: 'z. B. 069 12345678',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                _SectionCard(
                  title: 'Login',
                  subtitle: 'Damit meldest du dich später als Händler an.',
                  children: [
                    _Input(
                      controller: _emailController,
                      label: 'E-Mail',
                      hint: 'kontakt@deingeschaeft.de',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 13),
                    _Input(
                      controller: _passwordController,
                      label: 'Passwort',
                      hint: 'Mindestens 6 Zeichen',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      validator: _passwordValidator,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _muted,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ink,
                      disabledBackgroundColor: const Color(0xFFBEB8AE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                        : const Text(
                      'Partnerkonto erstellen',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Nach der Registrierung kannst du Logo, Cover, Öffnungszeiten, Links, Artikel und Tische bearbeiten.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
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
            'Qrder Partner',
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

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: _ink,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partner werden',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Geschäft anlegen. QR-Seite starten. Weniger Chaos.',
                  style: TextStyle(
                    color: Color(0xFFD8D8D8),
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

/* UI HELPERS */

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _SignupColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _SignupColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _SignupColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: _SignupColors.muted,
              fontSize: 12.8,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _Input({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _SignupColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          obscureText: obscureText,
          style: const TextStyle(
            color: _SignupColors.ink,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              icon,
              color: _SignupColors.muted,
              size: 20,
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: _SignupColors.soft,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: _SignupColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: _SignupColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: _SignupColors.ink,
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: _SignupColors.red,
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AreaDropdown extends StatelessWidget {
  final String? value;
  final List<String> areas;
  final bool loading;
  final ValueChanged<String?> onChanged;

  const _AreaDropdown({
    required this.value,
    required this.areas,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value != null && areas.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stadtteil',
          style: TextStyle(
            color: _SignupColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: safeValue,
          isExpanded: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Stadtteil fehlt';
            }
            return null;
          },
          items: areas.map((area) {
            return DropdownMenuItem<String>(
              value: area,
              child: Text(
                area,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: loading ? null : onChanged,
          decoration: InputDecoration(
            hintText: loading
                ? 'Stadtteile laden...'
                : areas.isEmpty
                ? 'Keine Stadtteile gefunden'
                : 'Stadtteil auswählen',
            prefixIcon: const Icon(
              Icons.map_outlined,
              color: _SignupColors.muted,
              size: 20,
            ),
            filled: true,
            fillColor: _SignupColors.soft,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: _SignupColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: _SignupColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: _SignupColors.ink,
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignupColors {
  static const Color card = Color(0xFFFFFEFB);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF777777);
  static const Color soft = Color(0xFFEEEBE4);
  static const Color line = Color(0xFFE7E2D9);
  static const Color red = Color(0xFFD83A34);
}