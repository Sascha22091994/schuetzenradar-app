import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class TaxiScreen extends StatelessWidget {
  const TaxiScreen({super.key});

  //--------------------------------------------------
  // ✅ ANRUF FUNKTION
  //--------------------------------------------------
  Future<void> _callNumber(String number) async {
    final cleaned = number.replaceAll(" ", "");
    final uri = Uri.parse("tel:$cleaned");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint("Telefon konnte nicht geöffnet werden");
    }
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final taxis = [
      ["Alt Espelkamp, Kleindorf", "Taxi Urban", "05772 3000"],
      ["Rahden, Preußisch Ströhen, Sielhorst, Steinbrink, Stelle, Tonnenheide, Varl, Wehe",
        "Taxi Urban",
        "05771 844"],
      ["Rahden", "Wolfgang Kassen Taxi", "05771 1060"],
      ["Lavelsloh", "Taxi Osterkamp", "05763 2526"],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Taxis in deiner Nähe"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: taxis.map((t) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            child: ListTile(
              leading: const Icon(
                Icons.local_taxi,
                color: Colors.amber,
              ),

              //--------------------------------------------------
              // ✅ NAME
              //--------------------------------------------------
              title: Text(
                t[1],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              //--------------------------------------------------
              // ✅ SAUBERE STRUKTUR
              //--------------------------------------------------
  subtitle: Padding(
  padding: const EdgeInsets.only(top: 4),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("📍 Gebiet:"),

      const SizedBox(height: 2),

      ...t[0].split(",").map((place) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text("• ${place.trim()}"),
          )),

      const SizedBox(height: 4),

      Text(
        "📞 ${t[2]}",
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ],
  ),
),


              isThreeLine: true,

              //--------------------------------------------------
              // ✅ GANZER EINTRAG KLICKBAR
              //--------------------------------------------------
              onTap: () => _callNumber(t[2]),

              //--------------------------------------------------
              // ✅ CALL BUTTON
              //--------------------------------------------------
              trailing: IconButton(
                icon: const Icon(
                  Icons.phone,
                  color: Colors.green,
                ),
                onPressed: () => _callNumber(t[2]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}