import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EaColors {
  static const Color bg = Color(0xFFF8F6F1);
  static const Color card = Color(0xFFFFFEFB);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF777777);
  static const Color soft = Color(0xFFEEEBE4);
  static const Color line = Color(0xFFE7E2D9);
  static const Color green = Color(0xFF2F5E1C);
  static const Color red = Color(0xFFD83A34);
  static const Color gold = Color(0xFFD8A75D);
}

/* DATA */

class CategoryData {
  final String id;
  final String name;
  final bool isActive;
  final int sortOrder;

  const CategoryData({
    required this.id,
    required this.name,
    required this.isActive,
    required this.sortOrder,
  });

  factory CategoryData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return CategoryData(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'Ohne Name',
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] as int : 999999,
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
    final rawPrice = data['price'];

    return ItemOptionSource(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ??
          data['title']?.toString() ??
          'Ohne Name',
      articleNumber: data['articleNumber']?.toString() ?? '',
      price: rawPrice is num
          ? rawPrice
          : num.tryParse(rawPrice?.toString().replaceAll(',', '.') ?? '') ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}

enum OptionGroupPreset {
  sauce,
  side,
  drink,
  extra,
  custom,
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
      titleController: TextEditingController(text: 'Auswahl'),
      isRequired: false,
      options: [OptionData.empty()],
    );
  }

  factory OptionGroupData.fromPreset(OptionGroupPreset preset) {
    switch (preset) {
      case OptionGroupPreset.sauce:
        return OptionGroupData(
          titleController: TextEditingController(text: 'Soße wählen'),
          isRequired: true,
          options: [
            OptionData.named('Knoblauch', '0'),
            OptionData.named('Scharf', '0'),
            OptionData.named('Mango würzig', '0'),
          ],
        );

      case OptionGroupPreset.side:
        return OptionGroupData(
          titleController: TextEditingController(text: 'Side wählen'),
          isRequired: false,
          options: [
            OptionData.named('Pommes', '0'),
            OptionData.named('Süßkartoffeln', '1.50'),
            OptionData.named('Reis', '0'),
          ],
        );

      case OptionGroupPreset.drink:
        return OptionGroupData(
          titleController: TextEditingController(text: 'Getränk wählen'),
          isRequired: false,
          options: [
            OptionData.named('Cola', '0'),
            OptionData.named('Ayran', '0'),
            OptionData.named('Wasser', '0'),
          ],
        );

      case OptionGroupPreset.extra:
        return OptionGroupData(
          titleController: TextEditingController(text: 'Extras'),
          isRequired: false,
          options: [
            OptionData.named('Extra Fleisch', '2'),
            OptionData.named('Extra Käse', '1'),
            OptionData.named('Extra Soße', '0.50'),
          ],
        );

      case OptionGroupPreset.custom:
        return OptionGroupData.empty();
    }
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
        text: map['title']?.toString() ?? 'Auswahl',
      ),
      isRequired:
      map['isRequired'] as bool? ?? map['required'] as bool? ?? false,
      options: parsedOptions.isEmpty ? [OptionData.empty()] : parsedOptions,
    );
  }

  Map<String, dynamic> toMap(String Function(String value) slug) {
    final title = titleController.text.trim();

    return {
      'id': slug(title),
      'title': title,
      'isRequired': isRequired,
      'required': isRequired,
      'minSelect': isRequired ? 1 : 0,
      'maxSelect': 1,
      'type': 'single_choice',
      'options': options.map((option) => option.toMap(slug)).toList(),
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

  factory OptionData.named(String name, String price) {
    return OptionData(
      nameController: TextEditingController(text: name),
      priceController: TextEditingController(text: price),
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

  Map<String, dynamic> toMap(String Function(String value) slug) {
    final name = nameController.text.trim();
    final price =
        num.tryParse(priceController.text.replaceAll(',', '.').trim()) ?? 0;

    return {
      'id': slug(name),
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

class PresetButtons extends StatelessWidget {
  final ValueChanged<OptionGroupPreset> onAddPreset;

  const PresetButtons({
    super.key,
    required this.onAddPreset,
  });

  @override
  Widget build(BuildContext context) {
    final presets = [
      _PresetData('Soßen', Icons.water_drop_outlined, OptionGroupPreset.sauce),
      _PresetData('Side', Icons.fastfood_outlined, OptionGroupPreset.side),
      _PresetData(
        'Getränk',
        Icons.local_drink_outlined,
        OptionGroupPreset.drink,
      ),
      _PresetData(
        'Extras',
        Icons.add_circle_outline_rounded,
        OptionGroupPreset.extra,
      ),
      _PresetData('Leer', Icons.tune_rounded, OptionGroupPreset.custom),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schnell hinzufügen',
          style: TextStyle(
            color: EaColors.ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((preset) {
            return OutlinedButton.icon(
              onPressed: () => onAddPreset(preset.preset),
              style: OutlinedButton.styleFrom(
                foregroundColor: EaColors.ink,
                side: const BorderSide(color: EaColors.line),
                backgroundColor: EaColors.soft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              icon: Icon(preset.icon, size: 17),
              label: Text(
                preset.label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PresetData {
  final String label;
  final IconData icon;
  final OptionGroupPreset preset;

  const _PresetData(this.label, this.icon, this.preset);
}

class OptionGroupBox extends StatelessWidget {
  final int index;
  final OptionGroupData group;
  final VoidCallback onChanged;
  final VoidCallback onRemoveGroup;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;
  final ValueChanged<int> onChooseArticle;

  const OptionGroupBox({
    super.key,
    required this.index,
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
        color: EaColors.bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: EaColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: EaColors.ink,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Auswahlgruppe',
                  style: TextStyle(
                    color: EaColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemoveGroup,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: EaColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const InputLabel('Frage an den Kunden'),
          const SizedBox(height: 8),
          StyledInput(
            controller: group.titleController,
            hintText: 'z. B. Soße wählen',
          ),
          const SizedBox(height: 10),
          MiniCheckTile(
            value: group.isRequired,
            title: 'Kunde muss etwas auswählen',
            subtitle: 'Gut für Soße, Brot, Größe usw.',
            onChanged: (value) {
              group.isRequired = value;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          const InputLabel('Antworten / Optionen'),
          const SizedBox(height: 8),
          ...List.generate(group.options.length, (optionIndex) {
            final option = group.options[optionIndex];

            return OptionLineBox(
              index: optionIndex,
              option: option,
              onChanged: onChanged,
              onRemove: () => onRemoveOption(optionIndex),
              onChooseArticle: () => onChooseArticle(optionIndex),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onAddOption,
              style: OutlinedButton.styleFrom(
                foregroundColor: EaColors.ink,
                side: const BorderSide(color: EaColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Option hinzufügen',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OptionLineBox extends StatelessWidget {
  final int index;
  final OptionData option;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onChooseArticle;

  const OptionLineBox({
    super.key,
    required this.index,
    required this.option,
    required this.onChanged,
    required this.onRemove,
    required this.onChooseArticle,
  });

  @override
  Widget build(BuildContext context) {
    final linked = option.linkedItemId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EaColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EaColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: EaColors.soft,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: EaColors.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  linked ? 'Verknüpfte Option' : 'Normale Option',
                  style: const TextStyle(
                    color: EaColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.close_rounded,
                  color: EaColors.red,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const InputLabel('Name'),
          const SizedBox(height: 7),
          StyledInput(
            controller: option.nameController,
            hintText: 'z. B. Knoblauch',
          ),
          const SizedBox(height: 10),
          const InputLabel('Aufpreis'),
          const SizedBox(height: 7),
          StyledInput(
            controller: option.priceController,
            hintText: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            highlight: true,
          ),
          const SizedBox(height: 8),
          const Text(
            '0 oder leer = kostenlos. Beispiel: 1.50 bedeutet +1,50 €.',
            style: TextStyle(
              color: EaColors.muted,
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChooseArticle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EaColors.ink,
                    side: const BorderSide(color: EaColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: Text(
                    linked
                        ? 'Verknüpft: ${option.linkedItemName}'
                        : 'Optional: Artikel verknüpfen',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (linked) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    option.linkedItemId = null;
                    option.linkedItemName = null;
                    onChanged();
                  },
                  icon: const Icon(Icons.link_off_rounded),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class MiniCheckTile extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  const MiniCheckTile({
    super.key,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value ? const Color(0xFFEAF7EF) : EaColors.soft,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: value ? const Color(0xFFCDEBD8) : EaColors.line,
            ),
          ),
          child: Row(
            children: [
              Icon(
                value ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: value ? EaColors.green : EaColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: EaColors.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: EaColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

class SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EaColors.soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EaColors.line),
      ),
      child: SwitchListTile(
        value: value,
        activeColor: EaColors.ink,
        onChanged: onChanged,
        secondary: Icon(icon, color: EaColors.ink),
        title: Text(
          title,
          style: const TextStyle(
            color: EaColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: EaColors.muted,
            fontSize: 12,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class CategoryDropdown extends StatelessWidget {
  final List<CategoryData> categories;
  final String? value;
  final bool enabled;
  final ValueChanged<CategoryData?> onChanged;

  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = categories.any((category) => category.id == value)
        ? value
        : categories.first.id;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      decoration: editInputDecoration(
        enabled ? 'Kategorie' : 'Menü',
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Text(
            category.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: enabled
          ? (id) {
        if (id == null) return;

        final category = categories.firstWhere(
              (cat) => cat.id == id,
          orElse: () => categories.first,
        );

        onChanged(category);
      }
          : null,
    );
  }
}

class EditCardBox extends StatelessWidget {
  final Widget child;

  const EditCardBox({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EaColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: EaColors.line),
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

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionTitle({
    super.key,
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
            color: EaColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            style: const TextStyle(
              color: EaColors.muted,
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

class InputLabel extends StatelessWidget {
  final String text;

  const InputLabel(
      this.text, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: EaColors.ink,
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool highlight;
  final int maxLines;
  final int minLines;

  const StyledInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.highlight = false,
    this.maxLines = 1,
    this.minLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      style: const TextStyle(
        color: EaColors.ink,
        fontWeight: FontWeight.w700,
      ),
      decoration: editInputDecoration(
        hintText,
        highlight: highlight,
      ),
    );
  }
}

class SheetShell extends StatelessWidget {
  final Widget child;

  const SheetShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      decoration: const BoxDecoration(
        color: EaColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: child,
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: EaColors.line,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

InputDecoration editInputDecoration(
    String hintText, {
      bool highlight = false,
    }) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: Color(0xFFAAAAAA),
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: highlight ? const Color(0xFFFFF4D8) : const Color(0xFFF3F0E9),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: highlight ? EaColors.gold : const Color(0xFFE0DBD2),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: highlight ? EaColors.gold : const Color(0xFFE0DBD2),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: EaColors.ink,
        width: 1.3,
      ),
    ),
  );
}