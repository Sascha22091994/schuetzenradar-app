import 'package:flutter/material.dart';
import '../services/email_service.dart';
import 'legal_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'submit_event_screen.dart';
import '../theme/app_colors.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  //--------------------------------------------------
  Future<void> _openInstagram() async {
    final uri = Uri.parse("https://www.instagram.com/ErlebnisRadar/");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openSupportLink(BuildContext context) async {
    final uri = Uri.parse(
      "https://sascha22091994.github.io/ErlebnisRadar-legal/",
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Danke für deinen Support!"),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  //--------------------------------------------------
  // ✅ Wiederverwendbare Zeile, identisch zum Profil/Einstellungen-Stil
  //--------------------------------------------------
  Widget _actionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        // ✅ ANGEPASST: schlichter, fett gesetzter Titel ohne Icon-Row –
        // konsistent zu Kalender/Profil/Einstellungen/Detailseite
        title: const Text(
          "Kontakt",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          Text(
            "Willkommen bei ErlebnisRadar",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "Kontaktiere uns, reiche neue Events ein oder sende Feedback.",
            style: TextStyle(color: secondaryTextColor),
          ),

          const SizedBox(height: 20),

          //--------------------------------------------------
          // ✅ EVENT & FEEDBACK, jetzt als gruppierte Card (konsistent
          // zu Profil/Einstellungen statt eigenständiger Container)
          //--------------------------------------------------
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _actionRow(
                  icon: Icons.event_available_rounded,
                  iconColor: AppColors.primary,
                  title: "Event einreichen",
                  subtitle: "Fehlt eine Veranstaltung oder sind Infos falsch?",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubmitEventScreen()),
                    );
                  },
                ),
                Divider(color: dividerColor, height: 1),
                _actionRow(
                  icon: Icons.email_outlined,
                  iconColor: AppColors.secondary,
                  title: "Nachricht senden",
                  subtitle: "Feedback, Fehler oder sonstige Anliegen",
                  onTap: () => EmailService.sendFeedback(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          //--------------------------------------------------
          // ✅ FÜR VERANSTALTER
          //--------------------------------------------------
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign_outlined, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        "Für Veranstalter",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Mit ErlebnisRadar könnt ihr eure Events professionell präsentieren – "
                    "mit Bildern, Highlights, Instagram-Verlinkung und mehr Sichtbarkeit. "
                    "Für besondere Hervorhebung meldet euch gerne direkt bei uns.",
                    style: TextStyle(color: secondaryTextColor, height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          //--------------------------------------------------
          // ✅ WEITERE LINKS, ebenfalls als gruppierte Card
          //--------------------------------------------------
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _actionRow(
                  icon: Icons.camera_alt_outlined,
                  iconColor: secondaryTextColor,
                  title: "Instagram",
                  subtitle: "@ErlebnisRadar",
                  onTap: _openInstagram,
                ),
                Divider(color: dividerColor, height: 1),
                _actionRow(
                  icon: Icons.favorite_outline,
                  iconColor: const Color(0xFFEF4444),
                  title: "ErlebnisRadar unterstützen",
                  subtitle: "Hilf mit, die App weiterzuentwickeln",
                  onTap: () => _openSupportLink(context),
                ),
                Divider(color: dividerColor, height: 1),
                _actionRow(
                  icon: Icons.description_outlined,
                  iconColor: secondaryTextColor,
                  title: "Impressum & Datenschutz",
                  subtitle: "Rechtliche Informationen",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LegalScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}