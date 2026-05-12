import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'restaurantPage_widgets.dart';
import 'shoppingBasketPage.dart';
import 'translator_service.dart';

class RestaurantPage extends StatefulWidget {
  const RestaurantPage({
    super.key,
    required this.merchantId,
  });

  final String merchantId;

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  String _selectedCategoryId = 'all';
  String _selectedLanguage = 'original';

  // Nachtmodus standardmäßig AN
  bool _darkMode = true;

  final List<CartItemData> _cartItems = [];

  final Map<String, String> _translationCache = {};
  final Set<String> _pendingTranslations = {};

  DocumentReference<Map<String, dynamic>> get _merchantRef {
    return FirebaseFirestore.instance
        .collection('merchants')
        .doc(widget.merchantId);
  }

  CollectionReference<Map<String, dynamic>> get _categoriesRef {
    return _merchantRef.collection('itemCategories');
  }

  CollectionReference<Map<String, dynamic>> get _itemsRef {
    return _merchantRef.collection('items');
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0,00 €';

    final number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;

    return '${number.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  num _priceAsNumber(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  bool _hasOriginalPrice(ArticleData article) {
    if (article.originalPrice == null) return false;

    final original = _priceAsNumber(article.originalPrice);
    final current = _priceAsNumber(article.price);

    return original > 0 && original > current;
  }

  List<CategoryData> _visibleCategories({
    required List<CategoryData> categories,
    required List<ArticleData> articles,
  }) {
    final activeCategoryIds = articles
        .where((item) => item.isActive)
        .map((item) => item.categoryId)
        .toSet();

    return categories.where((cat) {
      return cat.isActive && activeCategoryIds.contains(cat.id);
    }).toList();
  }

  List<ArticleData> _filteredArticles(List<ArticleData> articles) {
    if (_selectedCategoryId == 'all') return articles;

    return articles
        .where((article) => article.categoryId == _selectedCategoryId)
        .toList();
  }

  String _tr({
    required String key,
    required String text,
  }) {
    final cleanText = text.trim();

    if (_selectedLanguage == 'original' || cleanText.isEmpty) {
      return text;
    }

    final cacheKey = '$_selectedLanguage::$key::$cleanText';

    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    if (!_pendingTranslations.contains(cacheKey)) {
      _pendingTranslations.add(cacheKey);

      TranslatorService.translate(
        text: cleanText,
        targetLang: _selectedLanguage,
      ).then((translated) {
        if (!mounted) return;

        setState(() {
          _translationCache[cacheKey] = translated;
          _pendingTranslations.remove(cacheKey);
        });
      }).catchError((_) {
        if (!mounted) return;

        setState(() {
          _translationCache[cacheKey] = text;
          _pendingTranslations.remove(cacheKey);
        });
      });
    }

    return text;
  }

  Future<void> _openLanguageSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = RestaurantUiTheme.fallback(dark: _darkMode);

