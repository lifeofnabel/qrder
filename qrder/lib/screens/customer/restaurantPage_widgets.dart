import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qrder/screens/customer/translator_service.dart';
import 'package:url_launcher/url_launcher.dart';


/* -------------------------------------------------------------------------- */
/* TYPES */
/* -------------------------------------------------------------------------- */

typedef TranslateFn = String Function({
required String key,
required String text,
});

/* -------------------------------------------------------------------------- */
/* DATA */
/* -------------------------------------------------------------------------- */

class MerchantData {
  final String id;
  final String name;
  final String businessName;
  final String shopName;
  final String ownerName;
  final String description;

  final String logoUrl;
  final String coverUrl;

  final bool isActive;
  final bool isPublic;
  final String pageStyle;

  final String address;
  final String area;
  final String phone;
  final String email;

  final String website;
  final String websiteUrl;
  final String catalog;

  final String instagram;
  final String instagramUrl;
  final String tiktok;
  final String facebook;

  final String googleMaps;
  final String openingHoursText;

  const MerchantData({
    required this.id,
    required this.name,
    required this.businessName,
    required this.shopName,
    required this.ownerName,
    required this.description,
    required this.logoUrl,
    required this.coverUrl,
    required this.isActive,
    required this.isPublic,
    required this.pageStyle,
    required this.address,
    required this.area,
    required this.phone,
    required this.email,
    required this.website,
    required this.websiteUrl,
    required this.catalog,
    required this.instagram,
    required this.instagramUrl,
    required this.tiktok,
    required this.facebook,
    required this.googleMaps,
    required this.openingHoursText,
  });

  factory MerchantData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final rawStyle = data['pageStyle']?.toString() ?? 'classic';

    final pageStyle = ['classic', 'modern', 'compact'].contains(rawStyle)
        ? rawStyle
        : 'classic';

    final name = _firstNotEmpty(
      [
        data['shopName'],
        data['name'],
        data['businessName'],
      ],
      fallback: 'Restaurant',
    );

    return MerchantData(
      id: data['id']?.toString() ?? doc.id,
      name: name,
      businessName: data['businessName']?.toString() ?? name,
      shopName: data['shopName']?.toString() ?? name,
      ownerName: data['ownerName']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      logoUrl: data['logoUrl']?.toString() ?? '',
      coverUrl: data['coverUrl']?.toString() ?? '',
      isActive: data['isActive'] as bool? ?? true,
      isPublic: data['isPublic'] as bool? ?? true,
      pageStyle: pageStyle,
      address: data['address']?.toString() ?? '',
      area: data['area']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      website: data['website']?.toString() ?? '',
      websiteUrl: data['websiteUrl']?.toString() ?? '',
      catalog: data['catalog']?.toString() ?? '',
      instagram: data['instagram']?.toString() ?? '',
      instagramUrl: data['instagramUrl']?.toString() ?? '',
      tiktok: data['tiktok']?.toString() ?? '',
      facebook: data['facebook']?.toString() ?? '',
      googleMaps: data['googleMaps']?.toString() ?? '',
      openingHoursText: _parseOpeningHours(data),
    );
  }

  static String _firstNotEmpty(List<dynamic> values, {required String fallback}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static String _parseOpeningHours(Map<String, dynamic> data) {
    final direct = data['openingHoursText']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final raw = data['openingHours'];

    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }

    if (raw is Map) {
      final labels = {
        'monday': 'Mo',
        'tuesday': 'Di',
        'wednesday': 'Mi',
        'thursday': 'Do',
        'friday': 'Fr',
        'saturday': 'Sa',
        'sunday': 'So',
      };

      final lines = <String>[];

      for (final entry in labels.entries) {
        final value = raw[entry.key];

        if (value is Map) {
          final closed = value['closed'] == true;
          final open = value['open']?.toString() ?? '';
          final close = value['close']?.toString() ?? '';

          if (closed) {
            lines.add('${entry.value}: geschlossen');
          } else if (open.isNotEmpty && close.isNotEmpty) {
            lines.add('${entry.value}: $open - $close');
          }
        }
      }

      return lines.join('\n');
    }

    return '';
  }
}

class CategoryData {
  final String id;
  final String name;
  final String description;
  final int sortOrder;
  final bool isActive;

