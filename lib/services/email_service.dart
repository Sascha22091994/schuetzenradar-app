import 'package:url_launcher/url_launcher.dart';

class EmailService {

  static Future<void> sendFeedback({
    String subject = "SchützenRadar – Feedback & Kontakt",
    String body = _defaultBody,
  }) async {

    final Uri emailUri = Uri.parse(
      'mailto:info-schuetzenradar@web.de'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      print("Keine Mail-App gefunden");
    }
  }

  static const String _defaultBody = '''
Hallo,

vielen Dank für die tolle App! 🙌
Ich habe folgendes Anliegen:

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

Vielen Dank für deinen Einsatz und die Weiterentwicklung! 🍻
''';
}