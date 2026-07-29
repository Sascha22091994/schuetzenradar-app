import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  //--------------------------------------------------
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  //--------------------------------------------------
  // ✅ Wiederverwendbare Section-Card, konsistent zum Rest der App
  // (Icon + Titel-Row wie in event_detail_screen.dart, Card-Radius 16
  // wie überall sonst).
  //--------------------------------------------------
  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyTextColor = isDark ? Colors.grey.shade300 : Colors.grey.shade800;

    return Scaffold(
      appBar: AppBar(
        // ✅ ANGEPASST: flache Primärfarbe statt grünem Gradient –
        // konsistent zu jeder anderen AppBar in der App
        title: const Text(
          "Impressum & Datenschutz",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          //--------------------------------------------------
          // ✅ IMPRESSUM
          //--------------------------------------------------
          _buildSection(
            icon: Icons.description_outlined,
            title: "Impressum",
            isDark: isDark,
            children: [
              Text(
                "Angaben gemäß § 5 TMG\n\n"
                "ErlebnisRadar\n"
                "Inhaber:\n"
                "Sascha Langhorst\n\n"
                "E-Mail:\n"
                "info-ErlebnisRadar@web.de\n\n"
                "Verantwortlich für den Inhalt nach § 55 Abs. 2 RStV:\n"
                "Sascha Langhorst\n\n"
                "Haftung für Inhalte:\n"
                "Die Inhalte dieser App wurden mit größter Sorgfalt erstellt. "
                "Für die Richtigkeit, Vollständigkeit und Aktualität wird keine Gewähr übernommen.\n\n"
                "Haftung für Links:\n"
                "Diese App enthält ggf. Links zu externen Webseiten Dritter, "
                "auf deren Inhalte kein Einfluss besteht.",
                style: TextStyle(color: bodyTextColor, height: 1.4),
              ),
            ],
          ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // ✅ DATENSCHUTZ
          //--------------------------------------------------
          _buildSection(
            icon: Icons.privacy_tip_outlined,
            title: "Datenschutz",
            isDark: isDark,
            children: [
              Text(
                "Die Nutzung der App „ErlebnisRadar“ ist in der Regel ohne Angabe "
                "personenbezogener Daten möglich.\n\n"
                "Diese App nutzt Google Firebase zur Bereitstellung von Inhalten "
                "(z. B. Datenbank und Bilder-Upload). "
                "Dabei können technische Daten verarbeitet werden.",
                style: TextStyle(color: bodyTextColor, height: 1.4),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => _openUrl(
                  "https://github.com/Sascha22091994/ErlebnisRadar-legal/blob/main/privacy-policy.md",
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Zur vollständigen Datenschutzerklärung",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // ✅ KONTAKT
          //--------------------------------------------------
          _buildSection(
            icon: Icons.mail_outline_rounded,
            title: "Kontakt",
            isDark: isDark,
            children: [
              Text(
                "info-ErlebnisRadar@web.de",
                style: TextStyle(color: bodyTextColor),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}