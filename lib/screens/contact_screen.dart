import 'package:flutter/material.dart';
import '../services/email_service.dart';
import 'legal_screen.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  //--------------------------------------------------
  // UI
  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontakt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
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

          //--------------------------------------------------
          // HEADER
          //--------------------------------------------------
          const Text(
            '💬 Feedback & Kontakt',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          //--------------------------------------------------
          // BESCHREIBUNG
          //--------------------------------------------------
       
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

          const SizedBox(height: 30),

          //--------------------------------------------------
          // RECHTLICHES
          //--------------------------------------------------
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
