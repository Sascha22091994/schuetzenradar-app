import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdlerLiveScreen extends StatefulWidget {
  final String locationId;
  final String locationName;

  const AdlerLiveScreen({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  @override
  State<AdlerLiveScreen> createState() => _AdlerLiveScreenState();
}

class _AdlerLiveScreenState extends State<AdlerLiveScreen> {

  String _formatTime(DateTime t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: Text("LIVE – ${widget.locationName}"),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adler_events')
            .doc(widget.locationId)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final shots = data['shots'] ?? 0;
          final king = data['kingName'];

          final results =
              Map<String, dynamic>.from(data['results'] ?? {});

          final participants =
              (data['participants'] as List?) ?? [];

          //--------------------------------------------------
          // ✅ STABILE SORTIERUNG
          //--------------------------------------------------
          final sorted = results.entries.toList()
            ..sort((a, b) =>
                (b.value['order'] ?? 0)
                    .compareTo(a.value['order'] ?? 0));

          //--------------------------------------------------
          final now = DateTime.now();

          return Column(
            children: [

              //--------------------------------------------------
              // HEADER
              //--------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.green,
                child: Text(
                  "SCHÜSSE: $shots",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),

              //--------------------------------------------------
              // UHRZEIT
              //--------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  "Jetzt: ${_formatTime(now)}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),

              //--------------------------------------------------
              // 👑 KÖNIG WIEDER SICHTBAR
              //--------------------------------------------------
              if (king != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.amber,
                  child: Text(
                    "👑 KÖNIG: $king",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),

              //--------------------------------------------------
              // TEILNEHMER (saubere UI)
              //--------------------------------------------------
              if (participants.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: participants
                        .map((p) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                p,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),

              //--------------------------------------------------
              // TREFFER LISTE
              //--------------------------------------------------
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: sorted.asMap().entries.map((entry) {

                    final index = entry.key;
                    final part = entry.value.key;
                    final r = entry.value.value;

                    final isLatest = index == 0;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(isLatest ? 20 : 16),

                      decoration: BoxDecoration(
                        color: isLatest
                            ? Colors.orange.shade700
                            : Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLatest
                              ? Colors.yellow
                              : Colors.green,
                          width: isLatest ? 3 : 2,
                        ),

                        //--------------------------------------------------
                        // Glow
                        //--------------------------------------------------
                        boxShadow: isLatest
                            ? [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.7),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),

                      child: Row(
                        children: [

                          Expanded(
                            flex: 2,
                            child: Text(
                              part,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isLatest ? 22 : 18,
                                fontWeight:
                                    isLatest ? FontWeight.bold : null,
                              ),
                            ),
                          ),

                          Expanded(
                            flex: 2,
                            child: Text(
                              r['name'],
                              style: TextStyle(
                                fontSize: isLatest ? 22 : 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [

                                Text(
                                  "${r['shots']}",
                                  style: TextStyle(
                                    fontSize: isLatest ? 22 : 18,
                                    color: Colors.green,
                                  ),
                                ),

                                if (r['time'] != null)
                                  Text(
                                    _formatTime(DateTime.parse(r['time'])),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}