        return SheetShell(
          theme: theme,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SheetHandle(theme: theme),
                const SizedBox(height: 16),
                Text(
                  'Sprache auswählen',
                  style: TextStyle(
                    color: theme.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                ...TranslatorService.supportedLanguages.entries.map((entry) {
                  final selected = _selectedLanguage == entry.key;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LanguageTile(
                      theme: theme,
                      title: entry.value,
                      selected: selected,
                      onTap: () => Navigator.pop(context, entry.key),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _selectedLanguage = selected;
    });
  }

  void _toggleDarkMode() {
    setState(() {
      _darkMode = !_darkMode;
    });
  }

  void _addToCart({
    required ArticleData article,
    required List<SelectedOptionData> selectedOptions,
    required int quantity,
  }) {
    final extraPrice = selectedOptions.fold<num>(
      0,
          (sum, option) => sum + option.price,
    );

    final singlePrice = _priceAsNumber(article.price) + extraPrice;

    setState(() {
      _cartItems.add(
        CartItemData(
          itemId: article.id,
          title: article.title,
          articleNumber: article.articleNumber,
          basePrice: _priceAsNumber(article.price),
          singlePrice: singlePrice,
          quantity: quantity,
          selectedOptions: selectedOptions,
        ),
      );
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 900),
          content: Text('${article.title} wurde hinzugefügt.'),
        ),
      );
  }

  // ---------- ARTICLE DETAIL POPUP START ----------
  Future<void> _openArticleDetail({
    required ArticleData article,
    required RestaurantUiTheme theme,
    required bool restaurantActive,
  }) async {
    final Map<String, OptionData?> selectedByGroup = {};
    int quantity = 1;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool canAdd = restaurantActive && article.isAvailable;

            for (final group in article.optionGroups) {
              if (group.isRequired && selectedByGroup[group.id] == null) {
                canAdd = false;
              }
            }

            final selectedOptions = selectedByGroup.entries
                .where((entry) => entry.value != null)
                .map((entry) {
              final group = article.optionGroups.firstWhere(
                    (g) => g.id == entry.key,
              );

              return SelectedOptionData(
                groupId: entry.key,
                groupTitle: group.title,
                optionId: entry.value!.id,
                optionName: entry.value!.name,
                price: entry.value!.price,
                linkedItemId: entry.value!.linkedItemId,
              );
            }).toList();

            final extraPrice = selectedOptions.fold<num>(
              0,
                  (sum, option) => sum + option.price,
            );

            final singlePrice = _priceAsNumber(article.price) + extraPrice;
            final totalPrice = singlePrice * quantity;

            return SheetShell(
              theme: theme,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SheetHandle(theme: theme),
                        const SizedBox(height: 18),

                        ArticleDetailImage(
                          article: article,
                          theme: theme,
                        ),

                        const SizedBox(height: 18),

                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            if (article.articleNumber.isNotEmpty)
                              TinyChip(
                                theme: theme,
                                label: '#${article.articleNumber}',
                              ),
                            ...article.tags.map(
                                  (tag) => TinyChip(
                                theme: theme,
                                label: _tr(
                                  key: 'tag_${article.id}_$tag',
                                  text: tag,
                                ),
                              ),
                            ),
                            if (!article.isAvailable)
                              TinyChip(
                                theme: theme,
                                label: 'Nicht verfügbar',
                                danger: true,
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          _tr(
                            key: 'article_title_${article.id}',
                            text: article.title,
                          ),
                          style: TextStyle(
                            color: theme.ink,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),

                        if (article.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _tr(
                              key: 'article_desc_${article.id}',
                              text: article.description,
                            ),
                            style: TextStyle(
                              color: theme.muted,
                              fontSize: 14.5,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Text(
                              _formatPrice(singlePrice),
                              style: TextStyle(
                                color: theme.accent,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (_hasOriginalPrice(article)) ...[
                              const SizedBox(width: 8),
                              Text(
                                _formatPrice(article.originalPrice),
                                style: TextStyle(
                                  color: theme.muted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),

                        if (article.optionGroups.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          ...article.optionGroups.map((group) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _tr(
                                            key:
                                            'option_group_${article.id}_${group.id}',
                                            text: group.title,
                                          ),
                                          style: TextStyle(
                                            color: theme.ink,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      if (group.isRequired)
                                        TinyChip(
                                          theme: theme,
                                          label: 'Pflicht',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ...group.options.map((option) {
                                    final selected =
                                        selectedByGroup[group.id]?.id ==
                                            option.id;

                                    return Padding(
                                      padding:
                                      const EdgeInsets.only(bottom: 9),
                                      child: OptionTile(
                                        theme: theme,
                                        title: _tr(
                                          key:
                                          'option_${article.id}_${group.id}_${option.id}',
                                          text: option.name,
                                        ),
                                        price: option.price,
                                        selected: selected,
                                        onTap: () {
                                          setModalState(() {
                                            selectedByGroup[group.id] =
                                                option;
                                          });
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                        ],

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            QuantityButton(
                              theme: theme,
                              icon: Icons.remove_rounded,
                              onTap: quantity > 1
                                  ? () {
                                setModalState(() {
                                  quantity--;
                                });
                              }
                                  : null,
                            ),
                            Container(
                              width: 54,
                              alignment: Alignment.center,
                              child: Text(
                                '$quantity',
                                style: TextStyle(
                                  color: theme.ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            QuantityButton(
                              theme: theme,
                              icon: Icons.add_rounded,
                              onTap: () {
                                setModalState(() {
                                  quantity++;
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: canAdd
                                      ? () {
                                    _addToCart(
                                      article: article,
                                      selectedOptions: selectedOptions,
                                      quantity: quantity,
                                    );
                                    Navigator.pop(context);
                                  }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryButton,
                                    disabledBackgroundColor:
                                    theme.disabledButton,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(17),
                                    ),
                                  ),
                                  child: Text(
                                    restaurantActive
                                        ? 'Zum Korb • ${_formatPrice(totalPrice)}'
                                        : 'Gerade geschlossen',
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  // ---------- ARTICLE DETAIL POPUP END ----------

  Future<void> _openCartSheet(RestaurantUiTheme theme) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final total = _cartItems.fold<num>(
              0,
                  (sum, item) => sum + item.totalPrice,
            );

            return SheetShell(
              theme: theme,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SheetHandle(theme: theme),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Text(
                          'Warenkorb',
                          style: TextStyle(
                            color: theme.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _cartItems.isEmpty
                              ? null
                              : () {
                            setModalState(() {
                              _cartItems.clear();
                            });
                            setState(() {});
                          },
                          child: const Text('Leeren'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (_cartItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Text(
                          'Noch keine Artikel im Korb.',
                          style: TextStyle(
                            color: theme.muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _cartItems.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];

                            return CartLine(
                              theme: theme,
                              item: item,
                              onRemove: () {
                                setModalState(() {
                                  _cartItems.removeAt(index);
                                });
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _cartItems.isEmpty
                            ? null
                            : () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShoppingBasketPage(
                                merchantId: widget.merchantId,
                                cartItems: List<dynamic>.from(_cartItems),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryButton,
                          disabledBackgroundColor: theme.disabledButton,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          'Weiter • ${_formatPrice(total)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = TranslatorService.isRtl(_selectedLanguage);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _merchantRef.snapshots(),
        builder: (context, merchantSnapshot) {
          if (merchantSnapshot.hasError) {
            return const CenterMessage(
              text: 'Restaurant konnte nicht geladen werden.',
            );
          }

          if (!merchantSnapshot.hasData) {
            return const Scaffold(
              backgroundColor: Color(0xFF101010),
              body: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            );
          }

          final merchant = MerchantData.fromDoc(merchantSnapshot.data!);
          final theme = RestaurantUiTheme.fromStyle(
            merchant.pageStyle,
            dark: _darkMode,
          );

          return Scaffold(
            backgroundColor: theme.bg,
            body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _categoriesRef.orderBy('sortOrder').snapshots(),
              builder: (context, categorySnapshot) {
                if (!categorySnapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.ink),
                  );
                }

                final allCategories = categorySnapshot.data!.docs
                    .map((doc) => CategoryData.fromDoc(doc))
                    .where((cat) => cat.isActive)
                    .toList();

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _itemsRef.snapshots(),
                  builder: (context, itemSnapshot) {
                    if (!itemSnapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(color: theme.ink),
                      );
                    }

                    final allArticles = itemSnapshot.data!.docs
                        .map((doc) => ArticleData.fromDoc(doc))
                        .where((item) => item.isActive)
                        .toList()
                      ..sort((a, b) {
                        if (a.isAvailable != b.isAvailable) {
                          return a.isAvailable ? -1 : 1;
                        }

                        final aNum =
                            int.tryParse(a.articleNumber) ?? 999999;
                        final bNum =
                            int.tryParse(b.articleNumber) ?? 999999;

                        if (aNum != bNum) {
                          return aNum.compareTo(bNum);
                        }

                        return a.title.compareTo(b.title);
                      });

                    final visibleCategories = _visibleCategories(
                      categories: allCategories,
                      articles: allArticles,
                    );

                    if (_selectedCategoryId != 'all' &&
                        !visibleCategories
                            .any((cat) => cat.id == _selectedCategoryId)) {
                      _selectedCategoryId = 'all';
                    }

                    final articles = _filteredArticles(allArticles);

                    return SafeArea(
                      child: Stack(
                        children: [
                          CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    14,
                                    18,
                                    0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      TopControls(
                                        theme: theme,
                                        selectedLanguage: _selectedLanguage,
                                        darkMode: _darkMode,
                                        onLanguageTap: _openLanguageSheet,
                                        onDarkTap: _toggleDarkMode,
                                      ),

                                      const SizedBox(height: 12),

                                      if (!merchant.isActive) ...[
                                        ClosedNotice(theme: theme),
                                        const SizedBox(height: 12),
                                      ],

                                      MerchantHeader(
                                        merchant: merchant,
                                        theme: theme,
                                        translate: _tr,
                                      ),

                                      const SizedBox(height: 14),

                                      CategoryBar(
                                        categories: visibleCategories,
                                        selectedCategoryId:
                                        _selectedCategoryId,
                                        theme: theme,
                                        translate: _tr,
                                        onChanged: (id) {
                                          setState(() {
                                            _selectedCategoryId = id;
                                          });
                                        },
                                      ),

                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ),

                              if (articles.isEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: EmptyState(theme: theme),
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    0,
                                    18,
                                    18,
                                  ),
                                  sliver: SliverGrid(
                                    delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                        final article = articles[index];

                                        return FoodCard(
                                          article: article,
                                          theme: theme,
                                          title: _tr(
                                            key:
                                            'article_title_${article.id}',
                                            text: article.title,
                                          ),
                                          description: _tr(
                                            key:
                                            'article_desc_${article.id}',
                                            text: article.description,
                                          ),
                                          priceText:
                                          _formatPrice(article.price),
                                          originalPriceText:
                                          _hasOriginalPrice(article)
                                              ? _formatPrice(
                                            article.originalPrice,
                                          )
                                              : null,
                                          onOpen: () => _openArticleDetail(
                                            article: article,
                                            theme: theme,
                                            restaurantActive:
                                            merchant.isActive,
                                          ),
                                        );
                                      },
                                      childCount: articles.length,
                                    ),
                                    gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                      theme.compact ? 1 : 2,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: theme.gridRatio,
                                    ),
                                  ),
                                ),

                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    0,
                                    18,
                                    96,
                                  ),
                                  child: ImpressumCard(
                                    merchant: merchant,
                                    theme: theme,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 18,
                            child: BasketButton(
                              theme: theme,
                              count: _cartItems.fold<int>(
                                0,
                                    (sum, item) => sum + item.quantity,
                              ),
                              total: _cartItems.fold<num>(
                                0,
                                    (sum, item) => sum + item.totalPrice,
                              ),
                              onTap: () => _openCartSheet(theme),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}