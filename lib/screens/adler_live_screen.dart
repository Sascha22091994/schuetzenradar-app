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

class _AdlerLiveScreenState extends State<AdlerLiveScreen>
    with SingleTickerProviderStateMixin {

  String viewMode = "jung";

  late AnimationController _pulseController;
  late Animation<double> _pulse;

  String? viewerId;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulse = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _registerViewer();
  }

  @override
  void dispose() {
    _removeViewer();
    _pulseController.dispose();
    super.dispose();
  }

  //--------------------------------------------------
  // VIEWER SYSTEM
  //--------------------------------------------------
  Future<void> _registerViewer() async {

    final ref = FirebaseFirestore.instance
        .collection('adler_viewers')
        .doc(widget.locationId)
        .collection('users')
        .doc();

    viewerId = ref.id;

    final statsRef = FirebaseFirestore.instance
        .collection('adler_stats')
        .doc(widget.locationId);

    await FirebaseFirestore.instance.runTransaction((tx) async {

      tx.set(ref, {
        "joinedAt": FieldValue.serverTimestamp(),
      });

      final statsSnap = await tx.get(statsRef);

      int current = 0;
      int peak = 0;
      int total = 0;

      if (statsSnap.exists) {
        final data = statsSnap.data()!;
        current = data['current'] ?? 0;
        peak = data['peak'] ?? 0;
        total = data['total'] ?? 0;
      }

      current++;
      total++;

      if (current > peak) peak = current;

      tx.set(statsRef, {
        "current": current,
        "peak": peak,
        "total": total,
      }, SetOptions(merge: true));
    });
  }

  Future<void> _removeViewer() async {

    if (viewerId == null) return;

    final ref = FirebaseFirestore.instance
        .collection('adler_viewers')
        .doc(widget.locationId)
        .collection('users')
        .doc(viewerId);

    final statsRef = FirebaseFirestore.instance
        .collection('adler_stats')
        .doc(widget.locationId);

    await FirebaseFirestore.instance.runTransaction((tx) async {

      tx.delete(ref);

      final statsSnap = await tx.get(statsRef);

      if (statsSnap.exists) {
        int current = statsSnap.data()!['current'] ?? 0;
        if (current > 0) current--;

        tx.set(statsRef, {"current": current}, SetOptions(merge: true));
      }
    });
  }

  //--------------------------------------------------
  String _formatTime(DateTime t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  //--------------------------------------------------
  Widget _modeButton(String label, String value) {
    final active = viewMode == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => viewMode = value),
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: active ? Colors.green : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: active ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
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

        final hasData = snapshot.hasData && snapshot.data!.exists;

        final data = hasData
            ? snapshot.data!.data() as Map<String, dynamic>
            : {};

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

        return Stack(
          children: [

            //--------------------------------------------------
            // HAUPTINHALT
            //--------------------------------------------------
            Column(
              children: [

                //--------------------------------------------------
                // HEADER
                //--------------------------------------------------
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "LIVE",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ScaleTransition(
                            scale: _pulse,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Schüsse: $shots",
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        _formatTime(now),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                //--------------------------------------------------
                // TEILNEHMER
                //--------------------------------------------------
                if (participants.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 8,
                      children: participants
                          .map((p) => Chip(
                                label: Text(
                                  p,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                //--------------------------------------------------
                // KÖNIG
                //--------------------------------------------------
                if (king != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(14),
                    color: Colors.amber,
                    child: Text(
                      "👑 $king",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                //--------------------------------------------------
                // LISTE
                //--------------------------------------------------
                Expanded(
                  child: !hasData
                      ? const Center(
                          child: Text(
                            "Keine Live Daten",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        )
                      : ListView(
                          children: sorted.map((entry) {

                            final part = entry.key;
                            final r = entry.value;

                            final time = r['time'] != null
                                ? _formatTime(DateTime.parse(r['time']))
                                : "--:--";

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade900,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [

                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      part,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      r['name'] ?? "",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      time,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),

                                  Text(
                                    "${r['shots']}",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                )
              ],
            ),

            //--------------------------------------------------
            // KLEINE STATS UNTEN RECHTS
            //--------------------------------------------------
            Positioned(
              right: 10,
              bottom: 10,
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('adler_stats')
                    .doc(widget.locationId)
                    .snapshots(),
                builder: (context, snapshot) {

                  final data =
                      snapshot.data?.data() as Map<String, dynamic>?;

                  final current = data?['current'] ?? 0;
                  final peak = data?['peak'] ?? 0;
                  final total = data?['total'] ?? 0;

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha:0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("👀 $current",
                            style: const TextStyle(fontSize: 12, color: Colors.white70)),
                        Text("🔥 $peak",
                            style: const TextStyle(fontSize: 12, color: Colors.orange)),
                        Text("🎯 $total",
                            style: const TextStyle(fontSize: 12, color: Colors.greenAccent)),
                      ],
                    ),
                  );
                },
              ),
            ),
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
          // BUTTONS
          //--------------------------------------------------
          Row(
            children: [
              _modeButton("Jungschütze", "jung"),
              _modeButton("Altschütze", "alt"),
              _modeButton("Beide", "split"),
            ],
          ),

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
