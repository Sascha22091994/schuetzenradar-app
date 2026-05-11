import 'package:url_launcher/url_launcher.dart';

class EmailService {

  //--------------------------------------------------
  // ✅ FEEDBACK SENDEN (FLEXIBEL)
  //--------------------------------------------------
  static Future<void> sendFeedback({
    String subject = "SchützenRadar – Feedback & Kontakt",
    String body = _defaultBody,
  }) async {

    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info-schuetzenradar@web.de',
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  //--------------------------------------------------
  // ✅ STANDARD TEXT (VERBESSERT)
  //--------------------------------------------------
  static const String _defaultBody = '''
Hallo,

vielen Dank für diese tolle App! Ich habe folgendes Anliegen:

☐ Fehler melden
☐ Änderung vorschlagen
☐ Neues Schützenfest eintragen
☐ News einreichen
☐ Zugang Adlerschießen anfragen

--------------------------------------

📍 Ort / Schützenfest:

📅 Datum:

📝 Beschreibung / Infos:

--------------------------------------

Weitere Anmerkungen:




--------------------------------------

Vielen Dank für deinen Einsatz und die Weiterentwicklung der App! 🍻
''';
}
