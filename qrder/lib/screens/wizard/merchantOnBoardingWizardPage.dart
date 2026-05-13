import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../guest/loginPage.dart';
import '../../core/services/cloudinary_service.dart';


class MerchantOnboardingWizardPage extends StatefulWidget {
  const MerchantOnboardingWizardPage({super.key});

  @override
  State<MerchantOnboardingWizardPage> createState() =>
      _MerchantOnboardingWizardPageState();
}

class _MerchantOnboardingWizardPageState
    extends State<MerchantOnboardingWizardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  static const Color _bg = Color(0xFFF8F6F1);
  static const Color _card = Color(0xFFFFFEFB);
  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _muted = Color(0xFF777777);
  static const Color _line = Color(0xFFE7E2D9);
  static const Color _gold = Color(0xFFD8A75D);

  int _step = 0;
  bool _isLoading = false;

  String? _createdMerchantId;
  String? _createdEmail;

  static const String _defaultPassword = '12345678';

  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _googleMapsController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();

  final TextEditingController _newCategoryController = TextEditingController();

  final TextEditingController _articleTitleController = TextEditingController();
  final TextEditingController _articleDescriptionController =
  TextEditingController();
  final TextEditingController _articlePriceController = TextEditingController();

  String? _selectedArea;
  String? _selectedShopType;

  String? _logoUrl;
  String? _articleImageUrl;

  final List<String> _categories = [];
  int _currentCategoryIndex = 0;

  final List<String> _categorySuggestions = const [
    'Pizza',
    'Burger',
    'Döner',
    'Shawarma',
    'Falafel',
    'Bowls',
    'Wraps',
    'Teller',
    'Snacks',
    'Getränke',
    'Dessert',
    'Angebote',
  ];

  final List<String> _areas = const [
    'Innenstadt',
    'Westend',
    'Sachsenhausen',
    'Bockenheim',
    'Bornheim',
    'Nordend',
    'Gallus',
    'Bahnhofsviertel',
    'Ostend',
    'Höchst',
  ];

  final List<String> _shopTypes = const [
    'Imbiss',
    'Restaurant',
    'Kiosk',
    'Café',
    'Bäckerei',
    'Barber',
    'Beauty',
    'Pizza',
    'Burger',
    'Döner',
  ];

  @override
  void dispose() {
    _shopNameController.dispose();
    _instagramController.dispose();
    _googleMapsController.dispose();
    _openingHoursController.dispose();
    _newCategoryController.dispose();
    _articleTitleController.dispose();
    _articleDescriptionController.dispose();
    _articlePriceController.dispose();
    super.dispose();
  }

  String _generateEmail(String shopName) {
    final cleaned = shopName
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    return '$cleaned@mail.com';
  }

  Future<String?> _pickCropAndUploadImage({
    required String folder,
    required CropAspectRatio aspectRatio,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked == null) return null;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: aspectRatio,
        compressQuality: 88,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Bild schneiden',
            toolbarColor: _ink,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Bild schneiden',
            aspectRatioLockEnabled: true,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 520, height: 520),
          ),
        ],
      );

      if (cropped == null) return null;

      final croppedFile = XFile(
        cropped.path,
        name: 'qrder_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final url = await CloudinaryService.uploadImage(croppedFile);

      return url;
    } catch (e) {
      _showError('Bild konnte nicht hochgeladen werden: $e');
      return null;
    }
  }

  Future<void> _uploadLogo() async {
    setState(() => _isLoading = true);

    final url = await _pickCropAndUploadImage(
      folder: 'qrder/logos',
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    );

    if (url != null) {
      setState(() => _logoUrl = url);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _uploadArticleImage() async {
    setState(() => _isLoading = true);

    final url = await _pickCropAndUploadImage(
      folder: 'qrder/articles',
      aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
    );

    if (url != null) {
      setState(() => _articleImageUrl = url);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _createMerchant() async {
    final shopName = _shopNameController.text.trim();

    if (shopName.isEmpty) {
      _showError('Ladenname fehlt');
      return;
    }

    if (_selectedArea == null) {
      _showError('Stadtteil fehlt');
      return;
    }

    if (_selectedShopType == null) {
      _showError('Shop-Kategorie fehlt');
      return;
    }

    if (_logoUrl == null) {
      _showError('Logo ist Pflicht');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _generateEmail(shopName);

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: _defaultPassword,
      );

      final merchantId = userCredential.user!.uid;

      await _firestore.collection('merchants').doc(merchantId).set({
        'id': merchantId,
        'name': shopName,
        'email': email,
        'area': _selectedArea,
        'shopType': _selectedShopType,
        'logoUrl': _logoUrl,
        'instagram': _instagramController.text.trim(),
        'googleMapsUrl': _googleMapsController.text.trim(),
        'openingHours': _openingHoursController.text.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': 'internal_onboarding',
      });

      setState(() {
        _createdMerchantId = merchantId;
        _createdEmail = email;
        _step = 1;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showError('Diese Email existiert schon. Ladenname leicht ändern.');
      } else {
        _showError(e.message ?? 'Auth Fehler');
      }
    } catch (e) {
      _showError('Fehler: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCategories() async {
    if (_createdMerchantId == null) return;

    if (_categories.isEmpty) {
      _showError('Mindestens eine Kategorie hinzufügen');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final batch = _firestore.batch();

      for (int i = 0; i < _categories.length; i++) {
        final ref = _firestore
            .collection('merchants')
            .doc(_createdMerchantId)
            .collection('itemCategories')
            .doc();

        batch.set(ref, {
          'id': ref.id,
          'name': _categories[i],
          'sortIndex': i,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      setState(() => _step = 2);
    } catch (e) {
      _showError('Kategorien konnten nicht gespeichert werden: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveArticle() async {
    if (_createdMerchantId == null || _categories.isEmpty) return;

    final title = _articleTitleController.text.trim();
    final description = _articleDescriptionController.text.trim();
    final priceText = _articlePriceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(priceText);

    if (title.isEmpty) {
      _showError('Titel fehlt');
      return;
    }

    if (price == null) {
      _showError('Preis ungültig');
      return;
    }

    final categoryName = _categories[_currentCategoryIndex];

    setState(() => _isLoading = true);

    try {
      final ref = _firestore
          .collection('merchants')
          .doc(_createdMerchantId)
          .collection('items')
          .doc();

      await ref.set({
        'id': ref.id,
        'title': title,
        'description': description,
        'price': price,
        'imageUrl': _articleImageUrl ?? '',
        'categoryName': categoryName,
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _articleTitleController.clear();
      _articleDescriptionController.clear();
      _articlePriceController.clear();

      setState(() => _articleImageUrl = null);

      _showSuccess('Artikel gespeichert');
    } catch (e) {
      _showError('Artikel konnte nicht gespeichert werden: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextCategory() {
    if (_currentCategoryIndex < _categories.length - 1) {
      setState(() => _currentCategoryIndex++);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _addCategory(String category) {
    final clean = category.trim();

    if (clean.isEmpty) return;
    if (_categories.contains(clean)) return;

    setState(() {
      _categories.add(clean);
      _newCategoryController.clear();
    });
  }

  void _removeCategory(String category) {
    setState(() => _categories.remove(category));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Qrder Onboarding',
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      bottomNavigationBar: _createdEmail == null ? null : _loginInfoBar(),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isLoading,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildShopStep();
      case 1:
        return _buildCategoryStep();
      case 2:
        return _buildArticleStep();
      default:
        return _buildShopStep();
    }
  }

  Widget _buildShopStep() {
    return ListView(
      children: [
        _stepHeader('1', 'Laden erstellen', 'Basisdaten, Logo und Zugang'),

        _input(
          controller: _shopNameController,
          label: 'Ladenname *',
        ),

        const SizedBox(height: 12),

        _dropdown(
          label: 'Stadtteil *',
          value: _selectedArea,
          items: _areas,
          onChanged: (value) => setState(() => _selectedArea = value),
        ),

        const SizedBox(height: 12),

        _dropdown(
          label: 'Shop-Kategorie *',
          value: _selectedShopType,
          items: _shopTypes,
          onChanged: (value) => setState(() => _selectedShopType = value),
        ),

        const SizedBox(height: 14),

        _imageUploadCard(
          title: 'Logo *',
          subtitle: 'Quadratisch schneiden, wirkt später sauberer',
          imageUrl: _logoUrl,
          onTap: _uploadLogo,
        ),

        const SizedBox(height: 12),

        _input(
          controller: _instagramController,
          label: 'Instagram optional',
        ),

        const SizedBox(height: 12),

        _input(
          controller: _googleMapsController,
          label: 'Google Maps Link optional',
        ),

        const SizedBox(height: 12),

        _input(
          controller: _openingHoursController,
          label: 'Öffnungszeiten optional',
          maxLines: 3,
        ),

        const SizedBox(height: 20),

        _primaryButton(
          text: 'Laden erstellen',
          onPressed: _createMerchant,
        ),
      ],
    );
  }

  Widget _buildCategoryStep() {
    return ListView(
      children: [
        _stepHeader('2', 'Kategorien', 'Vorschläge wählen oder eigene anlegen'),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categorySuggestions.map((category) {
            final selected = _categories.contains(category);

            return ChoiceChip(
              label: Text(category),
              selected: selected,
              selectedColor: _gold.withOpacity(0.25),
              onSelected: (_) {
                selected ? _removeCategory(category) : _addCategory(category);
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: _input(
                controller: _newCategoryController,
                label: 'Eigene Kategorie',
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () => _addCategory(_newCategoryController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        _sectionLabel('Ausgewählt'),

        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            return Chip(
              backgroundColor: _card,
              label: Text(category),
              onDeleted: () => _removeCategory(category),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        _primaryButton(
          text: 'Kategorien speichern',
          onPressed: _saveCategories,
        ),
      ],
    );
  }

  Widget _buildArticleStep() {
    final category = _categories[_currentCategoryIndex];

    return ListView(
      children: [
        _stepHeader(
          '3',
          'Artikel einpflegen',
          'Aktuelle Kategorie: $category',
        ),

        _input(
          controller: _articleTitleController,
          label: 'Titel *',
        ),

        const SizedBox(height: 12),

        _input(
          controller: _articleDescriptionController,
          label: 'Beschreibung optional',
          maxLines: 3,
        ),

        const SizedBox(height: 12),

        _input(
          controller: _articlePriceController,
          label: 'Preis *',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),

        const SizedBox(height: 14),

        _imageUploadCard(
          title: 'Artikelbild optional',
          subtitle: '4:3 schneiden, gut für Karten und Menü',
          imageUrl: _articleImageUrl,
          onTap: _uploadArticleImage,
        ),

        const SizedBox(height: 20),

        _primaryButton(
          text: 'Artikel speichern',
          onPressed: _saveArticle,
        ),

        const SizedBox(height: 12),

        OutlinedButton(
          onPressed: _nextCategory,
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            side: const BorderSide(color: _line),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _currentCategoryIndex < _categories.length - 1
                ? 'Nächste Kategorie'
                : 'Fertig und zum Login',
          ),
        ),
      ],
    );
  }

  Widget _stepHeader(String number, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
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
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13.5,
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

  Widget _imageUploadCard({
    required String title,
    required String subtitle,
    required String? imageUrl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDE6),
                borderRadius: BorderRadius.circular(18),
                image: imageUrl == null
                    ? null
                    : DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: imageUrl == null
                  ? const Icon(
                Icons.add_photo_alternate_rounded,
                color: _gold,
                size: 32,
              )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.upload_rounded, color: _ink),
          ],
        ),
      ),
    );
  }

  Widget _loginInfoBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: _ink,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.lock_rounded, color: _gold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Email: $_createdEmail\nPasswort: $_defaultPassword',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15.5,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _ink,
        fontWeight: FontWeight.w900,
        fontSize: 15,
      ),
    );
  }
}