  const CategoryData({
    required this.id,
    required this.name,
    required this.description,
    required this.sortOrder,
    required this.isActive,
  });

  factory CategoryData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return CategoryData(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'Kategorie',
      description: data['description']?.toString() ?? '',
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] as int : 999999,
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}

class ArticleData {
  final String docId;
  final String id;
  final String articleNumber;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final String imageUrl;
  final dynamic price;
  final dynamic originalPrice;
  final bool isActive;
  final bool isAvailable;
  final List<String> tags;
  final List<OptionGroupData> optionGroups;

  const ArticleData({
    required this.docId,
    required this.id,
    required this.articleNumber,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.imageUrl,
    required this.price,
    required this.originalPrice,
    required this.isActive,
    required this.isAvailable,
    required this.tags,
    required this.optionGroups,
  });

  factory ArticleData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final groups = <OptionGroupData>[];
    final rawGroups = data['optionGroups'] ?? data['selectionGroups'];

    if (rawGroups is List) {
      for (final raw in rawGroups) {
        if (raw is Map) {
          groups.add(OptionGroupData.fromMap(Map<String, dynamic>.from(raw)));
        }
      }
    }

    return ArticleData(
      docId: doc.id,
      id: data['id']?.toString() ?? doc.id,
      articleNumber: data['articleNumber']?.toString() ?? '',
      title: data['title']?.toString() ?? data['name']?.toString() ?? 'Artikel',
      description: data['description']?.toString() ?? '',
      categoryId: data['categoryId']?.toString() ?? '',
      categoryName: data['categoryName']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      price: data['price'],
      originalPrice: data['originalPrice'],
      isActive: data['isActive'] as bool? ?? true,
      isAvailable: data['isAvailable'] as bool? ?? true,
      tags: _parseTags(data),
      optionGroups: groups,
    );
  }

  static List<String> _parseTags(Map<String, dynamic> data) {
    final raw = data['tags'] ?? data['badges'] ?? data['labels'];

    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    return [];
  }
}

class OptionGroupData {
  final String id;
  final String title;
  final bool isRequired;
  final List<OptionData> options;

  const OptionGroupData({
    required this.id,
    required this.title,
    required this.isRequired,
    required this.options,
  });

  factory OptionGroupData.fromMap(Map<String, dynamic> map) {
    final options = <OptionData>[];
    final rawOptions = map['options'];

    if (rawOptions is List) {
      for (final raw in rawOptions) {
        if (raw is Map) {
          options.add(OptionData.fromMap(Map<String, dynamic>.from(raw)));
        }
      }
    }

    return OptionGroupData(
      id: map['id']?.toString() ?? map['title']?.toString() ?? 'option',
      title: map['title']?.toString() ?? 'Option wählen',
      isRequired: map['isRequired'] as bool? ?? map['required'] as bool? ?? false,
      options: options,
    );
  }
}

class OptionData {
  final String id;
  final String name;
  final num price;
  final String? linkedItemId;

  const OptionData({
    required this.id,
    required this.name,
    required this.price,
    required this.linkedItemId,
  });

  factory OptionData.fromMap(Map<String, dynamic> map) {
    final rawPrice = map['price'];

    return OptionData(
      id: map['id']?.toString() ?? map['name']?.toString() ?? 'option',
      name: map['name']?.toString() ?? 'Option',
      price: rawPrice is num
          ? rawPrice
          : num.tryParse(rawPrice?.toString().replaceAll(',', '.') ?? '') ?? 0,
      linkedItemId: map['linkedItemId']?.toString(),
    );
  }
}

class SelectedOptionData {
  final String groupId;
  final String groupTitle;
  final String optionId;
  final String optionName;
  final num price;
  final String? linkedItemId;

  const SelectedOptionData({
    required this.groupId,
    required this.groupTitle,
    required this.optionId,
    required this.optionName,
    required this.price,
    required this.linkedItemId,
  });
}

class CartItemData {
  final String itemId;
  final String title;
  final String articleNumber;
  final num basePrice;
  final num singlePrice;
  final int quantity;
  final List<SelectedOptionData> selectedOptions;

  const CartItemData({
    required this.itemId,
    required this.title,
    required this.articleNumber,
    required this.basePrice,
    required this.singlePrice,
    required this.quantity,
    required this.selectedOptions,
  });

  num get totalPrice => singlePrice * quantity;
}

