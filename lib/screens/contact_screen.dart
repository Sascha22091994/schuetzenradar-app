import 'package:flutter/material.dart';
//import 'package:url_launcher/url_launcher.dart';

import '../services/email_service.dart';
import 'legal_screen.dart';

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
      Icon(Icons.contact_mail_outlined, color: Colors.white, size: 35),
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

  actions: [
    IconButton(
      icon: const Icon(Icons.campaign_outlined),
      tooltip: 'Feedback senden',
      onPressed: () {
        EmailService.sendFeedback();
      },
    ),
  ],
),


      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text(
            '💬 Feedback & Kontakt',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Diese App lebt von aktuellen Informationen und eurer Unterstützung.\n\n'

            '👉 Fehlt ein Schützenfest?\n'
            '👉 Sind Daten nicht mehr aktuell?\n'
            '👉 Gibt es neue Infos oder Änderungen?\n'
            '👉 Hast du Ideen zur Verbesserung?\n\n'

            'Dann melde dich gerne – jede Info hilft!\n\n'

            '------------------------------\n\n'

            '🦅 Adlerbereich (Live-Adlerschießen)\n\n'

            'Du möchtest das Adlerschießen für dein Schützenfest live eintragen?\n\n'

            '👉 Schreib uns einfach eine Nachricht\n'
            '👉 Nenne den Ort / das Schützenfest\n\n'

            'Du erhältst dann Zugriff für den Live-Bereich.\n\n'

            'So können:\n'
            '• Teilnehmer eingetragen werden\n'
            '• Schüsse gezählt werden\n'
            '• der Königsstand live verfolgt werden\n\n'

            '------------------------------\n\n'

            '📬 Kontakt\n\n'

            'Tippe auf "Nachricht senden", um uns direkt eine E-Mail zu schicken.\n\n'

            'Vielen Dank für deine Unterstützung! 🙌',
          ),

          const SizedBox(height: 20),

          //--------------------------------------------------
          // MAIL BUTTON
          //--------------------------------------------------
          ElevatedButton.icon(
            onPressed: () {
              EmailService.sendFeedback();
            },
            icon: const Icon(Icons.email),
            label: const Text('Nachricht senden'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          //--------------------------------------------------
          // 🍻 SUPPORT
          //--------------------------------------------------
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 20),

          const Text(
            "🍻 Support",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Wenn dir die App gefällt und du mich unterstützen möchtest,\n"
            "dann gib mir doch einfach ein Bier aus 🍺\n\n"
            "Vielen Dank für deinen Support 🙌",
          ),

          const SizedBox(height: 15),

          //--------------------------------------------------
          // ✅ ANIMIERTER BUTTON
          //--------------------------------------------------
          /*_AnimatedBeerButton(
            onPressed: () => _openPayPal(context),
          ),
*/
          //--------------------------------------------------
          // RECHTLICHES
          //--------------------------------------------------
          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalScreen(),
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
  }
}

//////////////////////////////////////////////////////
// ✅ ANIMIERTER BUTTON (SUBTIL)
//////////////////////////////////////////////////////

class _AnimatedBeerButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedBeerButton({required this.onPressed});

  @override
  State<_AnimatedBeerButton> createState() => _AnimatedBeerButtonState();
}

class _AnimatedBeerButtonState extends State<_AnimatedBeerButton>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scale = Tween(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: ElevatedButton.icon(
        onPressed: widget.onPressed,
        icon: const Icon(Icons.local_drink),
        label: const Text("🍺 Bier ausgeben"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}