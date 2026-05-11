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
  // ✅ VIEWER REGISTER
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
        "lastUpdate": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  //--------------------------------------------------
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

        tx.set(statsRef, {
          "current": current,
        }, SetOptions(merge: true));
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? Colors.green : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ),
      ),
    );
  }

  //--------------------------------------------------
  Widget _viewerStats() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('adler_stats')
          .doc(widget.locationId)
          .snapshots(),
      builder: (context, snapshot) {

        final data = snapshot.data?.data() as Map<String, dynamic>?;

        final current = data?['current'] ?? 0;
        final peak = data?['peak'] ?? 0;
        final total = data?['total'] ?? 0;

        return Column(
          children: [
            Text("👀 $current Zuschauer",
                style: const TextStyle(color: Colors.white)),
            Text("🔥 Peak: $peak",
                style: const TextStyle(color: Colors.orange)),
            Text("🎯 Gesamt: $total",
                style: const TextStyle(color: Colors.greenAccent)),
          ],
        );
      },
    );
  }

  //--------------------------------------------------
  // ✅ FIXED LIVE VIEW (WICHTIG!)
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

        return Column(
          children: [

            //--------------------------------------------------
            // HEADER
            //--------------------------------------------------
            Container(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("LIVE",
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
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
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),

            //--------------------------------------------------
            // 👀 VIEWER
            //--------------------------------------------------
            _viewerStats(),

            Text("🕒 ${_formatTime(now)}",
                style: const TextStyle(color: Colors.white)),

            //--------------------------------------------------
            // 👑 KING
            //--------------------------------------------------
            if (king != null)
              Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.all(10),
                color: Colors.amber,
                child: Text("👑 $king"),
              ),

            //--------------------------------------------------
            // 👥 PARTICIPANTS
            //--------------------------------------------------
            if (participants.isNotEmpty)
              Wrap(
                children: participants
                    .map((p) => Chip(label: Text(p)))
                    .toList(),
              ),

            //--------------------------------------------------
            // 💥 LISTE
            //--------------------------------------------------
            Expanded(
              child: !hasData
                  ? const Center(
                      child: Text("Keine Live Daten",
                          style: TextStyle(color: Colors.white)))
                  : ListView(
                      children: sorted.map((entry) {

                        final part = entry.key;
                        final r = entry.value;

                     

return ListTile(
  title: Text(
    part,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),

  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // 👤 NAME
      Text(
        r['name'] ?? "",
        style: const TextStyle(color: Colors.white),
      ),

      // 🕒 UHRZEIT
      if (r['time'] != null)
        Text(
          "🕒 ${_formatTime(DateTime.parse(r['time']))}",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
    ],
  ),

  trailing: Text(
    "${r['shots']}",
    style: const TextStyle(
      color: Colors.greenAccent,
      fontWeight: FontWeight.bold,
    ),
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
