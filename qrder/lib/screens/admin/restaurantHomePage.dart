import 'package:flutter/material.dart';
import 'landingPage.dart';
import 'readOrderPage.dart';
import 'orderHistoryPage.dart';
import 'myArticlesPage.dart';
import 'myArticlesAvailabilityPage.dart';
import 'myAccountPage.dart';
import 'MyCategoriesPage.dart';
import 'orderPage.dart';
import '../customer/restaurantPage.dart';

class RestaurantHomePage extends StatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  State<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  int _selectedIndex = 1;

  void _goToLandingPage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
          (route) => false,
    );
  }

  void _openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      _goToLandingPage();
    }

    if (index == 1) {
      // Schon hier
    }

    if (index == 2) {
      _openPage(const MyAccountPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F1),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            _MiniDashboardCard(
              title: 'Mein Shop',
              icon: Icons.storefront_outlined,
              onTap: () => _openPage(const RestaurantPage()),
            ),
            _MiniDashboardCard(
              title: 'My Categories',
              icon: Icons.category_outlined,
              onTap: () => _openPage(const MyCategoriesPage()),
            ),
            _MiniDashboardCard(
              title: 'My Articles',
              icon: Icons.inventory_2_outlined,
              onTap: () => _openPage(const MyArticlesPage()),
            ),
            _MiniDashboardCard(
              title: 'Verfügbarkeit',
              icon: Icons.event_available_rounded,
              onTap: () => _openPage(const MyArticlesAvailabilityPage()),
            ),
            _MiniDashboardCard(
              title: 'Account Data',
              icon: Icons.person_outline_rounded,
              onTap: () => _openPage(const MyAccountPage()),
            ),
            _MiniDashboardCard(
              title: 'Logout',
              icon: Icons.logout_rounded,
              onTap: _goToLandingPage,
            ),
          ],        ),
        actions: [
          TextButton(
            onPressed: _goToLandingPage,
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFCF9),
                  borderRadius: BorderRadius.circular(28),
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
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEBE4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.storefront_outlined,
                        color: Color(0xFF1A1A1A),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restaurant Dashboard',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Babel Imbiss Frankfurt',
                            style: TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Schnellzugriff',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 14),

              _PrimaryDashboardCard(
                title: 'Bestellungen lesen',
                subtitle: 'Neue Orders direkt sehen und öffnen.',
                icon: Icons.receipt_long_rounded,
                onTap: () => _openPage(const ReadOrderPage()),
              ),

              const SizedBox(height: 14),

              _DashboardCard(
                title: 'Order History',
                subtitle: 'Vergangene Bestellungen ansehen.',
                icon: Icons.history_rounded,
                onTap: () => _openPage(const OrderHistoryPage()),
              ),

              const SizedBox(height: 22),

              const Text(
                'Verwaltung',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.15,
                children: [
                  _MiniDashboardCard(
                    title: 'Mein Shop',
                    icon: Icons.storefront_outlined,
                    onTap: () => _openPage(const RestaurantPage()),
                  ),
                  _MiniDashboardCard(
                    title: 'My Categories',
                    icon: Icons.category_outlined,
                    onTap: () => _openPage(const MyCategoriesPage()),
                  ),
                  _MiniDashboardCard(
                    title: 'My Articles',
                    icon: Icons.inventory_2_outlined,
                    onTap: () => _openPage(const MyArticlesPage()),
                  ),
                  _MiniDashboardCard(
                    title: 'Verfügbarkeit',
                    icon: Icons.event_available_rounded,
                    onTap: () => _openPage(const MyArticlesAvailabilityPage()),
                  ),
                  _MiniDashboardCard(
                    title: 'Account Data',
                    icon: Icons.person_outline_rounded,
                    onTap: () => _openPage(const MyAccountPage()),
                  ),
                  _MiniDashboardCard(
                    title: 'Logout',
                    icon: Icons.logout_rounded,
                    onTap: _goToLandingPage,
                  ),
                ],
              ),
              const SizedBox(height: 26),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _TrustChip(icon: '📦', label: 'Orders im Blick'),
                  _TrustChip(icon: '🧾', label: 'Klare Verwaltung'),
                  _TrustChip(icon: '⚡', label: 'Schneller Zugriff'),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          color: Color(0xFFF8F6F1),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onNavTap,
          selectedItemColor: const Color(0xFF1A1A1A),
          unselectedItemColor: const Color(0xFFBBBBBB),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
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
}

class _PrimaryDashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryDashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 28),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFD8D8D8),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFDFCF9),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE7E2D9),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEBE4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF1A1A1A), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF999999),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniDashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniDashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFDFCF9),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE7E2D9),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEBE4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF1A1A1A), size: 22),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final String icon;
  final String label;

  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEBE4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}