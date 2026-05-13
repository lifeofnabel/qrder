import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/cloudinary_service.dart';
import 'editArticleParts.dart';

class EditArticlePage extends StatefulWidget {
  final String articleId;
  final String initialName;
  final String initialPrice;
  final String initialCategory;

  const EditArticlePage({
    super.key,
    required this.articleId,
    required this.initialName,
    required this.initialPrice,
    required this.initialCategory,
  });

  @override
  State<EditArticlePage> createState() => _EditArticlePageState();
}

class _EditArticlePageState extends State<EditArticlePage> {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _articleNumberController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isMenuItem = false;
  bool _isAvailable = true;
  bool _isActive = true;

  String? _selectedCategoryId;
  String? _selectedCategoryName;

  String _imageUrl = '';
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  int? _existingSortOrder;

  List<CategoryData> _categories = [];
  List<ItemOptionSource> _existingItems = [];
  List<String> _foodTags = [];

  final Set<String> _selectedTags = {};
  final List<OptionGroupData> _optionGroups = [];

  bool get _isNew => widget.articleId.trim().isEmpty;

  String? get _merchantId => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _merchantRef {
    return FirebaseFirestore.instance.collection('merchants').doc(_merchantId);
  }

  CollectionReference<Map<String, dynamic>> get _itemsRef {
    return _merchantRef.collection('items');
  }

  CollectionReference<Map<String, dynamic>> get _categoriesRef {
    return _merchantRef.collection('itemCategories');
  }

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _articleNumberController.dispose();
    _descriptionController.dispose();

    for (final group in _optionGroups) {
      group.dispose();
    }

