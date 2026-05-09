import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'landingPage.dart';
import 'readOrderPage.dart';
import 'orderHistoryPage.dart';
import 'myArticlesPage.dart';
import 'myArticlesAvailabilityPage.dart';
import 'myAccountPage.dart';
import 'MyCategoriesPage.dart';
import '../customer/restaurantPage.dart';

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

  int _selectedIndex = 1;

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

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    if (index == 0) {
      _logout();
      return;
    }

    if (index == 2) {
      _openPage(const MyAccountPage());
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = _merchantRef;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Q',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              'Qrder',
              style: TextStyle(
                color: _ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout_rounded,
              color: _muted,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ref == null
            ? _emptyState()
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ref.snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();

            final storeName =
            data?['name']?.toString().trim().isNotEmpty == true
                ? data!['name'].toString()
                : 'Dein Restaurant';

            final logoUrl =
            data?['logoUrl']?.toString().trim().isNotEmpty == true
                ? data!['logoUrl'].toString()
                : null;

            final isActive = data?['isActive'] as bool? ?? true;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(
                    storeName: storeName,
                    logoUrl: logoUrl,
                    isActive: isActive,
                  ),

                  const SizedBox(height: 16),

                  _scanHero(),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _SmallActionCard(
                          title: 'Orders',
                          subtitle: 'lesen',
                          icon: Icons.receipt_long_rounded,
                          onTap: () => _openPage(const ReadOrderPage()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SmallActionCard(
                          title: 'Historie',
                          subtitle: 'ansehen',
                          icon: Icons.history_rounded,
                          onTap: () =>
                              _openPage(const OrderHistoryPage()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

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
                          title: 'Verfügbar',
                          subtitle: 'anpassen',
                          icon: Icons.event_available_rounded,
                          onTap: () => _openPage(
                            const MyArticlesAvailabilityPage(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _SmallActionCard(
                          title: 'Kategorien',
                          subtitle: 'ordnen',
                          icon: Icons.category_outlined,
                          onTap: () =>
                              _openPage(const MyCategoriesPage()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SmallActionCard(
                          title: 'Mein Laden',
                          subtitle: 'anzeigen',
                          icon: Icons.storefront_outlined,
                          onTap: () => _openPage(const RestaurantPage()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: _bg,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
          selectedItemColor: _ink,
          unselectedItemColor: const Color(0xFFBBBBBB),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.logout_outlined),
              activeIcon: Icon(Icons.logout_rounded),
              label: 'Logout',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded),
              activeIcon: Icon(Icons.qr_code_scanner_rounded),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Kein eingeloggter Nutzer gefunden.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _muted,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _headerCard({
    required String storeName,
    required String? logoUrl,
    required bool isActive,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _LogoBox(logoUrl: logoUrl),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF2E9E5B) : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isActive ? 'Bereit für Bestellungen' : 'Deaktiviert',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openPage(const MyAccountPage()),
            icon: const Icon(
              Icons.settings_rounded,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanHero() {
    return Material(
      color: _ink,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () => _openPage(const ReadOrderPage()),
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
                    color: _gold,
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
                      color: _ink,
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

class _LogoBox extends StatelessWidget {
  final String? logoUrl;

  const _LogoBox({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.trim().isNotEmpty;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEBE4),
        borderRadius: BorderRadius.circular(17),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? Image.network(
        logoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.storefront_outlined,
            color: Color(0xFF1A1A1A),
            size: 28,
          );
        },
      )
          : const Icon(
        Icons.storefront_outlined,
        color: Color(0xFF1A1A1A),
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
      color: const Color(0xFFFFFEFB),
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: onTap,
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: const Color(0xFFE7E2D9)),
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
                  color: const Color(0xFF1A1A1A).withOpacity(0.18),
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
                      color: const Color(0xFFEEEBE4),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF1A1A1A),
                      size: 21,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
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
                      color: Color(0xFF777777),
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

class _DarkChip extends StatelessWidget {
  final String icon;
  final String label;

  const _DarkChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}