/* -------------------------------------------------------------------------- */
/* THEME */
/* -------------------------------------------------------------------------- */

class RestaurantUiTheme {
  final String id;
  final bool dark;
  final bool compact;
  final Color bg;
  final Color card;
  final Color ink;
  final Color muted;
  final Color soft;
  final Color line;
  final Color accent;
  final Color primaryButton;
  final Color disabledButton;
  final double headerRadius;
  final double cardRadius;
  final double gridRatio;

  const RestaurantUiTheme({
    required this.id,
    required this.dark,
    required this.compact,
    required this.bg,
    required this.card,
    required this.ink,
    required this.muted,
    required this.soft,
    required this.line,
    required this.accent,
    required this.primaryButton,
    required this.disabledButton,
    required this.headerRadius,
    required this.cardRadius,
    required this.gridRatio,
  });

  factory RestaurantUiTheme.fallback({required bool dark}) {
    return RestaurantUiTheme.fromStyle('classic', dark: dark);
  }

  factory RestaurantUiTheme.fromStyle(String style, {required bool dark}) {
    if (dark) {
      return RestaurantUiTheme(
        id: style,
        dark: true,
        compact: style == 'compact',
        bg: const Color(0xFF101010),
        card: const Color(0xFF1A1A1A),
        ink: Colors.white,
        muted: const Color(0xFFB8B8B8),
        soft: const Color(0xFF292929),
        line: const Color(0xFF333333),
        accent: const Color(0xFFD8A75D),
        primaryButton:
        style == 'modern' ? const Color(0xFFD8A75D) : Colors.white,
        disabledButton: const Color(0xFF555555),
        headerRadius: style == 'modern'
            ? 24
            : style == 'compact'
            ? 18
            : 22,
        cardRadius: style == 'modern'
            ? 28
            : style == 'compact'
            ? 18
            : 24,
        gridRatio: style == 'compact'
            ? 1.85
            : style == 'modern'
            ? 0.58
            : 0.60,
      );
    }

    switch (style) {
      case 'modern':
        return const RestaurantUiTheme(
          id: 'modern',
          dark: false,
          compact: false,
          bg: Color(0xFFF4EFE6),
          card: Color(0xFFFFFEFB),
          ink: Color(0xFF151515),
          muted: Color(0xFF6F6F6F),
          soft: Color(0xFFE9DDCB),
          line: Color(0xFFE0D0B7),
          accent: Color(0xFFC78C3C),
          primaryButton: Color(0xFF151515),
          disabledButton: Color(0xFFBEB8AE),
          headerRadius: 24,
          cardRadius: 28,
          gridRatio: 0.58,
        );

      case 'compact':
        return const RestaurantUiTheme(
          id: 'compact',
          dark: false,
          compact: true,
          bg: Color(0xFFF8F6F1),
          card: Color(0xFFFFFEFB),
          ink: Color(0xFF1A1A1A),
          muted: Color(0xFF777777),
          soft: Color(0xFFEEEBE4),
          line: Color(0xFFE7E2D9),
          accent: Color(0xFFD8A75D),
          primaryButton: Color(0xFF1A1A1A),
          disabledButton: Color(0xFFBEB8AE),
          headerRadius: 18,
          cardRadius: 18,
          gridRatio: 1.85,
        );

      case 'classic':
      default:
        return const RestaurantUiTheme(
          id: 'classic',
          dark: false,
          compact: false,
          bg: Color(0xFFF8F6F1),
          card: Color(0xFFFFFEFB),
          ink: Color(0xFF1A1A1A),
          muted: Color(0xFF777777),
          soft: Color(0xFFEEEBE4),
          line: Color(0xFFE7E2D9),
          accent: Color(0xFFD8A75D),
          primaryButton: Color(0xFF1A1A1A),
          disabledButton: Color(0xFFBEB8AE),
          headerRadius: 22,
          cardRadius: 24,
          gridRatio: 0.60,
        );
    }
  }
}

/* -------------------------------------------------------------------------- */
/* UI */
/* -------------------------------------------------------------------------- */

class TopControls extends StatelessWidget {
  final RestaurantUiTheme theme;
  final String selectedLanguage;
  final bool darkMode;
  final VoidCallback onLanguageTap;
  final VoidCallback onDarkTap;

