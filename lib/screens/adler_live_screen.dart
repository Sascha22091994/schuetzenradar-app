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

  //--------------------------------------------------
  // ✅ VIEW MODE
  //--------------------------------------------------
  String viewMode = "jung"; // jung | alt | split

  String _formatTime(DateTime t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  //--------------------------------------------------
  Widget _buildSingleLive(String eventType) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('adler_events')
          .doc(widget.locationId)
          .collection('events')
          .doc(eventType)
          .snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
              child: Text("Keine Daten", style: TextStyle(color: Colors.white)));
        }

        final data =
            snapshot.data!.data() as Map<String, dynamic>;

        final shots = data['shots'] ?? 0;
        final king = data['kingName'];
        final results =
            Map<String, dynamic>.from(data['results'] ?? {});
        final participants =
            (data['participants'] as List?) ?? [];

        final sorted = results.entries.toList()
          ..sort((a, b) =>
              (b.value['order'] ?? 0)
                  .compareTo(a.value['order'] ?? 0));

        final now = DateTime.now();

        return Column(
          children: [

            //--------------------------------------------------
            // HEADER
            //--------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.green,
              child: Text(
                "${eventType == "jung" ? "JUNGKÖNIG" : "ALTKÖNIG"} • SCHÜSSE: $shots",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),

            //--------------------------------------------------
            Text(
              "Jetzt: ${_formatTime(now)}",
              style: const TextStyle(color: Colors.white70),
            ),

            //--------------------------------------------------
            if (king != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.amber,
                child: Text(
                  "👑 $king",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

            //--------------------------------------------------
            if (participants.isNotEmpty)
              Wrap(
                children: participants
                    .map((p) => Padding(
                          padding: const EdgeInsets.all(4),
                          child: Chip(
                            label: Text(p),
                          ),
                        ))
                    .toList(),
              ),

            //--------------------------------------------------
            Expanded(
              child: ListView(
                children: sorted.asMap().entries.map((entry) {

                  final index = entry.key;
                  final part = entry.value.key;
                  final r = entry.value.value;

                  final isLatest = index == 0;

                  return Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.all(12),
                    color: isLatest
                        ? Colors.orange
                        : Colors.grey.shade900,
                    child: Row(
                      children: [

                        Expanded(child: Text(part, style: const TextStyle(color: Colors.white))),

                        Expanded(child: Text(r['name'], style: const TextStyle(color: Colors.white))),

                        Text("${r['shots']}",
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          ],
        );
      },
    );
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: Text("LIVE – ${widget.locationName}"),
        backgroundColor: Colors.green,
      ),

      body: Column(
        children: [

          //--------------------------------------------------
          // ✅ VIEW SWITCH
          //--------------------------------------------------
          Row(
            children: [

              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => viewMode = "jung"),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: viewMode == "jung"
                        ? Colors.green
                        : Colors.grey,
                    child: const Center(child: Text("Jung")),
                  ),
                ),
              ),

              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => viewMode = "alt"),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: viewMode == "alt"
                        ? Colors.green
                        : Colors.grey,
                    child: const Center(child: Text("Alt")),
                  ),
                ),
              ),

              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => viewMode = "split"),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: viewMode == "split"
                        ? Colors.green
                        : Colors.grey,
                    child: const Center(child: Text("Split")),
                  ),
                ),
              ),
            ],
          ),

          //--------------------------------------------------
          // ✅ CONTENT
          //--------------------------------------------------
          Expanded(
            child: viewMode == "split"
                ? Row(
                    children: [
                      Expanded(child: _buildSingleLive("jung")),
                      Expanded(child: _buildSingleLive("alt")),
                    ],
                  )
                : _buildSingleLive(viewMode),
          ),
        ],
      ),
    );
  }
}