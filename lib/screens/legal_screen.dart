import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  //--------------------------------------------------
  // ✅ LINK ÖFFNEN
  //--------------------------------------------------
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  elevation: 0,
  backgroundColor: Colors.green.shade700,

  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.green.shade800,
          Colors.green.shade600,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),

  title: Row(
    children: const [
      Icon(Icons.privacy_tip_outlined, color: Colors.white, size: 35),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          "Impressum & Datenschutz",
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            letterSpacing: 0.4,
          ),
        ),
      ),
    ],
  ),
),


      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          //--------------------------------------------------
          // IMPRESSUM
          //--------------------------------------------------
          const Text(
            "📄 Impressum",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Angaben gemäß § 5 TMG\n\n"

            "SchützenRadar\n"
            "Inhaber:\n"
            "Sascha Langhorst\n\n"

            "E-Mail:\n"
            "info-schuetzenradar@web.de\n\n"

            "Verantwortlich für den Inhalt nach § 55 Abs. 2 RStV:\n"
            "Sascha Langhorst\n\n"

            "Haftung für Inhalte:\n"
            "Die Inhalte dieser App wurden mit größter Sorgfalt erstellt. "
            "Für die Richtigkeit, Vollständigkeit und Aktualität wird keine Gewähr übernommen.\n\n"

            "Haftung für Links:\n"
            "Diese App enthält ggf. Links zu externen Webseiten Dritter, "
            "auf deren Inhalte kein Einfluss besteht.",
          ),

          const SizedBox(height: 30),

          //--------------------------------------------------
          // DATENSCHUTZ
          //--------------------------------------------------
          const Text(
            "🔒 Datenschutz",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Die Nutzung der App „SchützenRadar“ ist in der Regel ohne Angabe "
            "personenbezogener Daten möglich.\n\n"

            "Diese App nutzt Google Firebase zur Bereitstellung von Inhalten "
            "(z. B. Datenbank und Bilder-Upload). "
            "Dabei können technische Daten verarbeitet werden.\n\n"

            "Weitere Informationen:\n",
          ),
/*
const SizedBox(height: 20),

const Text(
  "💸 Spendenhinweis\n\n"

  "In dieser App besteht die Möglichkeit, den Entwickler freiwillig "
  "über einen externen Dienst (PayPal) zu unterstützen.\n\n"

  "Es handelt sich dabei um freiwillige Spenden ohne Gegenleistung.\n"
  "Es werden keine digitalen Inhalte oder Funktionen verkauft.\n\n"

  "Die Zahlungsabwicklung erfolgt ausschließlich über PayPal. "
  "Es gelten die Datenschutzbestimmungen von PayPal.",
),
*/
          //--------------------------------------------------
          // ✅ LINK ZU GITHUB PRIVACY
          //--------------------------------------------------
          GestureDetector(
            onTap: () => _openUrl(
              "https://github.com/Sascha22091994/schuetzenradar-legal/blob/main/privacy-policy.md",
            ),
            child: const Text(
              "Zur vollständigen Datenschutzerklärung →",
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "📬 Kontakt:\n"
            "info-schuetzenradar@web.de",
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}