  const TopControls({
    super.key,
    required this.theme,
    required this.selectedLanguage,
    required this.darkMode,
    required this.onLanguageTap,
    required this.onDarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final languageName =
        TranslatorService.supportedLanguages[selectedLanguage] ?? 'Original';

    return Row(
      children: [
        Expanded(
          child: _TopPill(
            theme: theme,
            icon: Icons.translate_rounded,
            label: languageName,
            onTap: onLanguageTap,
          ),
        ),
        const SizedBox(width: 10),
        _CircleButton(
          theme: theme,
          icon: darkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          onTap: onDarkTap,
        ),
      ],
    );
  }
}

class ClosedNotice extends StatelessWidget {
  final RestaurantUiTheme theme;

  const ClosedNotice({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFD83A34).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD83A34).withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD83A34),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hinweis: Dieses Restaurant ist gerade geschlossen. Du kannst alles ansehen, aber nicht bestellen.',
              style: TextStyle(
                color: theme.ink,
                fontSize: 12.5,
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

class MerchantHeader extends StatelessWidget {
  final MerchantData merchant;
  final RestaurantUiTheme theme;
  final TranslateFn translate;

  const MerchantHeader({
    super.key,
    required this.merchant,
    required this.theme,
    required this.translate,
  });

  Future<void> _openUri(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _showSnack(context, 'Konnte nicht geöffnet werden.');
    } catch (_) {
      if (context.mounted) _showSnack(context, 'Konnte nicht geöffnet werden.');
    }
  }

  void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Uri _safeUrl(String value) {
    final clean = value.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Uri.parse(clean);
    }
    return Uri.parse('https://$clean');
  }

  String _cleanHandle(String value) => value.trim().replaceAll('@', '');

