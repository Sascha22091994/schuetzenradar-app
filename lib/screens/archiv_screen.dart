import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArchivScreen extends StatelessWidget {
  final String? locationId;

  const ArchivScreen({super.key, this.locationId});

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        
title: Text(
  locationId == null ? "Archiv 🗂️" : "Archiv dieser Location",
),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder<QuerySnapshot>(

  stream: (() {
  Query query = FirebaseFirestore.instance
      .collection('adler_archive');

  if (locationId != null) {
    query = query.where('locationId', isEqualTo: locationId);
  }

  query = query.orderBy('createdAt', descending: true);

  return query.snapshots();
})(),


        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
  return const Center(child: CircularProgressIndicator());
}

if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  return const Center(
    child: Text("Noch keine archivierten Spiele vorhanden 🗂️"),
  );
}

          

          final docs = snapshot.data!.docs;

          //--------------------------------------------------
          // ✅ GROUP BY LOCATION
          //--------------------------------------------------
          final Map<String, List<Map<String, dynamic>>> grouped = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            final location = data['locationName'] ?? "Unbekannt";

            if (!grouped.containsKey(location)) {
              grouped[location] = [];
            }

            grouped[location]!.add(data);
          }

          //--------------------------------------------------
       return ListView(
  padding: const EdgeInsets.all(12),
  children: grouped.entries.map((entry) {

    final location = entry.key;
    final events = entry.value;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: ExpansionTile(
        title: Text(
          location,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        children: events.map((e) {

          final king = e['kingName'] ?? "-";
          final shots = e['shots'] ?? 0;
          final type = e['eventType'] ?? "-";

          final participants =
              List<String>.from(e['participants'] ?? []);
          final results =
              Map<String, dynamic>.from(e['results'] ?? {});

          final sorted = results.entries.toList()
            ..sort((a, b) =>
                (a.value['order'] ?? 0)
                    .compareTo(b.value['order'] ?? 0));

          DateTime? created;
          if (e['createdAt'] != null) {
            created = DateTime.tryParse(e['createdAt']);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),

              child: ExpansionTile(
                leading: const Icon(Icons.emoji_events),

                title: Text(
                  "👑 $king",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: Text(
                  "$type • $shots Schuss\n"
                  "${created != null ? "${created.day}.${created.month}.${created.year}" : ""}",
                ),

                children: [

                  //----------------------------------
                  // Teilnehmer
                  //----------------------------------
                  if (participants.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        spacing: 6,
                        children: participants
                            .map((p) => Chip(label: Text(p)))
                            .toList(),
                      ),
                    ),

                  //----------------------------------
                  // Trefferliste
                  //----------------------------------
                  ...sorted.map((entry) {

                    final r = entry.value;

                    String time = "--:--";
                    if (r['time'] != null) {
                      final parsed = DateTime.tryParse(r['time']);
                      if (parsed != null) {
                        time =
                            "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
                      }
                    }

                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),

                      title: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Text("${r['name']} • $time"),

                      trailing: Text(
                        "${r['shots']}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );

                  }).toList(),

                  //----------------------------------
                  // König Highlight
                  //----------------------------------
                  if (king != "-")
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "👑 $king ist König ($shots Schuss)",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );

        }).toList(),
      ),
    );

  }).toList(),
);

    },
      ),
    );
  }
}
