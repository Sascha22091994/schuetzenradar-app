import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArchivScreen extends StatelessWidget {
  final String? locationId;

  const ArchivScreen({super.key, this.locationId});

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          locationId == null
              ? "Archiv 🗂️"
              : "Archiv dieser Location",
        ),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: (() {
          Query query =
              FirebaseFirestore.instance.collection('adler_archive');

          if (locationId != null) {
            query =
                query.where('locationId', isEqualTo: locationId);
          }

          query = query.orderBy('createdAt', descending: true);

          return query.snapshots();
        })(),

        builder: (context, snapshot) {
          //--------------------------------------------------
          // LOADING
          //--------------------------------------------------
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          //--------------------------------------------------
          // EMPTY
          //--------------------------------------------------
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Noch keine archivierten Spiele vorhanden 🗂️",
                style: TextStyle(
                  color: isDark
                      ? Colors.white70
                      : Colors.black87,
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          //--------------------------------------------------
          // GROUP BY LOCATION
          //--------------------------------------------------
          final Map<String, List<Map<String, dynamic>>> grouped = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final location =
                data['locationName'] ?? "Unbekannt";

            grouped.putIfAbsent(location, () => []);
            grouped[location]!.add(data);
          }

          //--------------------------------------------------
          // UI
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
                        Map<String, dynamic>.from(
                            e['results'] ?? {});

                    final sorted = results.entries.toList()
                      ..sort((a, b) =>
                          (a.value['order'] ?? 0)
                              .compareTo(
                                  b.value['order'] ?? 0));

                    DateTime? created;
                    if (e['createdAt'] != null) {
                      created =
                          DateTime.tryParse(e['createdAt']);
                    }

                    //--------------------------------------------------
                    // EVENT CARD (FLACH & CLEAN ✅)
                    //--------------------------------------------------
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            //----------------------------------
                            // HEADER
                            //----------------------------------
                            Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 8),

                                Expanded(
                                  child: Text(
                                    king != "-"
                                        ? king
                                        : "Kein König",
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold),
                                  ),
                                ),

                                Text(
                                  "$shots Schuss",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "$type • ${created != null ? "${created.day.toString().padLeft(2, '0')}.${created.month.toString().padLeft(2, '0')}.${created.year}" : ""}",
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey),
                            ),

                            //----------------------------------
                            // KÖNIG
                            //----------------------------------
                            if (king != "-")
                              Container(
                                margin:
                                    const EdgeInsets.only(
                                        top: 8),
                                padding:
                                    const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber
                                      .withValues(
                                          alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(
                                          10),
                                ),
                                child: Text(
                                  "👑 $king ist König ($shots Schuss)",
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold),
                                ),
                              ),

                            //----------------------------------
                            // PARTICIPANTS
                            //----------------------------------
                            if (participants.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(
                                        top: 8),
                                child: Wrap(
                                  spacing: 6,
                                  children: participants
                                      .map((p) => Chip(
                                            label:
                                                Text(p),
                                          ))
                                      .toList(),
                                ),
                              ),

                            //----------------------------------
                            // RESULTS
                            //----------------------------------
                            const SizedBox(height: 6),

                            ...sorted.map((entry) {
                              final r = entry.value;

                              String time = "--:--";
                              if (r['time'] != null) {
                                final parsed =
                                    DateTime.tryParse(
                                        r['time']);
                                if (parsed != null) {
                                  time =
                                      "${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
                                }
                              }

                              return ListTile(
                                dense: true,
                                contentPadding:
                                    EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                title: Text(entry.key),
                                subtitle: Text(
                                    "${r['name']} • $time"),
                                trailing: Text(
                                  "${r['shots']}",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
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