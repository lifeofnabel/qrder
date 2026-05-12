import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>>? get _merchantRef {
    final uid = _user?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('merchants').doc(uid);
  }

  CollectionReference<Map<String, dynamic>>? get _ordersRef {
    final uid = _user?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('merchants')
        .doc(uid)
        .collection('orders');
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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

  String _shopUrl(String uid) {
    if (kIsWeb && Uri.base.origin.isNotEmpty) {
      return '${Uri.base.origin}/restaurant/$uid';
    }

    return 'https://qrder.app/restaurant/$uid';
  }

  Future<void> _copyShopLink(String uid) async {
    await Clipboard.setData(ClipboardData(text: _shopUrl(uid)));

    if (!mounted) return;

    _showSnack('Shop-Link kopiert.');
  }

  Future<void> _openContactSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _SheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 18),
              const Icon(
                Icons.support_agent_rounded,
                color: KDashboard.gold,
                size: 38,
              ),
              const SizedBox(height: 12),
              const Text(
                'Kontakt',
                style: TextStyle(
                  color: KDashboard.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Schnell Hilfe bekommen. Keine Faxen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KDashboard.muted,
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _ContactTile(
                icon: Icons.call_rounded,
                title: 'Anrufen',
                subtitle: '0177 1816751',
                onTap: () async {
                  Navigator.pop(context);
                  await launchUrl(Uri.parse('tel:01771816751'));
                },
              ),
              const SizedBox(height: 10),
              _ContactTile(
                icon: Icons.email_rounded,
                title: 'E-Mail',
                subtitle: 'nabell.321@gmail.com',
                onTap: () async {
                  Navigator.pop(context);
                  await launchUrl(Uri.parse('mailto:nabell.321@gmail.com'));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openOrderSettingsSheet() async {
    final uid = _user?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance.collection('merchants').doc(uid);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ref.snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? {};
            final qrCodeOrder = data['qrCodeOrder'] as bool? ?? false;
            final realOrder = data['realOrder'] as bool? ?? false;

            return _SheetShell(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 18),
                  const Text(
                    'Bestellfunktionen',
                    style: TextStyle(
                      color: KDashboard.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Steuere, wie Gäste bestellen dürfen.',
                    style: TextStyle(
                      color: KDashboard.muted,
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _OrderSwitchTile(
                    title: 'QR-Code Bestellung',
                    subtitle: 'Gast zeigt QR-Code an der Kasse.',
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
                    subtitle: 'Gast sendet Bestellung direkt in deine Übersicht.',
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantRef = _merchantRef;
    final ordersRef = _ordersRef;

    return Scaffold(
      backgroundColor: KDashboard.bg,
      body: SafeArea(
        child: merchantRef == null || ordersRef == null
            ? const _EmptyLoginState()
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: merchantRef.snapshots(),
          builder: (context, merchantSnapshot) {
            if (merchantSnapshot.hasError) {
              return const _ErrorState(text: 'Dashboard konnte nicht geladen werden.');
            }

            if (!merchantSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: KDashboard.ink),
              );
            }

            final data = merchantSnapshot.data?.data() ?? {};
            final uid = _user?.uid;

            final storeName = _firstNotEmpty(
              [data['businessName'], data['shopName'], data['name']],
              fallback: 'Dein Restaurant',
            );

            final description = _firstNotEmpty(
              [data['description']],
              fallback: 'Deine öffentliche Qrder-Seite',
            );

            final logoUrl = _firstNotEmpty([data['logoUrl']], fallback: '');
            final coverUrl = _firstNotEmpty([data['coverUrl']], fallback: '');

            final isActive = data['isActive'] as bool? ?? true;
            final qrCodeOrder = data['qrCodeOrder'] as bool? ?? false;
            final realOrder = data['realOrder'] as bool? ?? false;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ordersRef.snapshots(),
              builder: (context, orderSnapshot) {
                final orderDocs = orderSnapshot.data?.docs ?? [];

                final totalOrders = orderDocs.length;
                final newOrders = orderDocs.where((doc) {
                  final status = doc.data()['status']?.toString() ?? '';
                  return status == 'new' || status == 'waitingForScan';
                }).length;

                final realOrders = orderDocs.where((doc) {
                  return doc.data()['mode']?.toString() == 'realOrder';
                }).length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopBar(
                        storeName: storeName,
                        onLogout: _logout,
                        onContact: _openContactSheet,
                      ),

                      const SizedBox(height: 18),

                      _ShopHeroCard(
                        storeName: storeName,
                        description: description,
                        logoUrl: logoUrl,
                        coverUrl: coverUrl,
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

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: '$newOrders',
                              label: 'offen',
                              icon: Icons.notifications_active_outlined,
                              danger: newOrders > 0,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              title: '$totalOrders',
                              label: 'gesamt',
                              icon: Icons.receipt_long_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              title: '$realOrders',
                              label: 'direkt',
                              icon: Icons.send_outlined,
                              success: realOrders > 0,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      _ScanHero(
                        onTap: () => _openPage(const ReadOrderPage()),
                      ),

                      const SizedBox(height: 14),

                      _WideActionCard(
                        title: 'Bestellungen',
                        subtitle: 'Offene, gescannte und direkte Orders verwalten',
                        icon: Icons.history_rounded,
                        onTap: () => _openPage(const OrderHistoryPage()),                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Verwalten',
                        style: TextStyle(
                          color: KDashboard.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _SmallActionCard(
                              title: 'Artikel',
                              subtitle: 'Gerichte & Preise',
                              icon: Icons.inventory_2_outlined,
                              onTap: () => _openPage(const MyArticlesPage()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SmallActionCard(
                              title: 'Kategorien',
                              subtitle: 'Menü strukturieren',
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
                              subtitle: 'Daten & Design',
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
                              title: 'Kontakt',
                              subtitle: 'Qrder Hilfe',
                              icon: Icons.call_outlined,
                              onTap: _openContactSheet,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: TextButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded, size: 17),
                          label: const Text('Ausloggen'),
                          style: TextButton.styleFrom(
                            foregroundColor: KDashboard.muted,
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
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

/* UI */

class _TopBar extends StatelessWidget {
  final String storeName;
  final VoidCallback onLogout;
  final VoidCallback onContact;

  const _TopBar({
    required this.storeName,
    required this.onLogout,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: KDashboard.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Q',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            storeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: KDashboard.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Kontakt',
          onPressed: onContact,
          icon: const Icon(
            Icons.support_agent_rounded,
            color: KDashboard.muted,
            size: 21,
          ),
        ),
        IconButton(
          tooltip: 'Ausloggen',
          onPressed: onLogout,
          icon: const Icon(
            Icons.logout_rounded,
            color: KDashboard.muted,
            size: 21,
          ),
        ),
      ],
    );
  }
}

class _ShopHeroCard extends StatelessWidget {
  final String storeName;
  final String description;
  final String logoUrl;
  final String coverUrl;
  final bool isActive;
  final bool qrCodeOrder;
  final bool realOrder;
  final VoidCallback onOpenShop;
  final VoidCallback onCopyLink;
  final VoidCallback onSettings;

  const _ShopHeroCard({
    required this.storeName,
    required this.description,
    required this.logoUrl,
    required this.coverUrl,
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
    final hasCover = coverUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: KDashboard.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: KDashboard.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasCover)
            Positioned.fill(
              child: Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (hasCover)
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.68)),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LogoBox(logoUrl: logoUrl, hasLogo: hasLogo, onDark: hasCover),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasCover ? Colors.white : KDashboard.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
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
                                      ? KDashboard.green
                                      : KDashboard.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  isActive
                                      ? 'Shop online'
                                      : 'Shop pausiert',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: hasCover
                                        ? Colors.white70
                                        : KDashboard.muted,
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
                      icon: Icon(
                        Icons.tune_rounded,
                        color: hasCover ? Colors.white : KDashboard.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasCover ? Colors.white70 : KDashboard.muted,
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
                      glass: hasCover,
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(
                      label: realOrder ? 'Direkt aktiv' : 'Direkt aus',
                      active: realOrder,
                      icon: Icons.send_rounded,
                      glass: hasCover,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Material(
                  color: hasCover
                      ? Colors.white.withOpacity(0.14)
                      : KDashboard.soft,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onOpenShop,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasCover
                              ? Colors.white.withOpacity(0.22)
                              : KDashboard.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: hasCover ? Colors.white : KDashboard.ink,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: hasCover ? KDashboard.ink : Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Zum eigenen Shop',
                                  style: TextStyle(
                                    color: hasCover
                                        ? Colors.white
                                        : KDashboard.ink,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kundensicht prüfen',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: hasCover
                                        ? Colors.white70
                                        : KDashboard.muted,
                                    fontSize: 12.2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: hasCover ? Colors.white70 : KDashboard.muted,
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
                        label: 'Funktionen',
                        icon: Icons.tune_rounded,
                        onTap: onSettings,
                        light: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoBox extends StatelessWidget {
  final String logoUrl;
  final bool hasLogo;
  final bool onDark;

  const _LogoBox({
    required this.logoUrl,
    required this.hasLogo,
    required this.onDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: onDark ? Colors.white : KDashboard.soft,
        shape: BoxShape.circle,
        border: Border.all(
          color: onDark ? Colors.white24 : KDashboard.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? Image.network(
        logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.storefront_outlined,
            color: KDashboard.ink,
            size: 28,
          );
        },
      )
          : const Icon(
        Icons.storefront_outlined,
        color: KDashboard.ink,
        size: 28,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;
  final IconData icon;
  final bool glass;

  const _StatusPill({
    required this.label,
    required this.active,
    required this.icon,
    required this.glass,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? KDashboard.green : KDashboard.red;

    return Expanded(
      child: Container(
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: glass
              ? Colors.white.withOpacity(0.13)
              : active
              ? const Color(0xFFEAF7EF)
              : const Color(0xFFF7EAEA),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: glass
                ? Colors.white.withOpacity(0.18)
                : active
                ? const Color(0xFFCDEBD8)
                : const Color(0xFFEBCACA),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: glass ? Colors.white : color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: glass ? Colors.white : color,
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

class _StatCard extends StatelessWidget {
  final String title;
  final String label;
  final IconData icon;
  final bool danger;
  final bool success;

  const _StatCard({
    required this.title,
    required this.label,
    required this.icon,
    this.danger = false,
    this.success = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color = KDashboard.ink;
    if (danger) color = KDashboard.red;
    if (success) color = KDashboard.green;

    return Container(
      height: 92,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: KDashboard.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: KDashboard.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: KDashboard.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanHero extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanHero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KDashboard.ink,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: KDashboard.ink,
                  size: 38,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR scannen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Bestellung öffnen, prüfen, kassieren.',
                      style: TextStyle(
                        color: Color(0xFFD8D8D8),
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
                size: 28,
              ),
            ],
          ),
        ),
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
      color: KDashboard.card,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: onTap,
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: KDashboard.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -2,
                top: -2,
                child: Icon(
                  icon,
                  color: KDashboard.ink.withOpacity(0.16),
                  size: 34,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: KDashboard.soft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: KDashboard.ink, size: 21),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KDashboard.ink,
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
                      color: KDashboard.muted,
                      fontSize: 12.3,
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
      color: KDashboard.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: KDashboard.line),
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
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: KDashboard.soft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: KDashboard.ink, size: 24),
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
                        color: KDashboard.ink,
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
                        color: KDashboard.muted,
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
                color: KDashboard.muted,
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
  final bool light;

  const _MiniButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: light ? KDashboard.soft : KDashboard.ink,
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
              Icon(
                icon,
                color: light ? KDashboard.ink : Colors.white,
                size: 17,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: light ? KDashboard.ink : Colors.white,
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
        color: KDashboard.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: KDashboard.line),
      ),
      child: SwitchListTile(
        value: value,
        activeColor: KDashboard.ink,
        onChanged: onChanged,
        secondary: Icon(icon, color: KDashboard.ink),
        title: Text(
          title,
          style: const TextStyle(
            color: KDashboard.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: KDashboard.muted,
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KDashboard.soft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: KDashboard.line),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: KDashboard.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: KDashboard.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: KDashboard.muted,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: KDashboard.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetShell extends StatelessWidget {
  final Widget child;

  const _SheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
      decoration: const BoxDecoration(
        color: KDashboard.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: KDashboard.line,
          borderRadius: BorderRadius.circular(99),
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
            color: KDashboard.muted,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String text;

  const _ErrorState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: KDashboard.muted,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/* COLORS */

class KDashboard {
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