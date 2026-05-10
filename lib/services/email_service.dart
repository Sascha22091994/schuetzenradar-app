import 'package:url_launcher/url_launcher.dart';

class EmailService {
  static Future<void> sendFeedback() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info-schuetzenradar@web.de', // 👈 HIER DEINE MAIL
      queryParameters: {
        'subject': 'Schützenfeste App – Feedback',
        'body': '''
Hallo,

ich habe folgendes Anliegen:

[ ] Fehler melden
[ ] Änderung vorschlagen
[ ] Neues Schützenfest eintragen
[ ] News einreichen

--------------------------------------

Beschreibung:

Ort / Schützenfest:

Datum:

Weitere Infos:

--------------------------------------

Vielen Dank!
''',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}
