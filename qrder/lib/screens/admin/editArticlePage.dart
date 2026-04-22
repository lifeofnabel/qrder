import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  File? _selectedImage;

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _articleNumberController;
  late TextEditingController _descriptionController;

  late String _selectedCategory;

  final List<String> _categories = [
    'Wraps',
    'Bowls',
    'Getränke',
    'Menüs',
  ];

  final List<String> _availableTags = [
    'Spicy',
    'Vegan',
    'Vegetarisch',
    'Bestseller',
    'Fisch',
    'Schwein',
    'Hähnchen',
    'Halal',
    'Beef',
  ];

  final Set<String> _selectedTags = {};

  final List<String> _allArticles = [
    'Hähnchenwrap',
    'Falafel Wrap',
    'Halloumi Wrap',
    'Pommes',
    'Süßkartoffel',
    'Cola',
    'Ayran',
    'Wasser',
    'Knoblauchsoße',
    'Scharfe Soße',
  ];

  final List<_SelectionGroup> _selectionGroups = [
    _SelectionGroup(
      titleController: TextEditingController(text: 'Soße'),
      isEnabled: true,
      options: [
        _SelectionOption(
          nameController: TextEditingController(text: 'Knoblauchsoße'),
          priceController: TextEditingController(text: '0'),
        ),
        _SelectionOption(
          nameController: TextEditingController(text: 'Scharfe Soße'),
          priceController: TextEditingController(text: '0'),
        ),
      ],
    ),
    _SelectionGroup(
      titleController: TextEditingController(text: 'Side'),
      isEnabled: true,
      options: [
        _SelectionOption(
          nameController: TextEditingController(text: 'Pommes'),
          priceController: TextEditingController(text: '1'),
        ),
        _SelectionOption(
          nameController: TextEditingController(text: 'Süßkartoffel'),
          priceController: TextEditingController(text: '2'),
        ),
      ],
    ),
    _SelectionGroup(
      titleController: TextEditingController(text: 'Getränk Upgrade'),
      isEnabled: false,
      options: [
        _SelectionOption(
          nameController: TextEditingController(text: 'Cola'),
          priceController: TextEditingController(text: '2'),
        ),
      ],
    ),
  ];

  bool _hasLinkedArticles = true;
  int _linkedArticleCount = 2;
  List<String?> _linkedArticleSelections = ['Hähnchenwrap', 'Pommes'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialName);
    _priceController = TextEditingController(text: widget.initialPrice);
    _articleNumberController = TextEditingController(text: widget.articleId);
    _descriptionController = TextEditingController(
      text:
      'Leckerer Artikel mit anpassbaren Optionen. Perfekt für individuelle Bestellungen.',
    );
    _selectedCategory = widget.initialCategory;
    _selectedTags.addAll(['Hähnchen', 'Halal']);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _articleNumberController.dispose();
    _descriptionController.dispose();

    for (final group in _selectionGroups) {
      group.titleController.dispose();
      for (final option in group.options) {
        option.nameController.dispose();
        option.priceController.dispose();
      }
    }

    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
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

  void _addSelectionGroup() {
    setState(() {
      _selectionGroups.add(
        _SelectionGroup(
          titleController: TextEditingController(
            text: 'Neue Auswahlgruppe',
          ),
          isEnabled: true,
          options: [
            _SelectionOption(
              nameController: TextEditingController(text: 'Option 1'),
              priceController: TextEditingController(text: '0'),
            ),
          ],
        ),
      );
    });
  }

  void _removeSelectionGroup(int index) {
    final group = _selectionGroups[index];
    group.titleController.dispose();
    for (final option in group.options) {
      option.nameController.dispose();
      option.priceController.dispose();
    }

    setState(() {
      _selectionGroups.removeAt(index);
    });
  }

  void _addOptionToGroup(int groupIndex) {
    setState(() {
      _selectionGroups[groupIndex].options.add(
        _SelectionOption(
          nameController: TextEditingController(
            text: 'Neue Option ${_selectionGroups[groupIndex].options.length + 1}',
          ),
          priceController: TextEditingController(text: '0'),
        ),
      );
    });
  }

  void _removeOptionFromGroup(int groupIndex, int optionIndex) {
    final option = _selectionGroups[groupIndex].options[optionIndex];
    option.nameController.dispose();
    option.priceController.dispose();

    setState(() {
      _selectionGroups[groupIndex].options.removeAt(optionIndex);
    });
  }

  void _updateLinkedArticleCount(int count) {
    setState(() {
      _linkedArticleCount = count;
      if (_linkedArticleSelections.length < count) {
        _linkedArticleSelections.addAll(
          List.generate(count - _linkedArticleSelections.length, (_) => null),
        );
      } else if (_linkedArticleSelections.length > count) {
        _linkedArticleSelections = _linkedArticleSelections.sublist(0, count);
      }
    });
  }

  void _saveArticle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Artikel gespeichert.'),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ],
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
          'Artikel bearbeiten',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bearbeite hier Bild, Titel, Preis, Tags, Beschreibung und alle Auswahlmöglichkeiten.',
                style: TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),

              _CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Bild'),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEBE4),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFE0DBD2),
                            width: 1,
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                            : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 42,
                              color: Color(0xFF777777),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Bild auswählen',
                              style: TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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
                        onPressed: _pickImage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A1A1A),
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.upload_rounded),
                        label: const Text('Bild hochladen'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Grunddaten'),
                    const SizedBox(height: 16),
                    _InputLabel('Titel'),
                    const SizedBox(height: 8),
                    _StyledInput(controller: _titleController, hintText: 'Titel'),
                    const SizedBox(height: 14),
                    _InputLabel('Preis'),
                    const SizedBox(height: 8),
                    _StyledInput(
                      controller: _priceController,
                      hintText: 'z. B. 5.00',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    _InputLabel('Artikelnummer'),
                    const SizedBox(height: 8),
                    _StyledInput(
                      controller: _articleNumberController,
                      hintText: 'Artikelnummer',
                    ),
                    const SizedBox(height: 14),
                    _InputLabel('Kategorie'),
                    const SizedBox(height: 8),
                    _DropdownBox<String>(
                      value: _selectedCategory,
                      items: _categories,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _InputLabel('Beschreibung'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 6,
                      decoration: _inputDecoration('Beschreibung eingeben'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Tags',
                      subtitle: 'Mehrere Tags gleichzeitig möglich.',
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _availableTags.map((tag) {
                        final selected = _selectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () => _toggleTag(tag),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFFEEEBE4),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF555555),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Auswahlgruppen',
                      subtitle:
                      'Zum Beispiel Soße, Brot, Side oder Getränk. Pro Gruppe genau eine Auswahl.',
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_selectionGroups.length, (groupIndex) {
                      final group = _selectionGroups[groupIndex];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F6F1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE7E2D9),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Gruppe aktiv',
                                      style: TextStyle(
                                        color: Color(0xFF1A1A1A),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: group.isEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        group.isEnabled = value;
                                      });
                                    },
                                    activeColor: const Color(0xFF1A1A1A),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _InputLabel('Gruppenname'),
                              const SizedBox(height: 8),
                              _StyledInput(
                                controller: group.titleController,
                                hintText: 'z. B. Soße',
                              ),
                              const SizedBox(height: 14),

                              if (group.isEnabled) ...[
                                const Text(
                                  'Optionen',
                                  style: TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                ...List.generate(group.options.length, (optionIndex) {
                                  final option = group.options[optionIndex];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: TextField(
                                            controller: option.nameController,
                                            decoration: _inputDecoration('Option'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: TextField(
                                            controller: option.priceController,
                                            keyboardType: TextInputType.number,
                                            decoration: _inputDecoration('Aufpreis'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        GestureDetector(
                                          onTap: () =>
                                              _removeOptionFromGroup(groupIndex, optionIndex),
                                          child: Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD83A34),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _addOptionToGroup(groupIndex),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF1A1A1A),
                                      side: const BorderSide(
                                        color: Color(0xFFDDDDDD),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Option hinzufügen'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => _removeSelectionGroup(groupIndex),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD83A34),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text('Gruppe löschen'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _addSelectionGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F5E1C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Neue Auswahlgruppe hinzufügen'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _CardBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Verknüpfte Artikel',
                      subtitle:
                      'Zum Beispiel für Menü-Kombis wie Wrap + Side + Getränk.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Verknüpfte Artikel aktivieren?',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Switch(
                          value: _hasLinkedArticles,
                          onChanged: (value) {
                            setState(() {
                              _hasLinkedArticles = value;
                            });
                          },
                          activeColor: const Color(0xFF1A1A1A),
                        ),
                      ],
                    ),
                    if (_hasLinkedArticles) ...[
                      const SizedBox(height: 10),
                      _InputLabel('Wie viele Artikel verknüpfen?'),
                      const SizedBox(height: 8),
                      _DropdownBox<int>(
                        value: _linkedArticleCount,
                        items: [1, 2, 3, 4, 5],
                        onChanged: (value) {
                          if (value == null) return;
                          _updateLinkedArticleCount(value);
                        },
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(_linkedArticleCount, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verknüpfter Artikel ${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _DropdownBox<String>(
                                value: _linkedArticleSelections[index],
                                items: _allArticles,
                                onChanged: (value) {
                                  setState(() {
                                    _linkedArticleSelections[index] = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveArticle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Artikel speichern',
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
      ),
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
      child: child,
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String text;

  const _InputLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;

  const _StyledInput({
    required this.controller,
    required this.hintText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hintText),
    );
  }
}

class _DropdownBox<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;

  const _DropdownBox({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0DBD2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFFFDFCF9),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: Color(0xFFAAAAAA),
      fontSize: 15,
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
  );
}

class _SelectionGroup {
  TextEditingController titleController;
  bool isEnabled;
  List<_SelectionOption> options;

  _SelectionGroup({
    required this.titleController,
    required this.isEnabled,
    required this.options,
  });
}

class _SelectionOption {
  TextEditingController nameController;
  TextEditingController priceController;

  _SelectionOption({
    required this.nameController,
    required this.priceController,
  });
}