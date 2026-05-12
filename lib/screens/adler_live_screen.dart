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
  // ✅ CACHE
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
    _lastValidData.clear();

    // ❗ async safe fire & forget
    _removeViewer();

    _pulseController.dispose();
    super.dispose();
  }

  //--------------------------------------------------
  // ✅ REGISTER VIEWER (FIXED)
  //--------------------------------------------------
  Future<void> _registerViewer() async {
    try {
      final db = FirebaseFirestore.instance;

      final jungDoc = await db
          .collection('adler_events')
          .doc(widget.locationId)
          .collection('events')
          .doc('jung')
          .get();

      final altDoc = await db
          .collection('adler_events')
          .doc(widget.locationId)
          .collection('events')
          .doc('alt')
          .get();

      final isActive =
          (jungDoc.data()?['isActive'] == true) ||
          (altDoc.data()?['isActive'] == true);

      if (!isActive) return;

      final ref = db
          .collection('adler_viewers')
          .doc(widget.locationId)
          .collection('users')
          .doc();

      viewerId = ref.id;

      final statsRef =
          db.collection('adler_stats').doc(widget.locationId);

      await db.runTransaction((tx) async {

        // ✅ FIRST READ
        final snap = await tx.get(statsRef);

        int current = 0;
        int peak = 0;
        int total = 0;

        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          current = data['current'] ?? 0;
          peak = data['peak'] ?? 0;
          total = data['total'] ?? 0;
        }

        current++;
        total++;
        if (current > peak) peak = current;

        // ✅ THEN WRITE
        tx.set(ref, {
          "joinedAt": FieldValue.serverTimestamp(),
        });

        tx.set(statsRef, {
          "current": current,
          "peak": peak,
          "total": total,
        }, SetOptions(merge: true));
      });

    } catch (e) {
      debugPrint("RegisterViewer Error: $e");
    }
  }

  //--------------------------------------------------
  // ✅ REMOVE VIEWER (FIXED)
  //--------------------------------------------------
  Future<void> _removeViewer() async {
    if (viewerId == null) return;

    try {
      final db = FirebaseFirestore.instance;

      final ref = db
          .collection('adler_viewers')
          .doc(widget.locationId)
          .collection('users')
          .doc(viewerId);

      final statsRef =
          db.collection('adler_stats').doc(widget.locationId);

      await db.runTransaction((tx) async {

        // ✅ FIRST READ
        final snap = await tx.get(statsRef);

        int current = 0;

        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;
          current = data['current'] ?? 0;
        }

        if (current > 0) current--;

        // ✅ THEN WRITE
        tx.delete(ref);

        tx.set(statsRef, {
          "current": current,
        }, SetOptions(merge: true));
      });

    } catch (e) {
      debugPrint("RemoveViewer Error: $e");
    }
  }

  //--------------------------------------------------
  String _formatTime(DateTime t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
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

          final isActive = newData['isActive'] == true;

          if (isActive) {
            _lastValidData[eventType] = newData;
          } else {
            _lastValidData.remove(eventType);
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text("Schüsse: $shots",
                      style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
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

                        return ListTile(
                          title: Text(part, style: const TextStyle(color: Colors.white)),
                          subtitle: Text("${r['name']} • $time",
                              style: const TextStyle(color: Colors.white70)),
                          trailing: Text("${r['shots']}",
                              style: const TextStyle(color: Colors.greenAccent)),
                        );
                      }).toList(),
                    ),
            )
          ],
        );
      },
    );
  }
}