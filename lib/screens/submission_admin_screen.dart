import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';

String formatInstagram(String input) {
  if (input.isEmpty) return "";
  if (input.startsWith("http")) return input;
  return "https://instagram.com/$input";
}

String formatWebsite(String input) {
  if (input.isEmpty) return "";
  if (input.startsWith("http")) return input;
  return "https://$input";
}

class SubmissionAdminScreen extends StatelessWidget {
  const SubmissionAdminScreen({super.key});

  //--------------------------------------------------
  void _openModeration(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final type = data['type'] ?? 'festival';

    final name = TextEditingController(text: data['name'] ?? data['title'] ?? '');
    final location = TextEditingController(text: data['location'] ?? '');
    final address = TextEditingController(text: data['address'] ?? '');
    final description = TextEditingController(text: data['description'] ?? data['content'] ?? '');
    final highlights = TextEditingController(text: data['highlights'] ?? '');
    final instagram = TextEditingController(text: data['instagram'] ?? '');
    final website = TextEditingController(text: data['website'] ?? '');

    final flyerUrl = data['flyerUrl'];
    
final images = data['images'] is List
    ? List.from(data['images'])
    : [];


    bool hasAdler = data['hasAdler'] ?? false;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                //--------------------------------------------------
                // ✅ BILDER ANZEIGEN (NEU)
                //--------------------------------------------------
                if (flyerUrl != null && flyerUrl.toString().isNotEmpty) ...[
                  const Text("📄 Flyer", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Image.network(
                    flyerUrl,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  ),
                  const SizedBox(height: 10),
                ],

                if (images.isNotEmpty) ...[
                  const Text("📸 Zusatzbilder", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: images.map((url) {
                      return Image.network(
                        url,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),
                ],

                //--------------------------------------------------
                // ✅ FORM
                //--------------------------------------------------
                if (type == "news") ...[
                  TextField(controller: name, decoration: const InputDecoration(labelText: "Titel")),
                  TextField(controller: location, decoration: const InputDecoration(labelText: "Ort")),
                  TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: "Inhalt")),
                ] else ...[
                  TextField(controller: name, decoration: const InputDecoration(labelText: "Festname")),
                  TextField(controller: location, decoration: const InputDecoration(labelText: "Ort")),
                  TextField(controller: address, decoration: const InputDecoration(labelText: "Adresse")),
                  TextField(controller: description, decoration: const InputDecoration(labelText: "Beschreibung")),
                  TextField(controller: highlights, decoration: const InputDecoration(labelText: "Highlights")),
                  TextField(controller: instagram, decoration: const InputDecoration(labelText: "Instagram")),
                  TextField(controller: website, decoration: const InputDecoration(labelText: "Website")),

                  SwitchListTile(
                    title: const Text("Adlerschießen vorhanden"),
                    value: hasAdler,
                    onChanged: (v) => setState(() => hasAdler = v),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => startDate = picked);
                    },
                    child: Text("Start: ${startDate.day}.${startDate.month}.${startDate.year}"),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => endDate = picked);
                    },
                    child: Text("Ende: ${endDate.day}.${endDate.month}.${endDate.year}"),
                  ),
                ],
              ],
            ),
          ),

          //--------------------------------------------------
          // ✅ ACTIONS
          //--------------------------------------------------
          actions: [

            TextButton(
              onPressed: () async {
                await doc.reference.update({"status": "rejected"});
                Navigator.pop(context);
              },
              child: const Text("Ablehnen"),
            ),

            ElevatedButton(
              onPressed: () async {

                if (type == "news") {

                  await FirebaseFirestore.instance.collection('news').add({
                    "title": name.text,
                    "text": description.text,
                    "location": location.text,
                    "date": FieldValue.serverTimestamp(),
                    "isImportant": false,
                  });

                } else {

                  final locationId =
                      location.text.toLowerCase().trim().replaceAll(' ', '_');

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

                    // ✅ NEU
                    "flyerUrl": flyerUrl,
                    "images": images,
                  });

                  await FirebaseFirestore.instance
                      .collection('locations')
                      .doc(locationId)
                      .set({
                    "name": location.text,
                    "hasAdler": hasAdler,
                    "instagram": formatInstagram(instagram.text),
                    "website": formatWebsite(website.text),
                  }, SetOptions(merge: true));
                }

                await doc.reference.update({"status": "approved"});

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Eintrag übernommen")),
                );
              },
              child: const Text("Übernehmen"),
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

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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

                  //--------------------------------------------------
                  // ✅ PREVIEW IMAGE
                  //--------------------------------------------------
                  leading: (data['flyerUrl'] ?? '').toString().isNotEmpty
                      ? Image.network(
                          data['flyerUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        )
                      : const Icon(Icons.image),

                  title: Text(
                    data['type'] == 'news'
                        ? data['title'] ?? ''
                        : data['name'] ?? '',
                  ),

                  subtitle: Text(
                    data['type'] == 'news'
                        ? data['location'] ?? ''
                        : "${data['location'] ?? ''} • ${data['address'] ?? ''}",
                  ),

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