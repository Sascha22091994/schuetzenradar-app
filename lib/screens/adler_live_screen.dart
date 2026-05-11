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

  //--------------------------------------------------
  // CACHE
  //--------------------------------------------------
  final Map<String, Map<String, dynamic>> _lastValidData = {};

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

    final statsRef =
        FirebaseFirestore.instance.collection('adler_stats').doc(widget.locationId);

    await FirebaseFirestore.instance.runTransaction((tx) async {

      tx.set(ref, {
        "joinedAt": FieldValue.serverTimestamp(),
      });

      final snap = await tx.get(statsRef);

      int current = (snap.data()?['current'] ?? 0) + 1;
      int peak = snap.data()?['peak'] ?? 0;
      int total = (snap.data()?['total'] ?? 0) + 1;

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

    final statsRef =
        FirebaseFirestore.instance.collection('adler_stats').doc(widget.locationId);

    await FirebaseFirestore.instance.runTransaction((tx) async {

      tx.delete(ref);

      final snap = await tx.get(statsRef);

      int current = snap.data()?['current'] ?? 0;
      if (current > 0) current--;

      tx.set(statsRef, {"current": current}, SetOptions(merge: true));
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? Colors.green : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
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

        if (snapshot.hasData && snapshot.data!.exists) {
          final newData = snapshot.data!.data() as Map<String, dynamic>;
          if (newData.isNotEmpty) {
            _lastValidData[eventType] = newData;
          }
        }

        final data = _lastValidData[eventType] ?? {};

        final shots = data['shots'] ?? 0;
        final king = data['kingName'];
        final participants = (data['participants'] as List?) ?? [];
        final results = Map<String, dynamic>.from(data['results'] ?? {});

        final sorted = results.entries.toList()
          ..sort((a, b) =>
              (b.value['order'] ?? 0).compareTo(a.value['order'] ?? 0));

        return Column(
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
                      const Text("LIVE",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      ScaleTransition(
                        scale: _pulse,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text("Schüsse: $shots",
                      style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            //--------------------------------------------------
            // TEILNEHMER
            //--------------------------------------------------
            if (participants.isNotEmpty)
              Wrap(
                spacing: 6,
                children: participants
                    .map((p) => Chip(label: Text(p)))
                    .toList(),
              ),

            //--------------------------------------------------
            // KÖNIG
            //--------------------------------------------------
            if (king != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(12),
                color: Colors.amber,
                child: Text("👑 $king",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
              ),

            //--------------------------------------------------
            // LISTE (MOBILE FIX)
            //--------------------------------------------------
            Expanded(
              child: data.isEmpty
                  ? const Center(
                      child: Text(
                        "Warte auf Live Daten...",
                        style: TextStyle(color: Colors.white),
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
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),

                          //--------------------------------------------------
                          // ✅ BONUS HIGHLIGHT
                          //--------------------------------------------------
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.greenAccent.withOpacity(0.3),
                            ),
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(part,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Text("${r['shots']}",
                                      style: const TextStyle(
                                          color: Colors.greenAccent)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text("${r['name']} • $time",
                                  style:
                                      const TextStyle(color: Colors.white70)),
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
          Row(
            children: [
              _modeButton("Jung", "jung"),
              _modeButton("Alt", "alt"),
              _modeButton("Split", "split"),
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