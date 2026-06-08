import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import '../services/admin_service.dart';

class SubmissionAdminScreen extends StatelessWidget {
  const SubmissionAdminScreen({super.key});

  //--------------------------------------------------
  String _formatInstagram(String input) {
    if (input.isEmpty) return "";
    if (input.startsWith("http")) return input;
    return "https://instagram.com/$input";
  }

  String _formatWebsite(String input) {
    if (input.isEmpty) return "";
    if (input.startsWith("http")) return input;
    return "https://$input";
  }

  //--------------------------------------------------
  // ✅ ROBUST GEO CODING
  //--------------------------------------------------
  Future<Map<String, double>> _getCoordinates(
      String address, String location) async {
    try {
      // ✅ 1. Versuch: komplette Adresse
      final fullAddress = "$address, Deutschland";
      final result1 = await locationFromAddress(fullAddress);

      if (result1.isNotEmpty) {
        final loc = result1.first;
        debugPrint("✅ GEO (Adresse): ${loc.latitude}, ${loc.longitude}");

        return {"lat": loc.latitude, "lng": loc.longitude};
      }
    } catch (e) {
      debugPrint("⚠️ Adresse fehlgeschlagen: $e");
    }

    try {
      // ✅ 2. Fallback: nur Ort
      final fallback = "$location, Deutschland";
      final result2 = await locationFromAddress(fallback);

      if (result2.isNotEmpty) {
        final loc = result2.first;
        debugPrint("✅ GEO (Ort): ${loc.latitude}, ${loc.longitude}");

        return {"lat": loc.latitude, "lng": loc.longitude};
      }
    } catch (e) {
      debugPrint("❌ Fallback fehlgeschlagen: $e");
    }

    // ❌ ALLES fehlgeschlagen
    debugPrint("❌ KEINE GEO DATEN für: $address / $location");

    return {"lat": 0, "lng": 0};
  }

  //--------------------------------------------------
  void _openModeration(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final name = TextEditingController(text: data['name'] ?? '');
    final location = TextEditingController(text: data['location'] ?? '');
    final address = TextEditingController(text: data['address'] ?? '');
    final description = TextEditingController(text: data['description'] ?? '');
    final highlights = TextEditingController(text: data['highlights'] ?? '');
    final instagram = TextEditingController(text: data['instagram'] ?? '');
    final website = TextEditingController(text: data['website'] ?? '');

    bool hasAdler = data['hasAdler'] ?? false;

    final flyerUrl = data['flyerUrl'];
    final images = data['images'] is List ? List.from(data['images']) : [];

    DateTime startDate =
        (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();

    DateTime endDate =
        (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Einsendung prüfen"),

          content: SingleChildScrollView(
            child: Column(
              children: [

                if (flyerUrl != null && flyerUrl.toString().isNotEmpty)
                  Image.network(flyerUrl, height: 140),

                TextField(controller: name, decoration: const InputDecoration(labelText: "Festname")),
                TextField(controller: location, decoration: const InputDecoration(labelText: "Ort")),
                TextField(controller: address, decoration: const InputDecoration(labelText: "Adresse")),
                TextField(controller: description, decoration: const InputDecoration(labelText: "Beschreibung")),
                TextField(controller: highlights, decoration: const InputDecoration(labelText: "Highlights")),

                SwitchListTile(
                  title: const Text("Adlerschießen"),
                  value: hasAdler,
                  onChanged: (v) => setState(() => hasAdler = v),
                ),
              ],
            ),
          ),

          actions: [

            //--------------------------------------------------
            // ❌ ABLEHNEN
            //--------------------------------------------------
            TextButton(
              onPressed: () async {
                await doc.reference.update({"status": "rejected"});
                Navigator.pop(context);
              },
              child: const Text("Ablehnen"),
            ),

            //--------------------------------------------------
            // ✅ FREIGEBEN
            //--------------------------------------------------
            ElevatedButton(
              onPressed: () async {

                //--------------------------------------------------
                // ✅ LOCATION ID = ORT
                //--------------------------------------------------
                final locationId = location.text
                    .toLowerCase()
                    .trim()
                    .replaceAll(' ', '_')
                    .replaceAll('-', '_');

                //--------------------------------------------------
                // ✅ GEO FIX
                //--------------------------------------------------
                final coords =
                    await _getCoordinates(address.text, location.text);

                //--------------------------------------------------
                // ✅ LOCATION SPEICHERN
                //--------------------------------------------------
                await FirebaseFirestore.instance
                    .collection('locations')
                    .doc(locationId)
                    .set({
                  "name": location.text,
                  "address": address.text,
                  "latitude": coords["lat"],
                  "longitude": coords["lng"],
                  "hasAdler": hasAdler,
                  "instagram": _formatInstagram(instagram.text),
                  "website": _formatWebsite(website.text),
                }, SetOptions(merge: true));

                //--------------------------------------------------
                // ✅ FESTIVAL (ID = ORT 💥)
                //--------------------------------------------------
                await FirebaseFirestore.instance
                    .collection('festivals')
                    .doc(locationId)
                    .set({
                  "name": name.text,
                  "address": address.text,
                  "description": description.text,
                  "highlights": highlights.text,
                  "startDate": startDate,
                  "endDate": endDate,
                  "flyerUrl": flyerUrl ?? "",
                  "images": images,

                  "latitude": coords["lat"],
                  "longitude": coords["lng"],

                  "locationId": locationId,

                  "updatedAt": FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                //--------------------------------------------------
                await doc.reference.update({"status": "approved"});

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("✅ Fest gespeichert!")),
                );
              },
              child: const Text("Freigeben"),
            ),
          ],
        ),
      ),
    );
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    if (!AdminService.isAdmin) {
      return const Scaffold(
        body: Center(child: Text("Kein Zugriff")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Einsendungen")),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('submissions')
            .where('status', isEqualTo: 'pending')
            .snapshots(),

        builder: (context, snapshot) {

   if (snapshot.connectionState == ConnectionState.waiting) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

if (snapshot.hasError) {
  return const Center(
    child: Text("Fehler beim Laden.\nBitte Verbindung prüfen."),
  );
}

if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  return const Center(
    child: Text("Keine Daten verfügbar"),
  );
}

if (snapshot.hasError) {
  return const Center(
    child: Text("Fehler beim Laden.\nBitte Verbindung prüfen."),
  );
}

if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  return const Center(
    child: Text("Keine Daten verfügbar"),
  );
}
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Keine offenen Einsendungen"));
          }

          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text(data['name'] ?? ''),
                  subtitle: Text(data['location'] ?? ''),
                  onTap: () => _openModeration(context, doc),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
