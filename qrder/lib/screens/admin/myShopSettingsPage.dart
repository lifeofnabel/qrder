import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/cloudinary_service.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  static const Color _bg = Color(0xFFF8F6F1);
  static const Color _card = Color(0xFFFFFEFB);
  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _muted = Color(0xFF777777);
  static const Color _soft = Color(0xFFEEEBE4);
  static const Color _line = Color(0xFFE7E2D9);
  static const Color _gold = Color(0xFFD8A75D);
  static const Color _red = Color(0xFFD83A34);

  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _websiteUrlController = TextEditingController();
  final TextEditingController _catalogController = TextEditingController();

  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _instagramUrlController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _googleMapsController = TextEditingController();

  final TextEditingController _logoUrlController = TextEditingController();
  final TextEditingController _coverUrlController = TextEditingController();

  final TextEditingController _openingHoursTextController =
  TextEditingController();

  final TextEditingController _currentPasswordController =
  TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  bool _isUploadingCover = false;

  bool _isActive = true;
  bool _isPublic = true;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  String _selectedArea = '';
  String _selectedPageStyle = 'classic';
  final Map<String, OpeningDayData> _openingHours = {
    'monday': OpeningDayData(open: '10:00', close: '20:00', closed: false),
    'tuesday': OpeningDayData(open: '10:00', close: '20:00', closed: false),
    'wednesday': OpeningDayData(open: '10:00', close: '20:00', closed: false),
    'thursday': OpeningDayData(open: '10:00', close: '20:00', closed: false),
    'friday': OpeningDayData(open: '10:00', close: '20:00', closed: false),
    'saturday': OpeningDayData(open: '10:00', close: '20:00', closed: false),
    'sunday': OpeningDayData(open: '10:00', close: '20:00', closed: false),
  };

  List<String> _shopTypes = [];
  List<String> _availableAreas = [];
  List<String> _availableShopTypes = [];

  final List<_PageStyleOption> _pageStyles = const [
    _PageStyleOption(
      id: 'classic',
      title: 'Classic',
      subtitle: 'Hell, ruhig, sauber',
      icon: Icons.restaurant_menu_rounded,
    ),
    _PageStyleOption(
      id: 'modern',
      title: 'Modern',
      subtitle: 'Groß, visuell, premium',
      icon: Icons.auto_awesome_rounded,
    ),
    _PageStyleOption(
      id: 'compact',
      title: 'Compact',
      subtitle: 'Schnell, simpel, direkt',
      icon: Icons.view_compact_rounded,
    ),
  ];

  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>>? get _merchantRef {
    final uid = _user?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('merchants').doc(uid);
  }

  @override
  void initState() {
    super.initState();
    _loadMerchant();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _descriptionController.dispose();

    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();

    _websiteController.dispose();
    _websiteUrlController.dispose();
    _catalogController.dispose();

    _instagramController.dispose();
    _instagramUrlController.dispose();
    _tiktokController.dispose();
    _facebookController.dispose();
    _googleMapsController.dispose();

    _logoUrlController.dispose();
    _coverUrlController.dispose();

    _openingHoursTextController.dispose();

    _currentPasswordController.dispose();
    _newPasswordController.dispose();

    super.dispose();
  }

  void _loadOpeningHoursFromData(Map<String, dynamic> data) {
    final raw = data['openingHours'];

    if (raw is! Map) return;

    for (final entry in _openingHours.entries) {
      final dayKey = entry.key;
      final rawDay = raw[dayKey];

      if (rawDay is Map) {
        final open = rawDay['open']?.toString().trim();
        final close = rawDay['close']?.toString().trim();
        final closed = rawDay['closed'] == true;

        _openingHours[dayKey] = OpeningDayData(
          open: open != null && open.isNotEmpty ? open : '10:00',
          close: close != null && close.isNotEmpty ? close : '20:00',
          closed: closed,
        );
      }
    }
  }

  String _openingHoursToText() {
    const labels = {
      'monday': 'Mo',
      'tuesday': 'Di',
      'wednesday': 'Mi',
      'thursday': 'Do',
      'friday': 'Fr',
      'saturday': 'Sa',
      'sunday': 'So',
    };

    return _openingHours.entries.map((entry) {
      final label = labels[entry.key] ?? entry.key;
      final day = entry.value;

      if (day.closed) return '$label: geschlossen';

      return '$label: ${day.open} - ${day.close}';
    }).join('\n');
  }

  Map<String, dynamic> _openingHoursToMap() {
    return _openingHours.map((key, value) {
      return MapEntry(key, {
        'open': value.open,
        'close': value.close,
        'closed': value.closed,
      });
    });
  }

  Future<void> _loadMerchant() async {
    final ref = _merchantRef;

    if (ref == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _loadChooserData();

      final doc = await ref.get();
      final data = doc.data() ?? {};

      final fallbackName =
          data['shopName']?.toString() ??
              data['name']?.toString() ??
              data['businessName']?.toString() ??
              '';

      _shopNameController.text = data['shopName']?.toString() ?? fallbackName;
      _businessNameController.text =
          data['businessName']?.toString() ?? fallbackName;
      _ownerNameController.text = data['ownerName']?.toString() ?? '';
      _descriptionController.text = data['description']?.toString() ?? '';

      _addressController.text = data['address']?.toString() ?? '';
      _phoneController.text = data['phone']?.toString() ?? '';
      _emailController.text = data['email']?.toString() ?? _user?.email ?? '';

      _websiteController.text = data['website']?.toString() ?? '';
      _websiteUrlController.text = data['websiteUrl']?.toString() ?? '';
      _catalogController.text = data['catalog']?.toString() ?? '';

      _instagramController.text = data['instagram']?.toString() ?? '';
      _instagramUrlController.text = data['instagramUrl']?.toString() ?? '';
      _tiktokController.text = data['tiktok']?.toString() ?? '';
      _facebookController.text = data['facebook']?.toString() ?? '';
      _googleMapsController.text = data['googleMaps']?.toString() ?? '';

      _logoUrlController.text = data['logoUrl']?.toString() ?? '';
      _coverUrlController.text = data['coverUrl']?.toString() ?? '';

      _openingHoursTextController.text =
          _openingHoursTextController.text = _openingHoursToText();

      _isActive = data['isActive'] as bool? ?? true;
      _isPublic = data['isPublic'] as bool? ?? true;

      _selectedArea = data['area']?.toString() ?? '';
      if (_selectedArea.isNotEmpty && !_availableAreas.contains(_selectedArea)) {
        _availableAreas.add(_selectedArea);
      }

      final rawShopTypes = data['shopTypes'];
      if (rawShopTypes is List) {
        _shopTypes = rawShopTypes
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .take(2)
            .toList();
      }

      _selectedPageStyle = data['pageStyle']?.toString() ?? 'classic';

      final validStyles = _pageStyles.map((style) => style.id).toSet();
      if (!validStyles.contains(_selectedPageStyle)) {
        _selectedPageStyle = 'classic';
      }
    } catch (e) {
      _showSnack('Daten konnten nicht geladen werden.');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChooserData() async {
    final chooserRef = FirebaseFirestore.instance.collection('chooser');

    final areaDoc = await chooserRef.doc('area').get();
    final shopTypeDoc = await chooserRef.doc('shopType').get();

    final areaData = areaDoc.data() ?? {};
    final shopTypeData = shopTypeDoc.data() ?? {};

    final rawAreas = areaData['name'];
    final rawShopTypes = shopTypeData['name'];

    if (rawAreas is List) {
      _availableAreas = rawAreas
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    if (rawShopTypes is List) {
      _availableShopTypes = rawShopTypes
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
  }

  String _parseOpeningHoursTextFromData(Map<String, dynamic> data) {
    final direct = data['openingHoursText']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final raw = data['openingHours'];

    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }

    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .join('\n');
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

        if (value == null) continue;

        if (value is Map) {
          final closed = value['closed'] == true;
          final from = value['from']?.toString() ?? '';
          final to = value['to']?.toString() ?? '';

          if (closed) {
            lines.add('${entry.value}: geschlossen');
          } else if (from.isNotEmpty && to.isNotEmpty) {
            lines.add('${entry.value}: $from - $to');
          }
        } else {
          final text = value.toString().trim();
          if (text.isNotEmpty) {
            lines.add('${entry.value}: $text');
          }
        }
      }

      return lines.join('\n');
    }

    return '';
  }

  Future<void> _saveMerchant() async {
    final ref = _merchantRef;
    final user = _user;

    if (ref == null || user == null) {
      _showSnack('Kein Händler eingeloggt.');
      return;
    }

    final shopName = _shopNameController.text.trim();
    final businessName = _businessNameController.text.trim();
    final email = _emailController.text.trim();

    if (shopName.isEmpty) {
      _showSnack('Shop-Name fehlt.');
      return;
    }

    if (businessName.isEmpty) {
      _showSnack('Business-Name fehlt.');
      return;
    }

    if (email.isEmpty) {
      _showSnack('E-Mail fehlt.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.set(
        {
          'id': user.uid,

          'shopName': shopName,
          'name': shopName,
          'businessName': businessName,
          'ownerName': _ownerNameController.text.trim(),
          'description': _descriptionController.text.trim(),

          'address': _addressController.text.trim(),
          'area': _selectedArea,
          'phone': _phoneController.text.trim(),
          'email': email,

          'website': _websiteController.text.trim(),
          'websiteUrl': _cleanUrl(_websiteUrlController.text),
          'catalog': _cleanUrl(_catalogController.text),

          'instagram': _cleanSocial(_instagramController.text),
          'instagramUrl': _cleanSocialOrUrl(_instagramUrlController.text),
          'tiktok': _cleanSocialOrUrl(_tiktokController.text),
          'facebook': _cleanUrl(_facebookController.text),
          'googleMaps': _cleanUrl(_googleMapsController.text),

          'logoUrl': _logoUrlController.text.trim(),
          'coverUrl': _coverUrlController.text.trim(),

          'openingHours': _openingHoursToMap(),
          'openingHoursText': _openingHoursToText(),

          'shopTypes': _shopTypes.take(2).toList(),
          'pageStyle': _selectedPageStyle,
          'isActive': _isActive,
          'isPublic': _isPublic,

          'password': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await _changePasswordIfNeeded();

      _showSnack('Alles gespeichert.');
    } catch (e) {
      _showSnack('Speichern fehlgeschlagen.');
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _changePasswordIfNeeded() async {
    final user = _user;
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (newPassword.isEmpty) return;

    if (user == null || user.email == null) {
      throw Exception('Kein Firebase User.');
    }

    if (currentPassword.isEmpty) {
      _showSnack('Aktuelles Passwort fehlt.');
      throw Exception('Aktuelles Passwort fehlt.');
    }

    if (newPassword.length < 6) {
      _showSnack('Neues Passwort mindestens 6 Zeichen.');
      throw Exception('Passwort zu kurz.');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);

    _currentPasswordController.clear();
    _newPasswordController.clear();
  }

  Future<void> _uploadImage({
    required bool isCover,
  }) async {
    final ref = _merchantRef;
    final user = _user;

    if (ref == null || user == null) {
      _showSnack('Kein Händler eingeloggt.');
      return;
    }

    try {
      final picker = ImagePicker();

      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: isCover ? 2200 : 1600,
      );

      if (picked == null) return;

      XFile uploadFile = picked;

      if (!isCover) {
        try {
          final cropped = await ImageCropper().cropImage(
            sourcePath: picked.path,
            maxWidth: 900,
            maxHeight: 900,
            compressQuality: 88,
            compressFormat: ImageCompressFormat.jpg,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Logo zuschneiden',
                toolbarColor: _ink,
                toolbarWidgetColor: Colors.white,
                backgroundColor: _bg,
                activeControlsWidgetColor: _gold,
                cropStyle: CropStyle.circle,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
              ),
              IOSUiSettings(
                title: 'Logo zuschneiden',
                aspectRatioLockEnabled: true,
                resetAspectRatioEnabled: false,
                aspectRatioPickerButtonHidden: true,
                cropStyle: CropStyle.circle,
              ),
              WebUiSettings(
                context: context,
                presentStyle: WebPresentStyle.dialog,
                size: const CropperSize(width: 420, height: 420),
                initialAspectRatio: 1,
                guides: true,
                center: true,
                movable: true,
                rotatable: false,
                scalable: true,
                zoomable: true,
                cropBoxMovable: true,
                cropBoxResizable: false,
              ),
            ],
          );

          if (cropped != null) {
            uploadFile = XFile(
              cropped.path,
              name: 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg',
              mimeType: 'image/jpeg',
            );
          }
        } catch (_) {
          uploadFile = picked;
          _showSnack('Zuschneiden übersprungen. Bild wird normal hochgeladen.');
        }
      }

      setState(() {
        if (isCover) {
          _isUploadingCover = true;
        } else {
          _isUploadingLogo = true;
        }
      });

      final imageUrl = await CloudinaryService.uploadImage(uploadFile);

      if (isCover) {
        _coverUrlController.text = imageUrl;

        await ref.set(
          {
            'coverUrl': imageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        _showSnack('Cover hochgeladen.');
      } else {
        _logoUrlController.text = imageUrl;

        await ref.set(
          {
            'logoUrl': imageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        _showSnack('Logo hochgeladen.');
      }
    } catch (e) {
      _showSnack(isCover ? 'Cover-Upload fehlgeschlagen.' : 'Logo-Upload fehlgeschlagen.');
    }

    if (mounted) {
      setState(() {
        if (isCover) {
          _isUploadingCover = false;
        } else {
          _isUploadingLogo = false;
        }
      });
    }
  }

  String _cleanUrl(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) return '';

    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }

    return 'https://$cleaned';
  }

  String _cleanSocial(String value) {
    return value.trim().replaceAll('@', '');
  }

  String _cleanSocialOrUrl(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) return '';

    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }

    return cleaned.replaceAll('@', '');
  }

  void _toggleShopType(String type) {
    setState(() {
      if (_shopTypes.contains(type)) {
        _shopTypes.remove(type);
        return;
      }

      if (_shopTypes.length >= 2) {
        _showSnack('Maximal 2 Shop-Typen auswählbar.');
        return;
      }

      _shopTypes.add(type);
    });
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
    final logoUrl = _logoUrlController.text.trim();
    final coverUrl = _coverUrlController.text.trim();

    final hasLogo = logoUrl.isNotEmpty;
    final hasCover = coverUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _ink))
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(context),
              const SizedBox(height: 22),

              const Text(
                'Meine Einstellungen',
                style: TextStyle(
                  color: _ink,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 7),

              _PreviewCard(
                shopName: _shopNameController.text.trim(),
                description: _descriptionController.text.trim(),
                logoUrl: logoUrl,
                coverUrl: coverUrl,
                isActive: _isActive,
              ),

              const SizedBox(height: 14),

              _StatusCard(
                isActive: _isActive,
                isPublic: _isPublic,
                onActiveChanged: (value) {
                  setState(() => _isActive = value);
                },
                onPublicChanged: (value) {
                  setState(() => _isPublic = value);
                },
              ),

              const SizedBox(height: 14),

              _SectionCard(
                title: 'Basisdaten',
                subtitle: 'Name, Ansprechpartner und Shop-Typ.',
                children: [
                  _StyledInput(
                    controller: _businessNameController,
                    label: 'Business-Name',
                    hintText: 'Offizieller Geschäftsname',
                    prefixIcon: Icons.business_rounded,
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _ownerNameController,
                    label: 'Inhaber / Ansprechpartner',
                    hintText: 'Name des Ansprechpartners',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Shop-Typen',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Maximal 2 auswählbar.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  if (_availableShopTypes.isEmpty)
                    const Text(
                      'Keine Shop-Typen gefunden.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableShopTypes.map((type) {
                        final selected = _shopTypes.contains(type);

                        return GestureDetector(
                          onTap: () => _toggleShopType(type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? _ink : _soft,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: selected ? _ink : _line,
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: selected ? Colors.white : _ink,
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

              const SizedBox(height: 14),

              _SectionCard(
                title: 'Restaurant-Seite Style',
                subtitle: 'Wähle, wie deine öffentliche Qrder-Seite aussehen soll.',
                children: [
                  Column(
                    children: _pageStyles.map((style) {
                      final selected = _selectedPageStyle == style.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PageStyleCard(
                          title: style.title,
                          subtitle: style.subtitle,
                          icon: style.icon,
                          selected: selected,
                          onTap: () {
                            setState(() {
                              _selectedPageStyle = style.id;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _SectionCard(
                title: 'Öffentliche Infos',
                subtitle: 'Beschreibung, Adresse, Stadtteil und Kontakt.',
                children: [
                  _StyledInput(
                    controller: _descriptionController,
                    label: 'Beschreibung',
                    hintText: 'Kurzer Text über deinen Laden',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _addressController,
                    label: 'Adresse',
                    hintText: 'Rüster Str. 2, 60325 Frankfurt',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _phoneController,
                    label: 'Telefon',
                    hintText: '0177...',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _emailController,
                    label: 'E-Mail',
                    hintText: 'kontakt@deinladen.de',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _SectionCard(
                title: 'Bilder',
                subtitle: 'Logo und Cover-Bild für deine öffentliche Seite.',
                children: [
                  _ImageUploadBox(
                    title: 'Cover-Bild',
                    subtitle: 'Großes Hintergrundbild oben auf deiner Restaurant-Seite.',
                    imageUrl: coverUrl,
                    isCover: true,
                    isUploading: _isUploadingCover,
                    onUpload: () => _uploadImage(isCover: true),
                    onUrlChanged: (value) {
                      _coverUrlController.text = value;
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 18),
                  _ImageUploadBox(
                    title: 'Logo',
                    subtitle: 'Rundes oder quadratisches Ladenlogo.',
                    imageUrl: logoUrl,
                    isCover: false,
                    isUploading: _isUploadingLogo,
                    onUpload: () => _uploadImage(isCover: false),
                    onUrlChanged: (value) {
                      _logoUrlController.text = value;
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _coverUrlController,
                    label: 'Cover URL',
                    hintText: 'Wird nach Upload automatisch gesetzt',
                    prefixIcon: Icons.image_outlined,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _logoUrlController,
                    label: 'Logo URL',
                    hintText: 'Wird nach Upload automatisch gesetzt',
                    prefixIcon: Icons.link_rounded,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _SectionCard(
                title: 'Öffnungszeiten',
                subtitle: 'Tage aktivieren, Uhrzeiten einstellen, sauber speichern.',
                children: [
                  ..._openingHours.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OpeningDayEditor(
                        dayKey: entry.key,
                        data: entry.value,
                        onChanged: (newData) {
                          setState(() {
                            _openingHours[entry.key] = newData;
                            _openingHoursTextController.text = _openingHoursToText();
                          });
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  _OpeningPreviewBox(text: _openingHoursToText()),
                ],
              ),

              const SizedBox(height: 14),

              _SectionCard(
                title: 'Links & Social',
                subtitle: 'Diese Links erscheinen als kleine Buttons auf deiner Restaurant-Seite.',
                children: [
                  _StyledInput(
                    controller: _websiteUrlController,
                    label: 'Website URL',
                    hintText: 'www.deinladen.de',
                    prefixIcon: Icons.language_rounded,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _websiteController,
                    label: 'Website Text / optional',
                    hintText: 'z. B. deinladen.de',
                    prefixIcon: Icons.text_fields_rounded,
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _catalogController,
                    label: 'Katalog / Speisekarte URL',
                    hintText: 'https://deinladen.de/menu.html',
                    prefixIcon: Icons.menu_book_rounded,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _instagramUrlController,
                    label: 'Instagram',
                    hintText: '@deinladen oder Link',
                    prefixIcon: Icons.alternate_email_rounded,
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _tiktokController,
                    label: 'TikTok',
                    hintText: '@deinladen oder Link',
                    prefixIcon: Icons.music_note_rounded,
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _facebookController,
                    label: 'Facebook',
                    hintText: 'facebook.com/deinladen',
                    prefixIcon: Icons.facebook_rounded,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _googleMapsController,
                    label: 'Google Maps Link',
                    hintText: 'maps.google.com/... oder leer lassen',
                    prefixIcon: Icons.map_outlined,
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _SectionCard(
                title: 'Passwort ändern',
                subtitle: 'Nur ausfüllen, wenn du dein Passwort ändern willst.',
                children: [
                  _StyledInput(
                    controller: _currentPasswordController,
                    label: 'Aktuelles Passwort',
                    hintText: 'Aktuelles Passwort',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscureCurrentPassword,
                    suffix: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword =
                          !_obscureCurrentPassword;
                        });
                      },
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _StyledInput(
                    controller: _newPasswordController,
                    label: 'Neues Passwort',
                    hintText: 'Mindestens 6 Zeichen',
                    prefixIcon: Icons.password_rounded,
                    obscureText: _obscureNewPassword,
                    suffix: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Passwort wird nur in Firebase Auth geändert. Das alte Firestore-Feld wird gelöscht.',
                    style: TextStyle(
                      color: _red,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMerchant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ink,
                    disabledBackgroundColor: const Color(0xFFBEB8AE),
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
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    'Alles speichern',
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

  Widget _topBar(BuildContext context) {
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
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _ink,
          ),
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
}

/* UI */

class _PreviewCard extends StatelessWidget {
  final String shopName;
  final String description;
  final String logoUrl;
  final String coverUrl;
  final bool isActive;

  const _PreviewCard({
    required this.shopName,
    required this.description,
    required this.logoUrl,
    required this.coverUrl,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl.trim().isNotEmpty;
    final hasCover = coverUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7E2D9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasCover)
            Positioned.fill(
              child: Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(),
              ),
            ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.62),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasLogo
                      ? Image.network(
                    logoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.storefront_outlined,
                        color: Colors.white,
                      );
                    },
                  )
                      : const Icon(
                    Icons.storefront_outlined,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  shopName.isEmpty ? 'Dein Laden' : shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description.isEmpty ? 'Beschreibung deiner Qrder-Seite' : description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE8E8E8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  isActive ? 'Geöffnet für Bestellungen' : 'Gerade geschlossen',
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF6DE38B)
                        : const Color(0xFFFF6B6B),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

class _StatusCard extends StatelessWidget {
  final bool isActive;
  final bool isPublic;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<bool> onPublicChanged;

  const _StatusCard({
    required this.isActive,
    required this.isPublic,
    required this.onActiveChanged,
    required this.onPublicChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SwitchLine(
          title: isActive ? 'Laden aktiv' : 'Laden pausiert',
          subtitle: isActive
              ? 'Kunden können bestellen.'
              : 'Kunden sehen Hinweis, aber können nicht bestellen.',
          icon: isActive ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
          value: isActive,
          onChanged: onActiveChanged,
          activeColor: const Color(0xFF2E9E5B),
        ),
      ],
    );
  }
}

class _SwitchLine extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _SwitchLine({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFEAF7EF) : const Color(0xFFF7EAEA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: value ? const Color(0xFFCDEBD8) : const Color(0xFFEBCACA),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? activeColor : const Color(0xFFD83A34),
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 12.3,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ImageUploadBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool isCover;
  final bool isUploading;
  final VoidCallback onUpload;
  final ValueChanged<String> onUrlChanged;

  const _ImageUploadBox({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.isCover,
    required this.isUploading,
    required this.onUpload,
    required this.onUrlChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0DBD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          Container(
            height: isCover ? 130 : 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEBE4),
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF777777),
                );
              },
            )
                : const Icon(
              Icons.image_outlined,
              color: Color(0xFF777777),
              size: 38,
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: isUploading ? null : onUpload,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A1A),
                side: const BorderSide(color: Color(0xFFE0DBD2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: isUploading
                  ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1A1A1A),
                ),
              )
                  : Icon(isCover ? Icons.wallpaper_rounded : Icons.crop_rounded),
              label: Text(
                isUploading ? 'Wird hochgeladen...' : '$title hochladen',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF777777),
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

class _StyledInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffix;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _StyledInput({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffix,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: const Color(0xFF888888),
              size: 20,
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF3F0E9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: Color(0xFFE0DBD2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: Color(0xFFE0DBD2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: Color(0xFF1A1A1A),
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownInput extends StatelessWidget {
  final String label;
  final String? value;
  final String hintText;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownInput({
    required this.label,
    required this.value,
    required this.hintText,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value != null && items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: safeValue,
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF888888),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFF3F0E9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: Color(0xFFE0DBD2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: Color(0xFFE0DBD2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: Color(0xFF1A1A1A),
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageStyleOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _PageStyleOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _PageStyleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PageStyleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFF3F0E9),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFE0DBD2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.14)
                      : const Color(0xFFFFFEFB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : const Color(0xFF1A1A1A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color:
                        selected ? Colors.white : const Color(0xFF1A1A1A),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFFD8D8D8)
                            : const Color(0xFF777777),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? Colors.white : const Color(0xFFAAAAAA),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class OpeningDayData {
  final String open;
  final String close;
  final bool closed;

  const OpeningDayData({
    required this.open,
    required this.close,
    required this.closed,
  });

  OpeningDayData copyWith({
    String? open,
    String? close,
    bool? closed,
  }) {
    return OpeningDayData(
      open: open ?? this.open,
      close: close ?? this.close,
      closed: closed ?? this.closed,
    );
  }
}

class _OpeningDayEditor extends StatelessWidget {
  final String dayKey;
  final OpeningDayData data;
  final ValueChanged<OpeningDayData> onChanged;

  const _OpeningDayEditor({
    required this.dayKey,
    required this.data,
    required this.onChanged,
  });

  String get _label {
    switch (dayKey) {
      case 'monday':
        return 'Montag';
      case 'tuesday':
        return 'Dienstag';
      case 'wednesday':
        return 'Mittwoch';
      case 'thursday':
        return 'Donnerstag';
      case 'friday':
        return 'Freitag';
      case 'saturday':
        return 'Samstag';
      case 'sunday':
        return 'Sonntag';
      default:
        return dayKey;
    }
  }

  Future<void> _pickTime({
    required BuildContext context,
    required bool isOpen,
  }) async {
    final current = isOpen ? data.open : data.close;
    final parts = current.split(':');

    final initialHour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 10;
    final initialMinute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialHour.clamp(0, 23),
        minute: initialMinute.clamp(0, 59),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A1A1A),
              onPrimary: Colors.white,
              surface: Color(0xFFFFFEFB),
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

    if (isOpen) {
      onChanged(data.copyWith(open: value));
    } else {
      onChanged(data.copyWith(close: value));
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = data.closed;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0E9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0DBD2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _label,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                disabled ? 'geschlossen' : 'offen',
                style: TextStyle(
                  color: disabled
                      ? const Color(0xFFD83A34)
                      : const Color(0xFF2E9E5B),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: !data.closed,
                activeColor: const Color(0xFF1A1A1A),
                onChanged: (value) {
                  onChanged(data.copyWith(closed: !value));
                },
              ),
            ],
          ),
          if (!disabled) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Öffnet',
                    value: data.open,
                    onTap: () => _pickTime(
                      context: context,
                      isOpen: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeButton(
                    label: 'Schließt',
                    value: data.close,
                    onTap: () => _pickTime(
                      context: context,
                      isOpen: false,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFEFB),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE7E2D9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
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

class _OpeningPreviewBox extends StatelessWidget {
  final String text;

  const _OpeningPreviewBox({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.visibility_outlined,
            color: Colors.white,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.8,
                height: 1.45,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}