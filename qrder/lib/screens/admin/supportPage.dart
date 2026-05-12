import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const Color _bg = Color(0xFFF8F6F1);
  static const Color _card = Color(0xFFFFFEFB);
  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _muted = Color(0xFF777777);
  static const Color _soft = Color(0xFFEEEBE4);
  static const Color _line = Color(0xFFE7E2D9);
  static const Color _gold = Color(0xFFD8A75D);
  static const Color _green = Color(0xFF2E9E5B);
  static const Color _red = Color(0xFFD83A34);

  static const String _whatsappNumber = '491771816751';
  static const String _email = 'nabell.321@gmail.com';
  static const String _instagramUrl = 'https://instagram.com/lifeofnabel';

  Future<void> _openUrl(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!ok && context.mounted) {
        _showSnack(context, 'Konnte nicht geöffnet werden.');
      }
    } catch (_) {
      if (context.mounted) {
        _showSnack(context, 'Konnte nicht geöffnet werden.');
      }
    }
  }

  void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent('Hallo, ich brauche Hilfe mit Qrder.')}',
    );

    await _openUrl(context, uri);
  }

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      queryParameters: {
        'subject': 'Qrder Support',
        'body': 'Hallo, ich brauche Hilfe mit Qrder.\n\nProblem:\n',
      },
    );

    await _openUrl(context, uri);
  }

  Future<void> _openInstagram(BuildContext context) async {
    await _openUrl(context, Uri.parse(_instagramUrl));
  }

  Future<void> _reportProblem(BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent('Problem melden – Qrder\n\nWas ist passiert?\n\nScreenshot vorhanden: Ja/Nein\n\nLadenname:\n')}',
    );

    await _openUrl(context, uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(context),

              const SizedBox(height: 24),

              const Text(
                'Support',
                style: TextStyle(
                  color: _ink,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hilfe, Kontakt und schnelle Antworten für deinen Qrder-Laden.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              _HeroSupportCard(
                onWhatsApp: () => _openWhatsApp(context),
                onProblem: () => _reportProblem(context),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _SupportSmallCard(
                      title: 'E-Mail',
                      subtitle: _email,
                      icon: Icons.email_outlined,
                      onTap: () => _openEmail(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SupportSmallCard(
                      title: 'Instagram',
                      subtitle: '@lifeofnabel',
                      icon: Icons.alternate_email_rounded,
                      onTap: () => _openInstagram(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _SectionCard(
                title: 'FAQ',
                subtitle: 'Kurze Antworten, bevor Chaos tanzt.',
                children: const [
                  _FaqItem(
                    question: 'Wie bekomme ich meinen QR-Code?',
                    answer:
                    'Dein QR-Code zeigt später direkt auf deine Restaurant-Seite. Du kannst ihn für Tische, Flyer oder Sticker nutzen.',
                  ),
                  _FaqItem(
                    question: 'Kann ich Artikel selbst bearbeiten?',
                    answer:
                    'Ja. Über Artikel und Kategorien kannst du dein Menü pflegen.',
                  ),
                  _FaqItem(
                    question: 'Was passiert, wenn ein Artikel ausverkauft ist?',
                    answer:
                    'Du kannst ihn deaktivieren. Kunden sehen ihn dann grau oder weiter unten.',
                  ),
                  _FaqItem(
                    question: 'Kann ich mein Logo ändern?',
                    answer:
                    'Ja. Unter Mein Laden kannst du dein Logo hochladen und speichern.',
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _SectionCard(
                title: 'Anleitung',
                subtitle: 'Mini-Ablauf für den Alltag.',
                children: const [
                  _GuideStep(
                    number: '1',
                    title: 'Artikel prüfen',
                    text: 'Kontrolliere Preise, Bilder und Verfügbarkeit.',
                  ),
                  _GuideStep(
                    number: '2',
                    title: 'QR-Code nutzen',
                    text: 'QR-Code am Tisch, Tresen oder auf Flyer platzieren.',
                  ),
                  _GuideStep(
                    number: '3',
                    title: 'Bestellung scannen',
                    text: 'Kunde bestellt, Team scannt QR und bearbeitet die Bestellung.',
                  ),
                  _GuideStep(
                    number: '4',
                    title: 'Problem melden',
                    text: 'Bei Fehlern Screenshot machen und per WhatsApp senden.',
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _SectionCard(
                title: 'Live Chat / Problem melden',
                subtitle: 'Schnellster Weg: WhatsApp.',
                children: [
                  _WideButton(
                    label: 'Problem per WhatsApp melden',
                    icon: Icons.report_problem_outlined,
                    color: _red,
                    onTap: () => _reportProblem(context),
                  ),
                  const SizedBox(height: 10),
                  _WideButton(
                    label: 'Support per WhatsApp öffnen',
                    icon: Icons.chat_bubble_outline_rounded,
                    color: _green,
                    onTap: () => _openWhatsApp(context),
                  ),
                ],
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
            'Qrder Hilfe',
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

class _HeroSupportCard extends StatelessWidget {
  final VoidCallback onWhatsApp;
  final VoidCallback onProblem;

  const _HeroSupportCard({
    required this.onWhatsApp,
    required this.onProblem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Color(0xFF1A1A1A),
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Brauchst du Hilfe?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Schreib direkt per WhatsApp. Kein Formular-Wald, kein Ticket-Labyrinth.',
            style: TextStyle(
              color: Color(0xFFD8D8D8),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  label: 'WhatsApp',
                  icon: Icons.chat_rounded,
                  onTap: onWhatsApp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroButton(
                  label: 'Problem',
                  icon: Icons.bug_report_outlined,
                  onTap: onProblem,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HeroButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
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

class _SupportSmallCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SupportSmallCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFEFB),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 122,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
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
            children: [
              Positioned(
                right: -2,
                top: -2,
                child: Icon(
                  icon,
                  color: const Color(0xFF1A1A1A).withOpacity(0.14),
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
                      fontSize: 12.2,
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

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        iconColor: const Color(0xFF1A1A1A),
        collapsedIconColor: const Color(0xFF777777),
        title: Text(
          question,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String title;
  final String text;

  const _GuideStep({
    required this.number,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
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
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 12.8,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
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

class _WideButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _WideButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}