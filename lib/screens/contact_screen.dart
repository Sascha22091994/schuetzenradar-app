import 'package:flutter/material.dart';
//import 'package:url_launcher/url_launcher.dart';

import '../services/email_service.dart';
import 'legal_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'submit_news_screen.dart';
import 'submit_festival_screen.dart';
import 'adler_login_screen.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});
/*
  //--------------------------------------------------
  // ✅ PAYPAL LINK + DANKE POPUP
  //--------------------------------------------------
  Future<void> _openPayPal(BuildContext context) async {
    final uri = Uri.parse("https://paypal.me/SaschaLanghorst");

    await launchUrl(uri, mode: LaunchMode.externalApplication);

    //--------------------------------------------------
    // ✅ DANKE POPUP
    //--------------------------------------------------
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🍺 Danke dir! Prost und viel Spaß weiterhin!"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
*/
  //--------------------------------------------------
Future<void> _openInstagram() async {
  final uri = Uri.parse("https://www.instagram.com/schuetzenradar/");
  await launchUrl(uri, mode: LaunchMode.externalApplication);
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
          Icon(Icons.contact_mail_outlined,
              color: Colors.white, size: 35),
          SizedBox(width: 8),
          Text(
            "Kontakt",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    ),

    //--------------------------------------------------
    // ✅ BODY (FIXED!)
    //--------------------------------------------------
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [

        //--------------------------------------------------
        // HEADLINE
        //--------------------------------------------------
        const Text(
          "Wie kann ich dir helfen?",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          "Wähle einfach den passenden Bereich aus:",
        ),

        const SizedBox(height: 20),

        //--------------------------------------------------
        // FEST EINREICHEN
        //--------------------------------------------------
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SubmitFestivalScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: const [
                Icon(Icons.event, color: Colors.green, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "🎉 Fest einreichen\nFehlt ein Schützenfest oder sind Daten falsch?",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        //--------------------------------------------------
        // NEWS EINREICHEN
        //--------------------------------------------------
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SubmitNewsScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Row(
              children: const [
                Icon(Icons.article, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "📰 News einreichen\nNeue Infos, Updates oder Highlights melden",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        //--------------------------------------------------
        // NACHRICHT SENDEN
        //--------------------------------------------------
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            EmailService.sendFeedback();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: const [
                Icon(Icons.email, color: Colors.black87, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "💬 Nachricht senden\nFeedback, Fehler oder sonstige Anliegen",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),



//--------------------------------------------------
// 🦅 ADLER INFO + DEMO
//--------------------------------------------------
Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.orange.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.orange.shade300),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "🦅 Live-Adlerschießen",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),

      const SizedBox(height: 6),

      const Text(
        "Mit SchützenRadar kannst du das Adlerschießen live verfolgen.\n\n"
        "Vereine können Teilnehmer eintragen, Schüsse zählen und den Stand in Echtzeit anzeigen.\n\n"
        "👉 Du möchtest das für dein Fest nutzen?\n"
        "Dann sende einfach eine Nachricht mit Ort und Veranstaltung.",
      ),

      const SizedBox(height: 12),

      //--------------------------------------------------
      // ✅ DEMO BUTTON
      //--------------------------------------------------
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdlerLoginScreen(
                locationId: "demo",
                locationName: "Demo",
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: const [
              Icon(Icons.play_arrow, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Demo ansehen",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 12),
            ],
          ),
        ),
      ),
    ],
  ),
),
      //--------------------------------------------------
        // INSTAGRAM
        //--------------------------------------------------

const SizedBox(height: 16),

ElevatedButton.icon(
  onPressed: _openInstagram,
  icon: const Icon(Icons.camera_alt),
  label: const Text("Instagram besuchen"),
),

const SizedBox(height: 24),

const SizedBox(height: 16),

ElevatedButton.icon(
  onPressed: () async {
    final uri = Uri.parse(
      "https://sascha22091994.github.io/schuetzenradar-legal/",
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);

    // ✅ kleines Danke Feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("💛 Danke für deinen Support!"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  },
  icon: const Icon(Icons.favorite),
  label: const Text("💚 Projekt unterstützen"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
  ),
),


        //--------------------------------------------------
        // RECHTLICHES
        //--------------------------------------------------
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LegalScreen(),
              ),
            );
          },
          icon: const Icon(Icons.description),
          label: const Text("Impressum & Datenschutz"),
        ),

        const SizedBox(height: 20),
      ],
    ),
  );
}}