    super.dispose();
  }

  Future<void> _boot() async {
    try {
      if (_merchantId == null) {
        throw Exception('Kein Händler eingeloggt.');
      }

      await _loadCategories();
      await _loadFoodTags();
      await _loadExistingItems();

      if (_isNew) {
        await _prepareNewArticle();
      } else {
        await _loadArticle();
      }
    } catch (e) {
      _showSnack('Laden fehlgeschlagen: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _loadCategories() async {
    final snap = await _categoriesRef.orderBy('sortOrder').get();

    _categories = snap.docs
        .map((doc) => CategoryData.fromDoc(doc))
        .where((category) => category.isActive)
        .toList();

    if (_categories.isEmpty) {
      final defaultRef = _categoriesRef.doc();

      await defaultRef.set({
        'id': defaultRef.id,
        'name': 'Allgemein',
        'description': '',
        'sortOrder': 1,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _categories = [
        CategoryData(
          id: defaultRef.id,
          name: 'Allgemein',
          isActive: true,
          sortOrder: 1,
        ),
      ];
    }
  }

  Future<void> _loadFoodTags() async {
    final doc = await FirebaseFirestore.instance
        .collection('chooser')
        .doc('foodTags')
        .get();

    final raw = doc.data()?['name'];

    if (raw is List) {
      _foodTags = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      _foodTags.sort();
    }

    if (_foodTags.isEmpty) {
      _foodTags = [
        'Bestseller',
        'Neu',
        'Vegan',
        'Vegetarisch',
        'Halal',
        'Scharf',
        'Angebot',
      ];
    }
  }

  Future<void> _loadExistingItems() async {
    final snap = await _itemsRef.get();

    _existingItems = snap.docs
        .map((doc) => ItemOptionSource.fromDoc(doc))
        .where((item) => item.isActive)
        .toList();

    _existingItems.sort((a, b) {
      final aNumber = int.tryParse(a.articleNumber) ?? 999999;
      final bNumber = int.tryParse(b.articleNumber) ?? 999999;
      return aNumber.compareTo(bNumber);
    });
  }

  Future<void> _prepareNewArticle() async {
    final initialCategory = widget.initialCategory.trim();

    final category = _categories.firstWhere(
          (cat) => cat.name.toLowerCase() == initialCategory.toLowerCase(),
      orElse: () => _categories.first,
    );

    _selectedCategoryId = category.id;
    _selectedCategoryName = category.name;

    _titleController.text = widget.initialName.trim();
    _priceController.text = _cleanPrice(widget.initialPrice);
    _originalPriceController.text = '';
    _descriptionController.text = '';
    _articleNumberController.text = await _nextArticleNumber();

    _isMenuItem =
        _looksLikeMenu(widget.initialName) || _looksLikeMenu(widget.initialCategory);

    if (_isMenuItem) {
      await _selectOrCreateMenuCategory();
    }
  }

  Future<void> _loadArticle() async {
    final doc = await _itemsRef.doc(widget.articleId).get();

    if (!doc.exists || doc.data() == null) {
      await _prepareNewArticle();
      return;
    }

    final data = doc.data()!;

    _titleController.text =
        data['title']?.toString() ?? data['name']?.toString() ?? '';
    _priceController.text = _valueToInput(data['price']);
    _originalPriceController.text = _valueToInput(data['originalPrice']);
    _articleNumberController.text = data['articleNumber']?.toString() ?? '';
    _descriptionController.text = data['description']?.toString() ?? '';
    _imageUrl = data['imageUrl']?.toString() ?? '';

    _existingSortOrder =
    data['sortOrder'] is int ? data['sortOrder'] as int : null;

    _isAvailable = data['isAvailable'] as bool? ?? true;
    _isActive = data['isActive'] as bool? ?? true;

    _selectedCategoryId = data['categoryId']?.toString();
    _selectedCategoryName = data['categoryName']?.toString();

    _isMenuItem = data['isMenuItem'] as bool? ??
        _looksLikeMenu(_selectedCategoryName ?? '') ||
            _looksLikeMenu(_titleController.text);

    if (_selectedCategoryId == null ||
        !_categories.any((cat) => cat.id == _selectedCategoryId)) {
      final fallback = _categories.first;
      _selectedCategoryId = fallback.id;
      _selectedCategoryName = fallback.name;
    }

    final rawTags = data['tags'];
    if (rawTags is List) {
      _selectedTags.clear();
      _selectedTags.addAll(
        rawTags
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty),
      );
    }

    final rawGroups = data['optionGroups'] ?? data['selectionGroups'];
    if (rawGroups is List) {
      _optionGroups.clear();

      for (final raw in rawGroups) {
        if (raw is Map) {
          _optionGroups.add(
            OptionGroupData.fromMap(Map<String, dynamic>.from(raw)),
          );
        }
      }
    }
  }

  bool _looksLikeMenu(String value) {
    final clean = value.trim().toLowerCase();
    return clean.contains('menü') || clean.contains('menu');
  }

  Future<void> _selectOrCreateMenuCategory() async {
    final existing = _categories.where((cat) {
      final name = cat.name.toLowerCase();
      return name == 'menü' || name == 'menu';
    }).toList();

    if (existing.isNotEmpty) {
      _selectedCategoryId = existing.first.id;
      _selectedCategoryName = existing.first.name;
      return;
    }

    final ref = _categoriesRef.doc();
    final sortOrder = _categories.length + 1;

    await ref.set({
      'id': ref.id,
      'name': 'Menü',
      'sortOrder': sortOrder,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final menuCategory = CategoryData(
      id: ref.id,
      name: 'Menü',
      isActive: true,
      sortOrder: sortOrder,
    );

    _categories.add(menuCategory);

    _selectedCategoryId = menuCategory.id;
    _selectedCategoryName = menuCategory.name;
  }

  Future<String> _nextArticleNumber() async {
    final snap = await _itemsRef.get();
    final used = <int>{};

    for (final doc in snap.docs) {
      final number = int.tryParse(doc.data()['articleNumber']?.toString() ?? '');
      if (number != null && number > 0) {
        used.add(number);
      }
    }

    var next = 1;
    while (used.contains(next)) {
      next++;
    }

    return next.toString();
  }

  String _cleanPrice(String value) {
    return value.replaceAll('€', '').replaceAll(',', '.').trim();
  }

  String _valueToInput(dynamic value) {
    if (value == null) return '';
    if (value is num) return value.toString();
    return value.toString().replaceAll('€', '').replaceAll(',', '.').trim();
  }

  num _parsePrice(String value) {
    final clean = value.replaceAll('€', '').replaceAll(',', '.').trim();
    return num.tryParse(clean) ?? 0;
  }

  String _normalizeSearch(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _slug(String value) {
    final clean = _normalizeSearch(value).replaceAll(' ', '-');
    return clean.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : clean;
  }

  void _showSnack(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
      maxWidth: 1800,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _pickedImage = picked;
      _pickedImageBytes = bytes;
    });
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _toggleMenuMode(bool value) async {
    setState(() {
      _isMenuItem = value;
    });

    if (value) {
      await _selectOrCreateMenuCategory();
      if (mounted) setState(() {});
    }
  }

  void _addOptionGroupPreset(OptionGroupPreset preset) {
    setState(() {
      _optionGroups.add(OptionGroupData.fromPreset(preset));
    });
  }

  void _removeOptionGroup(int index) {
    final group = _optionGroups.removeAt(index);
    group.dispose();
    setState(() {});
  }

  void _addOption(int groupIndex) {
    setState(() {
      _optionGroups[groupIndex].options.add(OptionData.empty());
    });
  }

  void _removeOption(int groupIndex, int optionIndex) {
    if (_optionGroups[groupIndex].options.length <= 1) {
      _showSnack('Mindestens eine Option bleibt drin.');
      return;
    }

    final option = _optionGroups[groupIndex].options.removeAt(optionIndex);
    option.dispose();
    setState(() {});
  }

  Future<void> _chooseExistingItemForOption({
    required int groupIndex,
    required int optionIndex,
  }) async {
    if (_existingItems.isEmpty) {
      _showSnack('Keine vorhandenen Artikel gefunden.');
      return;
    }

    final chosen = await showModalBottomSheet<ItemOptionSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return SheetShell(
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.78,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SheetHandle(),
                  const SizedBox(height: 18),
                  const Text(
                    'Artikel verknüpfen',
                    style: TextStyle(
                      color: EaColors.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Optional: Nutze einen bestehenden Artikel als auswählbare Option.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: EaColors.muted,
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _existingItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _existingItems[index];

                        return Material(
                          color: EaColors.soft,
                          borderRadius: BorderRadius.circular(17),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(17),
                            onTap: () => Navigator.pop(context, item),
                            child: Padding(
                              padding: const EdgeInsets.all(13),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: EaColors.ink,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.articleNumber.isEmpty
                                            ? '#'
                                            : item.articleNumber,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: EaColors.ink,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${item.price.toStringAsFixed(2).replaceAll('.', ',')} €',
                                          style: const TextStyle(
                                            color: EaColors.muted,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: EaColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (chosen == null) return;

    final option = _optionGroups[groupIndex].options[optionIndex];

    setState(() {
      option.nameController.text = chosen.name;
      option.priceController.text = '0';
      option.linkedItemId = chosen.id;
      option.linkedItemName = chosen.name;
    });
  }

  Future<void> _saveArticle() async {
    final merchantId = _merchantId;

    if (merchantId == null) {
      _showSnack('Kein Händler gefunden.');
      return;
    }

    final title = _titleController.text.trim();
    final articleNumber = _articleNumberController.text.trim();

    if (title.isEmpty) {
      _showSnack('Bitte Titel eingeben.');
      return;
    }

    if (articleNumber.isEmpty) {
      _showSnack('Bitte Artikelnummer eingeben.');
      return;
    }

    if (_isMenuItem) {
      await _selectOrCreateMenuCategory();
    }

    if (_selectedCategoryId == null || _selectedCategoryName == null) {
      _showSnack('Bitte Kategorie wählen.');
      return;
    }

    for (final group in _optionGroups) {
      if (group.titleController.text.trim().isEmpty) {
        _showSnack('Eine Optionsgruppe hat keinen Namen.');
        return;
      }

      for (final option in group.options) {
        if (option.nameController.text.trim().isEmpty) {
          _showSnack('Eine Option hat keinen Namen.');
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    try {
      String finalImageUrl = _imageUrl;

      if (_pickedImage != null) {
        finalImageUrl = await CloudinaryService.uploadImage(_pickedImage!);
      }

      final itemId =
      _isNew ? DateTime.now().millisecondsSinceEpoch.toString() : widget.articleId;

      final price = _parsePrice(_priceController.text);

      final originalPrice = _originalPriceController.text.trim().isEmpty
          ? null
          : _parsePrice(_originalPriceController.text);

      final searchName = _normalizeSearch(title);

      final data = <String, dynamic>{
        'id': itemId,
        'merchantId': merchantId,

        'articleNumber': articleNumber,

        'name': title,
        'title': title,
        'description': _descriptionController.text.trim(),

        'categoryId': _selectedCategoryId,
        'categoryName': _selectedCategoryName,

        'price': price,
        'originalPrice': originalPrice,

        'imageUrl': finalImageUrl,

        'tags': _selectedTags.toList(),

        'searchName': searchName,
        'searchKeywords': searchName.isEmpty ? [] : searchName.split(' '),

        'optionGroups': _optionGroups.map((group) => group.toMap(_slug)).toList(),

        'isMenuItem': _isMenuItem,
        'isActive': _isActive,
        'isAvailable': _isAvailable,

        'type': 'merchant_item',
        'sortOrder': _existingSortOrder ?? DateTime.now().millisecondsSinceEpoch,

        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isNew) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await _itemsRef.doc(itemId).set(data, SetOptions(merge: true));

      if (!mounted) return;

      _showSnack('Artikel gespeichert.');
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Speichern fehlgeschlagen: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: EaColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: EaColors.ink),
        ),
      );
    }

    return Scaffold(
      backgroundColor: EaColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              const SizedBox(height: 18),
              _heroBox(),
              const SizedBox(height: 14),
              _statusBox(),
              const SizedBox(height: 14),
              _imageBox(),
              const SizedBox(height: 14),
              _basicBox(),
              const SizedBox(height: 14),
              _tagsBox(),
              const SizedBox(height: 14),
              _optionsBox(),
              const SizedBox(height: 22),
              _saveButton(),
            ],
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
            backgroundColor: EaColors.soft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.arrow_back_rounded, color: EaColors.ink),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: EaColors.soft,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            _isNew ? 'Neuer Artikel' : 'Bearbeiten',
            style: const TextStyle(
              color: EaColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroBox() {
    return EditCardBox(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: EaColors.ink,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _isNew ? Icons.add_rounded : Icons.edit_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Artikel bearbeiten',
                  style: TextStyle(
                    color: EaColors.ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Name, Preis, Bild, Tags und Auswahloptionen pflegen.',
                  style: TextStyle(
                    color: EaColors.muted,
                    fontSize: 13.2,
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

  Widget _statusBox() {
    return EditCardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Status',
            subtitle:
            'Steuert, ob der Artikel öffentlich sichtbar und bestellbar ist.',
          ),
          const SizedBox(height: 14),
          SwitchRow(
            title: 'Artikel sichtbar',
            subtitle: 'Wenn aus, wird der Artikel nicht angezeigt.',
            icon: Icons.visibility_outlined,
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
          ),
          const SizedBox(height: 10),
          SwitchRow(
            title: 'Aktuell verfügbar',
            subtitle: 'Wenn aus, erscheint er grau und kann nicht bestellt werden.',
            icon: Icons.event_available_rounded,
            value: _isAvailable,
            onChanged: (value) => setState(() => _isAvailable = value),
          ),
        ],
      ),
    );
  }

  Widget _imageBox() {
    return EditCardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Bild',
            subtitle: 'Ein gutes Bild verkauft schneller als lange Texte.',
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                color: EaColors.soft,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: EaColors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: _pickedImageBytes != null
                  ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                  : _imageUrl.isNotEmpty
                  ? Image.network(
                _imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              )
                  : _imagePlaceholder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              style: OutlinedButton.styleFrom(
                foregroundColor: EaColors.ink,
                side: const BorderSide(color: EaColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.upload_rounded),
              label: const Text(
                'Bild auswählen',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, color: EaColors.muted, size: 44),
        SizedBox(height: 10),
        Text(
          'Bild auswählen',
          style: TextStyle(
            color: EaColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _basicBox() {
    return EditCardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Grunddaten',
            subtitle: 'Das sieht der Kunde direkt auf der Karte.',
          ),
          const SizedBox(height: 16),

          const InputLabel('Titel'),
          const SizedBox(height: 8),
          StyledInput(
            controller: _titleController,
            hintText: 'z. B. Pizza',
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const InputLabel('Preis'),
                    const SizedBox(height: 8),
                    StyledInput(
                      controller: _priceController,
                      hintText: '6.50',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    const InputLabel('Alter Preis'),
                    const SizedBox(height: 8),
                    StyledInput(
                      controller: _originalPriceController,
                      hintText: 'optional',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      highlight: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const InputLabel('Artikelnummer'),
          const SizedBox(height: 8),
          StyledInput(
            controller: _articleNumberController,
            hintText: 'z. B. 12',
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 14),

          const InputLabel('Kategorie'),
          const SizedBox(height: 8),
          CategoryDropdown(
            categories: _categories,
            value: _selectedCategoryId,
            enabled: !_isMenuItem,
            onChanged: (category) {
              if (category == null) return;

              setState(() {
                _selectedCategoryId = category.id;
                _selectedCategoryName = category.name;
              });
            },
          ),

          if (_isMenuItem) ...[
            const SizedBox(height: 8),
            const Text(
              'Menü-Modus aktiv: Kategorie wird automatisch auf „Menü“ gesetzt.',
              style: TextStyle(
                color: EaColors.gold,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],

          const SizedBox(height: 14),

          const InputLabel('Beschreibung'),
          const SizedBox(height: 8),
          StyledInput(
            controller: _descriptionController,
            hintText: 'z. B. Hähnchen, Knoblauchcreme, Salat, Tomate',
            minLines: 3,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _tagsBox() {
    return EditCardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Tags',
            subtitle: 'Kleine Hinweise wie Halal, Vegan oder Bestseller.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: _foodTags.map((tag) {
              final selected = _selectedTags.contains(tag);

              return GestureDetector(
                onTap: () => _toggleTag(tag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? EaColors.ink : EaColors.soft,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected ? EaColors.ink : EaColors.line,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: selected ? Colors.white : EaColors.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _optionsBox() {
    return EditCardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Auswahl für Kunden',
            subtitle: 'Nur nutzen, wenn der Kunde beim Artikel etwas wählen soll.',
          ),
          const SizedBox(height: 14),

          if (_optionGroups.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EaColors.soft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: EaColors.line),
              ),
              child: const Text(
                'Keine Auswahl nötig. Kunde kann diesen Artikel direkt in den Korb legen.',
                style: TextStyle(
                  color: EaColors.muted,
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...List.generate(_optionGroups.length, (groupIndex) {
              final group = _optionGroups[groupIndex];

              return OptionGroupBox(
                key: ValueKey('option_group_$groupIndex'),
                index: groupIndex,
                group: group,
                onChanged: () => setState(() {}),
                onRemoveGroup: () => _removeOptionGroup(groupIndex),
                onAddOption: () => _addOption(groupIndex),
                onRemoveOption: (optionIndex) {
                  _removeOption(groupIndex, optionIndex);
                },
                onChooseArticle: (optionIndex) {
                  _chooseExistingItemForOption(
                    groupIndex: groupIndex,
                    optionIndex: optionIndex,
                  );
                },
              );
            }),

          const SizedBox(height: 14),

          PresetButtons(
            onAddPreset: _addOptionGroupPreset,
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveArticle,
        style: ElevatedButton.styleFrom(
          backgroundColor: EaColors.ink,
          disabledBackgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.4,
          ),
        )
            : const Text(
          'Artikel speichern',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}