  Uri _routeUri() {
    if (merchant.googleMaps.trim().isNotEmpty) {
      return _safeUrl(merchant.googleMaps);
    }

    final query = merchant.address.trim().isNotEmpty
        ? merchant.address.trim()
        : '${merchant.name} ${merchant.area}'.trim();

    return Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = merchant.logoUrl.trim().isNotEmpty;
    final hasAddress = merchant.address.trim().isNotEmpty;
    final hasPhone = merchant.phone.trim().isNotEmpty;
    final hasWebsite =
        merchant.websiteUrl.trim().isNotEmpty || merchant.website.trim().isNotEmpty;
    final hasCatalog = merchant.catalog.trim().isNotEmpty;
    final hasInstagram = merchant.instagramUrl.trim().isNotEmpty ||
        merchant.instagram.trim().isNotEmpty;
    final hasTiktok = merchant.tiktok.trim().isNotEmpty;
    final hasOpeningHours = merchant.openingHoursText.trim().isNotEmpty;

    final websiteValue =
    merchant.websiteUrl.trim().isNotEmpty ? merchant.websiteUrl : merchant.website;

    final instagramValue = merchant.instagramUrl.trim().isNotEmpty
        ? merchant.instagramUrl
        : merchant.instagram;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(theme.compact ? 13 : 15),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(theme.headerRadius),
        border: Border.all(color: theme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HeaderLogo(
                logoUrl: merchant.logoUrl,
                hasLogo: hasLogo,
                theme: theme,
                size: theme.compact ? 46 : 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translate(key: 'merchant_name_${merchant.id}', text: merchant.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.ink,
                        fontSize: theme.compact ? 18 : 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (merchant.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        translate(
                          key: 'merchant_desc_${merchant.id}',
                          text: merchant.description,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _MiniStatusDot(active: merchant.isActive),
            ],
          ),
          if (hasAddress) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _openUri(context, _routeUri()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.soft,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: theme.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.navigation_outlined, color: theme.ink, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        merchant.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.open_in_new_rounded, color: theme.muted, size: 15),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (hasPhone)
                MiniLinkChip(
                  theme: theme,
                  icon: Icons.call_outlined,
                  label: 'Anrufen',
                  onTap: () => _openUri(context, Uri(scheme: 'tel', path: merchant.phone)),
                ),
              if (hasWebsite)
                MiniLinkChip(
                  theme: theme,
                  icon: Icons.language_rounded,
                  label: 'Web',
                  onTap: () => _openUri(context, _safeUrl(websiteValue)),
                ),
              if (hasCatalog)
                MiniLinkChip(
                  theme: theme,
                  icon: Icons.menu_book_rounded,
                  label: 'Karte',
                  onTap: () => _openUri(context, _safeUrl(merchant.catalog)),
                ),
              if (hasInstagram)
                MiniLinkChip(
                  theme: theme,
                  icon: Icons.alternate_email_rounded,
                  label: 'Instagram',
                  onTap: () {
                    final raw = instagramValue.trim();
                    if (raw.startsWith('http')) {
                      _openUri(context, _safeUrl(raw));
                    } else {
                      _openUri(
                        context,
                        Uri.parse('https://instagram.com/${_cleanHandle(raw)}'),
                      );
                    }
                  },
                ),
              if (hasTiktok)
                MiniLinkChip(
                  theme: theme,
                  icon: Icons.music_note_rounded,
                  label: 'TikTok',
                  onTap: () {
                    final raw = merchant.tiktok.trim();
                    if (raw.startsWith('http')) {
                      _openUri(context, _safeUrl(raw));
                    } else {
                      _openUri(
                        context,
                        Uri.parse('https://www.tiktok.com/@${_cleanHandle(raw)}'),
                      );
                    }
                  },
                ),
              if (hasOpeningHours)
                MiniLinkChip(
                  theme: theme,
                  icon: Icons.schedule_rounded,
                  label: 'Zeiten',
                  onTap: () => openOpeningHoursSheet(context, theme, merchant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryBar extends StatelessWidget {
  final List<CategoryData> categories;
  final String selectedCategoryId;
  final RestaurantUiTheme theme;
  final TranslateFn translate;
  final ValueChanged<String> onChanged;

  const CategoryBar({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.theme,
    required this.translate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      const CategoryData(
        id: 'all',
        name: 'Alle',
        description: '',
        sortOrder: 0,
        isActive: true,
      ),
      ...categories,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((category) {
          final selected = selectedCategoryId == category.id;

          final name = category.id == 'all'
              ? 'Alle'
              : translate(key: 'category_${category.id}', text: category.name);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(category.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: EdgeInsets.symmetric(
                  horizontal: theme.compact ? 13 : 15,
                  vertical: theme.compact ? 9 : 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? theme.ink : theme.soft,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: selected ? theme.ink : theme.line),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: selected ? theme.bg : theme.ink,
                    fontSize: theme.compact ? 12 : 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FoodCard extends StatelessWidget {
  final ArticleData article;
  final RestaurantUiTheme theme;
  final String title;
  final String description;
  final String priceText;
  final String? originalPriceText;
  final VoidCallback onOpen;

  const FoodCard({
    super.key,
    required this.article,
    required this.theme,
    required this.title,
    required this.description,
    required this.priceText,
    required this.originalPriceText,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = article.imageUrl.trim().isNotEmpty;
    final disabled = !article.isAvailable;

    if (theme.compact) {
      return _CompactFoodCard(
        article: article,
        theme: theme,
        title: title,
        description: description,
        priceText: priceText,
        onOpen: onOpen,
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: disabled ? 0.48 : 1,
      child: Material(
        color: theme.card,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(theme.cardRadius),
          onTap: onOpen,
          child: Container(
            decoration: BoxDecoration(
              color: disabled ? theme.soft : theme.card,
              borderRadius: BorderRadius.circular(theme.cardRadius),
              border: Border.all(color: theme.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(theme.dark ? 0.30 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.soft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: hasImage
                              ? Image.network(
                            article.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Icon(
                                Icons.image_outlined,
                                color: theme.muted,
                                size: 36,
                              );
                            },
                          )
                              : Icon(
                            Icons.image_outlined,
                            color: theme.muted,
                            size: 36,
                          ),
                        ),
                        if (article.articleNumber.isNotEmpty)
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: _ImageBadge(theme: theme, text: article.articleNumber),
                          ),
                        if (disabled)
                          const Positioned(
                            right: 8,
                            top: 8,
                            child: _UnavailableBadge(),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article.tags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: article.tags.take(2).map((tag) {
                                return TinyChip(theme: theme, label: tag);
                              }).toList(),
                            ),
                          ),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.18,
                          ),
                        ),
                        if (description.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.muted,
                              fontSize: 11.2,
                              height: 1.23,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 5,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    priceText,
                                    style: TextStyle(
                                      color: theme.accent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (originalPriceText != null)
                                    Text(
                                      originalPriceText!,
                                      style: TextStyle(
                                        color: theme.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              disabled
                                  ? Icons.remove_circle_outline_rounded
                                  : Icons.add_circle_rounded,
                              color: disabled ? theme.muted : theme.primaryButton,
                              size: 34,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ArticleDetailImage extends StatelessWidget {
  final ArticleData article;
  final RestaurantUiTheme theme;

  const ArticleDetailImage({
    super.key,
    required this.article,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = article.imageUrl.trim().isNotEmpty;

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.soft,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
        article.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.image_outlined,
          color: theme.muted,
          size: 46,
        ),
      )
          : Icon(
        Icons.image_outlined,
        color: theme.muted,
        size: 46,
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  final RestaurantUiTheme theme;
  final String title;
  final num price;
  final bool selected;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.theme,
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceText =
    price == 0 ? '' : '+${price.toStringAsFixed(2).replaceAll('.', ',')} €';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? theme.primaryButton : theme.soft,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: selected ? theme.primaryButton : theme.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : theme.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (priceText.isNotEmpty)
              Text(
                priceText,
                style: TextStyle(
                  color: selected ? Colors.white : theme.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class QuantityButton extends StatelessWidget {
  final RestaurantUiTheme theme;
  final IconData icon;
  final VoidCallback? onTap;

  const QuantityButton({
    super.key,
    required this.theme,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? theme.disabledButton : theme.soft,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: onTap == null ? Colors.white : theme.ink,
          ),
        ),
      ),
    );
  }
}

class BasketButton extends StatelessWidget {
  final RestaurantUiTheme theme;
  final int count;
  final num total;
  final VoidCallback onTap;

  const BasketButton({
    super.key,
    required this.theme,
    required this.count,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalText = '${total.toStringAsFixed(2).replaceAll('.', ',')} €';
    final isEmpty = count == 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isEmpty ? theme.card : theme.primaryButton,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isEmpty ? theme.line : theme.primaryButton),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 18,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              color: isEmpty ? theme.ink : Colors.white,
              size: 23,
            ),
            const SizedBox(width: 10),
            Text(
              isEmpty ? 'Korb ist leer' : '$count Artikel',
              style: TextStyle(
                color: isEmpty ? theme.ink : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              totalText,
              style: TextStyle(
                color: isEmpty ? theme.muted : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartLine extends StatelessWidget {
  final RestaurantUiTheme theme;
  final CartItemData item;
  final VoidCallback onRemove;

  const CartLine({
    super.key,
    required this.theme,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final optionText = item.selectedOptions
        .map((option) => option.optionName)
        .where((text) => text.trim().isNotEmpty)
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
                style: TextStyle(
                  color: theme.ink,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (optionText.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    optionText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.totalPrice.toStringAsFixed(2).replaceAll('.', ',')} €',
            style: TextStyle(
              color: theme.accent,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close_rounded, color: theme.muted, size: 19),
          ),
        ],
      ),
    );
  }
}

class TinyChip extends StatelessWidget {
  final RestaurantUiTheme theme;
  final String label;
  final bool danger;

  const TinyChip({
    super.key,
    required this.theme,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFD83A34) : theme.soft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: danger ? Colors.white : theme.ink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class LanguageTile extends StatelessWidget {
  final RestaurantUiTheme theme;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const LanguageTile({
    super.key,
    required this.theme,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? theme.primaryButton : theme.soft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected ? Colors.white : theme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? Colors.white : theme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SheetShell extends StatelessWidget {
  final RestaurantUiTheme theme;
  final Widget child;

  const SheetShell({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: child,
    );
  }
}

class SheetHandle extends StatelessWidget {
  final RestaurantUiTheme theme;

  const SheetHandle({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: theme.line,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final RestaurantUiTheme theme;

  const EmptyState({
    super.key,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.line),
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 46, color: theme.muted),
          const SizedBox(height: 14),
          Text(
            'Keine Artikel',
            style: TextStyle(
              color: theme.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hier gibt es aktuell keine Artikel.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.muted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class CenterMessage extends StatelessWidget {
  final String text;

  const CenterMessage({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8F6F1),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Restaurant konnte nicht geladen werden.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF777777),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class ImpressumCard extends StatelessWidget {
  final MerchantData merchant;
  final RestaurantUiTheme theme;

  const ImpressumCard({
    super.key,
    required this.merchant,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final business = merchant.businessName.trim().isNotEmpty
        ? merchant.businessName
        : merchant.name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impressum',
            style: TextStyle(
              color: theme.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _InfoLine(theme: theme, label: 'Geschäft', value: business),
          if (merchant.ownerName.trim().isNotEmpty)
            _InfoLine(theme: theme, label: 'Inhaber', value: merchant.ownerName),
          if (merchant.address.trim().isNotEmpty)
            _InfoLine(theme: theme, label: 'Adresse', value: merchant.address),
          if (merchant.email.trim().isNotEmpty)
            _InfoLine(theme: theme, label: 'E-Mail', value: merchant.email),
          if (merchant.phone.trim().isNotEmpty)
            _InfoLine(theme: theme, label: 'Telefon', value: merchant.phone),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* SMALL PRIVATE WIDGETS */
/* -------------------------------------------------------------------------- */

class _TopPill extends StatelessWidget {
  final RestaurantUiTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopPill({
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.card,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: theme.line),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.ink, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: theme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final RestaurantUiTheme theme;
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({
    required this.theme,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.line),
          ),
          child: Icon(icon, color: theme.ink, size: 20),
        ),
      ),
    );
  }
}

class HeaderLogo extends StatelessWidget {
  final String logoUrl;
  final bool hasLogo;
  final RestaurantUiTheme theme;
  final double size;

  const HeaderLogo({
    super.key,
    required this.logoUrl,
    required this.hasLogo,
    required this.theme,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.soft,
        shape: BoxShape.circle,
        border: Border.all(color: theme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? Image.network(
        logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Icon(Icons.storefront_outlined, color: theme.ink, size: 28);
        },
      )
          : Icon(Icons.storefront_outlined, color: theme.ink, size: 28),
    );
  }
}

class MiniLinkChip extends StatelessWidget {
  final RestaurantUiTheme theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const MiniLinkChip({
    super.key,
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.soft,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: theme.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.ink, size: 15),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: theme.ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatusDot extends StatelessWidget {
  final bool active;

  const _MiniStatusDot({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2E9E5B) : const Color(0xFFD83A34),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CompactFoodCard extends StatelessWidget {
  final ArticleData article;
  final RestaurantUiTheme theme;
  final String title;
  final String description;
  final String priceText;
  final VoidCallback onOpen;

  const _CompactFoodCard({
    required this.article,
    required this.theme,
    required this.title,
    required this.description,
    required this.priceText,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = article.imageUrl.trim().isNotEmpty;
    final disabled = !article.isAvailable;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: disabled ? 0.48 : 1,
      child: Material(
        color: theme.card,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(theme.cardRadius),
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: disabled ? theme.soft : theme.card,
              borderRadius: BorderRadius.circular(theme.cardRadius),
              border: Border.all(color: theme.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: theme.soft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? Image.network(
                    article.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.image_outlined,
                      color: theme.muted,
                    ),
                  )
                      : Icon(Icons.image_outlined, color: theme.muted),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (description.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        priceText,
                        style: TextStyle(
                          color: theme.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  disabled
                      ? Icons.remove_circle_outline_rounded
                      : Icons.add_circle_rounded,
                  color: disabled ? theme.muted : theme.primaryButton,
                  size: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  final RestaurantUiTheme theme;
  final String text;

  const _ImageBadge({
    required this.theme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.ink,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: theme.bg,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _UnavailableBadge extends StatelessWidget {
  const _UnavailableBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Color(0xFFD83A34),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'Aus',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final RestaurantUiTheme theme;
  final String label;
  final String value;

  const _InfoLine({
    required this.theme,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: theme.muted,
          fontSize: 12.2,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* SHEET HELPERS */
/* -------------------------------------------------------------------------- */

void openOpeningHoursSheet(
    BuildContext context,
    RestaurantUiTheme theme,
    MerchantData merchant,
    ) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return SheetShell(
        theme: theme,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetHandle(theme: theme),
              const SizedBox(height: 16),
              Text(
                'Öffnungszeiten',
                style: TextStyle(
                  color: theme.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                merchant.openingHoursText.isEmpty
                    ? 'Keine Öffnungszeiten hinterlegt.'
                    : merchant.openingHoursText,
                style: TextStyle(
                  color: theme.muted,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}