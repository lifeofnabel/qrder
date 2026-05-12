import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../customer/restaurantPage.dart';
import '../guest/landingPage.dart';

import 'readOrderPage.dart';
import 'myOrdersPage.dart';
import 'myArticlesPage.dart';
import 'myShopSettingsPage.dart';
import 'MyCategoriesPage.dart';
import 'supportPage.dart';
import 'myTablesPage.dart';

class RestaurantHomePage extends StatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  State<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  static const Color _bg = Color(0xFFF8F6F1);
  static const Color _card = Color(0xFFFFFEFB);
  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _muted = Color(0xFF777777);
  static const Color _soft = Color(0xFFEEEBE4);
  static const Color _line = Color(0xFFE7E2D9);
  static const Color _gold = Color(0xFFD8A75D);
  static const Color _green = Color(0xFF2E9E5B);
  static const Color _red = Color(0xFFD83A34);

  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>>? get _merchantRef {
    final uid = _user?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('merchants').doc(uid);
  }

  void _openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
          (route) => false,
    );
  }

  Future<void> _copyShopLink(String uid) async {
    final shopUrl = 'https://qrder.app/restaurant/$uid';

    await Clipboard.setData(ClipboardData(text: shopUrl));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shop-Link kopiert.')),
    );
  }

  Future<void> _openOrderSettingsSheet() async {
    final uid = _user?.uid;
    if (uid == null) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final ref = FirebaseFirestore.instance.collection('merchants').doc(uid);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ref.snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? {};

            final qrCodeOrder = data['qrCodeOrder'] as bool? ?? false;
            final realOrder = data['realOrder'] as bool? ?? false;

            return Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              decoration: const BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Bestellfunktionen',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Steuere, wie Kunden bestellen dürfen.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _OrderSwitchTile(
                      title: 'QR-Code Bestellung',
                      subtitle: 'Kunde bekommt QR-Code und zeigt ihn an der Kasse.',
                      icon: Icons.qr_code_2_rounded,
                      value: qrCodeOrder,
                      onChanged: (value) async {
                        await ref.set(
                          {
                            'qrCodeOrder': value,
                            'updatedAt': FieldValue.serverTimestamp(),
                          },
                          SetOptions(merge: true),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _OrderSwitchTile(
                      title: 'Direkte Bestellung',
                      subtitle: 'Kunde sendet Bestellung direkt an deine Bestellseite.',
                      icon: Icons.send_rounded,
                      value: realOrder,
                      onChanged: (value) async {
                        await ref.set(
                          {
                            'realOrder': value,
                            'updatedAt': FieldValue.serverTimestamp(),
                          },
                          SetOptions(merge: true),
                        );
                      },
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
    final ref = _merchantRef;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ref == null
            ? const _EmptyLoginState()
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ref.snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? {};
            final uid = _user?.uid;

            final storeName = _firstNotEmpty([
              data['shopName'],
              data['name'],
              data['businessName'],
            ], fallback: 'Dein Restaurant');

            final logoUrl = _firstNotEmpty([
              data['logoUrl'],
            ], fallback: '');

            final description = _firstNotEmpty([
              data['description'],
            ], fallback: 'Deine öffentliche Qrder-Seite');

            final isActive = data['isActive'] as bool? ?? true;
            final qrCodeOrder = data['qrCodeOrder'] as bool? ?? false;
            final realOrder = data['realOrder'] as bool? ?? false;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBrand(onLogout: _logout),

                  const SizedBox(height: 18),

                  _ShopHeaderCard(
                    storeName: storeName,
                    description: description,
                    logoUrl: logoUrl,
                    isActive: isActive,
                    qrCodeOrder: qrCodeOrder,
                    realOrder: realOrder,
                    onOpenShop: () {
                      if (uid == null) {
                        _showSnack('Kein Händler eingeloggt.');
                        return;
                      }

                      _openPage(RestaurantPage(merchantId: uid));
                    },
                    onCopyLink: () {
                      if (uid == null) {
                        _showSnack('Kein Händler eingeloggt.');
                        return;
                      }

                      _copyShopLink(uid);
                    },
                    onSettings: _openOrderSettingsSheet,
                  ),

                  const SizedBox(height: 18),

                  _ScanHero(
                    onTap: () => _openPage(const ReadOrderPage()),
                  ),

                  const SizedBox(height: 12),

                  _WideActionCard(
                    title: 'Historie',
                    subtitle: 'Alte und direkte Bestellungen ansehen',
                    icon: Icons.history_rounded,
                    onTap: () => _openPage(const OrderHistoryPage()),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _SmallActionCard(
                          title: 'Artikel',
                          subtitle: 'bearbeiten',
                          icon: Icons.inventory_2_outlined,
                          onTap: () => _openPage(const MyArticlesPage()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SmallActionCard(
                          title: 'Kategorien',
                          subtitle: 'ordnen',
                          icon: Icons.category_outlined,
                          onTap: () => _openPage(const MyCategoriesPage()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _SmallActionCard(
                          title: 'Tische',
                          subtitle: 'Plätze verwalten',
                          icon: Icons.table_restaurant_outlined,
                          onTap: () => _openPage(const MyTablesPage()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SmallActionCard(
                          title: 'Account',
                          subtitle: 'Einstellungen & Daten ändern',
                          icon: Icons.person_outline_rounded,
                          onTap: () => _openPage(const MyAccountPage()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _SmallActionCard(
                          title: 'Support',
                          subtitle: 'Hilfe holen',
                          icon: Icons.support_agent_rounded,
                          onTap: () => _openPage(const SupportPage()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SmallActionCard(
                          title: 'Shop (Bald)',
                          subtitle: 'Zubehör',
                          icon: Icons.shopping_bag_outlined,
                          onTap: () => _openPage(const QrderShopPage()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 17,
                      ),
                      label: const Text('Ausloggen'),
                      style: TextButton.styleFrom(
                        foregroundColor: _muted,
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _firstNotEmpty(List<dynamic> values, {required String fallback}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  void _showSnack(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }
}

/* UI */

class _TopBrand extends StatelessWidget {
  final VoidCallback onLogout;

  const _TopBrand({
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _RestaurantColors.ink,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              'Q',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Qrder',
          style: TextStyle(
            color: _RestaurantColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Ausloggen',
          onPressed: onLogout,
          icon: const Icon(
            Icons.logout_rounded,
            color: _RestaurantColors.muted,
            size: 21,
          ),
        ),
      ],
    );
  }
}

class _ShopHeaderCard extends StatelessWidget {
  final String storeName;
  final String description;
  final String logoUrl;
  final bool isActive;
  final bool qrCodeOrder;
  final bool realOrder;
  final VoidCallback onOpenShop;
  final VoidCallback onCopyLink;
  final VoidCallback onSettings;

  const _ShopHeaderCard({
    required this.storeName,
    required this.description,
    required this.logoUrl,
    required this.isActive,
    required this.qrCodeOrder,
    required this.realOrder,
    required this.onOpenShop,
    required this.onCopyLink,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _RestaurantColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _RestaurantColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LogoBox(logoUrl: logoUrl, hasLogo: hasLogo),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _RestaurantColors.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? _RestaurantColors.green
                                : _RestaurantColors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            isActive
                                ? 'Öffentliche Shop-Seite aktiv'
                                : 'Shop gerade pausiert',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _RestaurantColors.muted,
                              fontSize: 12.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Bestellfunktionen',
                onPressed: onSettings,
                icon: const Icon(
                  Icons.tune_rounded,
                  color: _RestaurantColors.muted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _RestaurantColors.muted,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _StatusPill(
                label: qrCodeOrder ? 'QR aktiv' : 'QR aus',
                active: qrCodeOrder,
                icon: Icons.qr_code_2_rounded,
              ),
              const SizedBox(width: 8),
              _StatusPill(
                label: realOrder ? 'Direkt aktiv' : 'Direkt aus',
                active: realOrder,
                icon: Icons.send_rounded,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Material(
            color: _RestaurantColors.soft,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onOpenShop,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _RestaurantColors.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _RestaurantColors.ink,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zum eigenen Shop',
                            style: TextStyle(
                              color: _RestaurantColors.ink,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'So sehen Kunden deine QR-Seite.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _RestaurantColors.muted,
                              fontSize: 12.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _RestaurantColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _MiniButton(
                  label: 'Link kopieren',
                  icon: Icons.copy_rounded,
                  onTap: onCopyLink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniButton(
                  label: 'QR Export später',
                  icon: Icons.qr_code_2_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('QR-Code Export bauen wir später.'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;
  final IconData icon;

  const _StatusPill({
    required this.label,
    required this.active,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFEAF7EF)
              : const Color(0xFFF7EAEA),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active
                ? const Color(0xFFCDEBD8)
                : const Color(0xFFEBCACA),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: active
                  ? _RestaurantColors.green
                  : _RestaurantColors.red,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active
                      ? _RestaurantColors.green
                      : _RestaurantColors.red,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanHero extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanHero({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _RestaurantColors.ink,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _RestaurantColors.gold,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Hauptaktion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: _RestaurantColors.ink,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'QR scannen',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Bestellung öffnen, prüfen und direkt bearbeiten.',
                    style: TextStyle(
                      color: Color(0xFFD8D8D8),
                      fontSize: 14.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OrderSwitchTile({
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
        color: _RestaurantColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _RestaurantColors.line),
      ),
      child: SwitchListTile(
        value: value,
        activeColor: _RestaurantColors.ink,
        onChanged: onChanged,
        secondary: Icon(
          icon,
          color: _RestaurantColors.ink,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _RestaurantColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: _RestaurantColors.muted,
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LogoBox extends StatelessWidget {
  final String logoUrl;
  final bool hasLogo;

  const _LogoBox({
    required this.logoUrl,
    required this.hasLogo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: _RestaurantColors.soft,
        shape: BoxShape.circle,
        border: Border.all(color: _RestaurantColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? Image.network(
        logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.storefront_outlined,
            color: _RestaurantColors.ink,
            size: 28,
          );
        },
      )
          : const Icon(
        Icons.storefront_outlined,
        color: _RestaurantColors.ink,
        size: 28,
      ),
    );
  }
}

class _SmallActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _RestaurantColors.card,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: onTap,
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: _RestaurantColors.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -2,
                top: -2,
                child: Icon(
                  icon,
                  color: _RestaurantColors.ink.withOpacity(0.18),
                  size: 34,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _RestaurantColors.soft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: _RestaurantColors.ink,
                      size: 21,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _RestaurantColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _RestaurantColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _WideActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _RestaurantColors.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _RestaurantColors.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _RestaurantColors.soft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: _RestaurantColors.ink,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _RestaurantColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _RestaurantColors.muted,
                        fontSize: 12.8,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _RestaurantColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _RestaurantColors.ink,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 17),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
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

class _EmptyLoginState extends StatelessWidget {
  const _EmptyLoginState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Kein eingeloggter Nutzer gefunden.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _RestaurantColors.muted,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/* PLACEHOLDER */

class QrderShopPage extends StatelessWidget {
  const QrderShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SimplePlaceholderPage(
      title: 'Qrder Shop',
      icon: Icons.shopping_bag_outlined,
      text: 'Hier kommen später QR-Code Sticker, Tischaufsteller und Zubehör rein.',
    );
  }
}

class _SimplePlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String text;

  const _SimplePlaceholderPage({
    required this.title,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RestaurantColors.bg,
      appBar: AppBar(
        backgroundColor: _RestaurantColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _RestaurantColors.ink),
        title: Text(
          title,
          style: const TextStyle(
            color: _RestaurantColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _RestaurantColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _RestaurantColors.line),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 46, color: _RestaurantColors.ink),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: _RestaurantColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _RestaurantColors.muted,
                    fontSize: 14,
                    height: 1.45,
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
}

/* COLORS */

class _RestaurantColors {
  static const Color bg = Color(0xFFF8F6F1);
  static const Color card = Color(0xFFFFFEFB);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF777777);
  static const Color soft = Color(0xFFEEEBE4);
  static const Color line = Color(0xFFE7E2D9);
  static const Color gold = Color(0xFFD8A75D);
  static const Color green = Color(0xFF2E9E5B);
  static const Color red = Color(0xFFD83A34);
}