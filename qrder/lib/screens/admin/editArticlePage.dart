import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'cloudinary_service.dart';

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
  static const Color _bg = Color(0xFFF8F6F1);
  static const Color _card = Color(0xFFFFFEFB);
  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _muted = Color(0xFF777777);
  static const Color _soft = Color(0xFFEEEBE4);
  static const Color _line = Color(0xFFE7E2D9);
  static const Color _green = Color(0xFF2F5E1C);
  static const Color _red = Color(0xFFD83A34);
  static const Color _gold = Color(0xFFD8A75D);

  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _originalPriceController =
  TextEditingController();
  final TextEditingController _articleNumberController =
  TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

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

  CollectionReference<Map<String, dynamic>> get _itemsRef {
    return FirebaseFirestore.instance
        .collection('merchants')
        .doc(_merchantId)
        .collection('items');
  }

  CollectionReference<Map<String, dynamic>> get _categoriesRef {
    return FirebaseFirestore.instance
        .collection('merchants')
        .doc(_merchantId)
        .collection('itemCategories');
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
      throw Exception('Keine Kategorien gefunden.');
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
    final category = _categories.firstWhere(
          (cat) => cat.name == widget.initialCategory,
      orElse: () => _categories.first,
    );

    _selectedCategoryId = category.id;
    _selectedCategoryName = category.name;

    _titleController.text = widget.initialName.trim();
    _priceController.text = _cleanPrice(widget.initialPrice);
    _originalPriceController.text = '';
    _descriptionController.text = '';
    _articleNumberController.text = await _nextArticleNumber();

    _optionGroups.clear();
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

    _existingSortOrder = data['sortOrder'] is int ? data['sortOrder'] as int : null;

    _selectedCategoryId = data['categoryId']?.toString();
    _selectedCategoryName = data['categoryName']?.toString();

    if (_selectedCategoryId == null ||
        !_categories.any((cat) => cat.id == _selectedCategoryId)) {
      final fallback = _categories.first;
      _selectedCategoryId = fallback.id;
      _selectedCategoryName = fallback.name;
    }

    final rawTags = data['tags'];
    if (rawTags is List) {
      _selectedTags.clear();
      _selectedTags.addAll(rawTags.map((e) => e.toString()));
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

  void _showSnack(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
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

  void _addOptionGroup() {
    setState(() {
      _optionGroups.add(OptionGroupData.empty());
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
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Artikel als Option wählen',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _existingItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _existingItems[index];

                      return ListTile(
                        tileColor: _soft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text('${item.articleNumber} · ${item.price} €'),
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
                ),
              ],
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

    if (_selectedCategoryId == null || _selectedCategoryName == null) {
      _showSnack('Bitte Kategorie wählen.');
      return;
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
        'searchName': _normalizeSearch(title),
        'optionGroups': _optionGroups.map((group) => group.toMap()).toList(),
        'isActive': true,
        'isAvailable': true,
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
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(color: _ink),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _isNew ? 'Artikel erstellen' : 'Artikel bearbeiten',
          style: const TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: _ink),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBox(),
              const SizedBox(height: 16),
              _imageBox(),
              const SizedBox(height: 16),
              _basicBox(),
              const SizedBox(height: 16),
              _tagsBox(),
              const SizedBox(height: 16),
              _optionsBox(),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveArticle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ink,
                    disabledBackgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBox() {
    return _CardBox(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _isNew ? Icons.add_rounded : Icons.edit_rounded,
              color: _ink,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              _isNew ? 'Neuer Artikel' : 'Artikel bearbeiten',
              style: const TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageBox() {
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Bild',
            subtitle: 'Optional, aber stark für Kunden.',
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: _soft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _line),
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
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.upload_rounded),
              label: const Text(
                'Bild auswählen',
                style: TextStyle(fontWeight: FontWeight.w800),
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
        Icon(Icons.image_outlined, color: _muted, size: 42),
        SizedBox(height: 10),
        Text(
          'Bild auswählen',
          style: TextStyle(
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _basicBox() {
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Grunddaten'),
          const SizedBox(height: 16),
          const _InputLabel('Titel'),
          const SizedBox(height: 8),
          _StyledInput(
            controller: _titleController,
            hintText: 'z. B. Falafel Wrap',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const _InputLabel('Preis'),
                    const SizedBox(height: 8),
                    _StyledInput(
                      controller: _priceController,
                      hintText: '5',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    const _InputLabel('Alter Preis'),
                    const SizedBox(height: 8),
                    _StyledInput(
                      controller: _originalPriceController,
                      hintText: 'optional',
                      keyboardType: TextInputType.number,
                      highlight: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _InputLabel('Artikelnummer'),
          const SizedBox(height: 8),
          _StyledInput(
            controller: _articleNumberController,
            hintText: 'z. B. 12',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          const _InputLabel('Kategorie'),
          const SizedBox(height: 8),
          _CategoryDropdown(
            categories: _categories,
            value: _selectedCategoryId,
            onChanged: (category) {
              if (category == null) return;

              setState(() {
                _selectedCategoryId = category.id;
                _selectedCategoryName = category.name;
              });
            },
          ),
          const SizedBox(height: 14),
          const _InputLabel('Beschreibung'),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            decoration: _inputDecoration('Beschreibung eingeben'),
          ),
        ],
      ),
    );
  }

  Widget _tagsBox() {
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Tags',
            subtitle: 'Zum Beispiel Halal, Vegan oder Bestseller.',
          ),
          const SizedBox(height: 14),
          if (_foodTags.isEmpty)
            const Text(
              'Keine Tags gefunden.',
              style: TextStyle(color: _muted),
            )
          else
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: _foodTags.map((tag) {
                final selected = _selectedTags.contains(tag);

                return GestureDetector(
                  onTap: () => _toggleTag(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? _ink : _soft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: selected ? Colors.white : _ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
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
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Optionen',
            subtitle:
            'Für Soße, Side, Getränk oder Extras. Maximal 1 Auswahl pro Gruppe.',
          ),
          const SizedBox(height: 14),
          if (_optionGroups.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _soft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Keine Optionen. Der Artikel kann direkt bestellt werden.',
                style: TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 12),
          ...List.generate(_optionGroups.length, (groupIndex) {
            final group = _optionGroups[groupIndex];

            return _OptionGroupBox(
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _addOptionGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Optionsgruppe hinzufügen',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* DATA */

class CategoryData {
  final String id;
  final String name;
  final bool isActive;

  const CategoryData({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory CategoryData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return CategoryData(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'Ohne Name',
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}

class ItemOptionSource {
  final String id;
  final String name;
  final String articleNumber;
  final num price;
  final bool isActive;

  const ItemOptionSource({
    required this.id,
    required this.name,
    required this.articleNumber,
    required this.price,
    required this.isActive,
  });

  factory ItemOptionSource.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return ItemOptionSource(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ??
          data['title']?.toString() ??
          'Ohne Name',
      articleNumber: data['articleNumber']?.toString() ?? '',
      price: data['price'] is num ? data['price'] as num : 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}

class OptionGroupData {
  final TextEditingController titleController;
  bool isRequired;
  final List<OptionData> options;

  OptionGroupData({
    required this.titleController,
    required this.isRequired,
    required this.options,
  });

  factory OptionGroupData.empty() {
    return OptionGroupData(
      titleController: TextEditingController(text: 'Soße wählen'),
      isRequired: false,
      options: [OptionData.empty()],
    );
  }

  factory OptionGroupData.fromMap(Map<String, dynamic> map) {
    final rawOptions = map['options'];
    final parsedOptions = <OptionData>[];

    if (rawOptions is List) {
      for (final raw in rawOptions) {
        if (raw is Map) {
          parsedOptions.add(
            OptionData.fromMap(Map<String, dynamic>.from(raw)),
          );
        }
      }
    }

    return OptionGroupData(
      titleController: TextEditingController(
        text: map['title']?.toString() ?? 'Option wählen',
      ),
      isRequired:
      map['isRequired'] as bool? ?? map['required'] as bool? ?? false,
      options: parsedOptions.isEmpty ? [OptionData.empty()] : parsedOptions,
    );
  }

  Map<String, dynamic> toMap() {
    final title = titleController.text.trim();

    return {
      'id': title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), ''),
      'title': title,
      'isRequired': isRequired,
      'minSelect': isRequired ? 1 : 0,
      'maxSelect': 1,
      'options': options.map((option) => option.toMap()).toList(),
    };
  }

  void dispose() {
    titleController.dispose();

    for (final option in options) {
      option.dispose();
    }
  }
}

class OptionData {
  final TextEditingController nameController;
  final TextEditingController priceController;

  String? linkedItemId;
  String? linkedItemName;

  OptionData({
    required this.nameController,
    required this.priceController,
    this.linkedItemId,
    this.linkedItemName,
  });

  factory OptionData.empty() {
    return OptionData(
      nameController: TextEditingController(text: ''),
      priceController: TextEditingController(text: '0'),
    );
  }

  factory OptionData.fromMap(Map<String, dynamic> map) {
    return OptionData(
      nameController: TextEditingController(
        text: map['name']?.toString() ?? '',
      ),
      priceController: TextEditingController(
        text: map['price']?.toString() ?? '0',
      ),
      linkedItemId: map['linkedItemId']?.toString(),
      linkedItemName: map['linkedItemName']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    final name = nameController.text.trim();
    final price =
        num.tryParse(priceController.text.replaceAll(',', '.').trim()) ?? 0;

    return {
      'id': name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), ''),
      'name': name,
      'price': price,
      'linkedItemId': linkedItemId,
      'linkedItemName': linkedItemName,
      'isAvailable': true,
    };
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

/* UI */

class _OptionGroupBox extends StatelessWidget {
  final OptionGroupData group;
  final VoidCallback onChanged;
  final VoidCallback onRemoveGroup;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;
  final ValueChanged<int> onChooseArticle;

  const _OptionGroupBox({
    required this.group,
    required this.onChanged,
    required this.onRemoveGroup,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onChooseArticle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E2D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InputLabel('Name der Gruppe'),
          const SizedBox(height: 8),
          _StyledInput(
            controller: group.titleController,
            hintText: 'z. B. Soße wählen',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: group.isRequired,
                onChanged: (value) {
                  group.isRequired = value ?? false;
                  onChanged();
                },
              ),
              const Expanded(
                child: Text(
                  'Pflichtauswahl',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Text(
                'Max 1',
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(group.options.length, (index) {
            final option = group.options[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7E2D9)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _StyledInput(
                          controller: option.nameController,
                          hintText: 'Option',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _StyledInput(
                          controller: option.priceController,
                          hintText: '+ €',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        onPressed: () => onRemoveOption(index),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFD83A34),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onChooseArticle(index),
                          icon: const Icon(Icons.link_rounded, size: 18),
                          label: Text(
                            option.linkedItemId == null
                                ? 'Aus Artikel wählen'
                                : 'Verknüpft: ${option.linkedItemName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (option.linkedItemId != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            option.linkedItemId = null;
                            option.linkedItemName = null;
                            onChanged();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onAddOption,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Option hinzufügen'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onRemoveGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD83A34),
                foregroundColor: Colors.white,
              ),
              child: const Text('Gruppe entfernen'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<CategoryData> categories;
  final String? value;
  final ValueChanged<CategoryData?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue =
    categories.any((category) => category.id == value) ? value : categories.first.id;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      decoration: _inputDecoration('Kategorie'),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Text(
            category.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (id) {
        if (id == null) return;

        final category = categories.firstWhere(
              (cat) => cat.id == id,
          orElse: () => categories.first,
        );

        onChanged(category);
      },
    );
  }
}

class _CardBox extends StatelessWidget {
  final Widget child;

  const _CardBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFB),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7E2D9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String text;

  const _InputLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool highlight;

  const _StyledInput({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(
        hintText,
        highlight: highlight,
      ),
    );
  }
}

InputDecoration _inputDecoration(
    String hintText, {
      bool highlight = false,
    }) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: highlight ? const Color(0xFFFFF4D8) : const Color(0xFFF3F0E9),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: highlight ? const Color(0xFFD8A75D) : const Color(0xFFE0DBD2),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: highlight ? const Color(0xFFD8A75D) : const Color(0xFFE0DBD2),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Color(0xFF1A1A1A),
        width: 1.3,
      ),
    ),
  );
}