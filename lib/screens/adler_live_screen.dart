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

  final Map<String, Map<String, dynamic>> _lastValidData = {};

  //--------------------------------------------------
  // ✅ AUTO RESET BEI 12H INAKTIVITÄT
  //--------------------------------------------------
  Future<void> _checkInactivity() async {
    try {
      final db = FirebaseFirestore.instance;

      for (final eventType in ["jung", "alt"]) {
        final doc = await db
            .collection('adler_events')
            .doc(widget.locationId)
            .collection('events')
            .doc(eventType)
            .get();

        if (!doc.exists) continue;

        final data = doc.data()!;
        final lastUpdate = data['lastUpdate'];
        if (lastUpdate == null) continue;

        final last = (lastUpdate as Timestamp).toDate();
        final diff = DateTime.now().difference(last);

        if (diff.inHours >= 12) {
          await db
              .collection('adler_events')
              .doc(widget.locationId)
              .collection('events')
              .doc(eventType)
              .set({
            "isActive": false,
            "shots": 0,
            "kingName": null,
            "results": {},
            "participants": [],
            "eventType": eventType,
            "lastUpdate": FieldValue.serverTimestamp(),
          }, SetOptions(merge: false));
        }
      }

      await db.collection('locations').doc(widget.locationId).set({
        "isLive": false,
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint("Inactivity Check Error: $e");
    }
  }

  //--------------------------------------------------
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

    _checkInactivity();
    _registerViewer();
  }

  //--------------------------------------------------
  @override
  void dispose() {
    _lastValidData.clear();
    _removeViewer();
    _pulseController.dispose();
    super.dispose();
  }

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

        tx.set(ref, {"joinedAt": FieldValue.serverTimestamp()});
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
        final snap = await tx.get(statsRef);

        int current = snap.exists
            ? (snap.data() as Map<String, dynamic>)['current'] ?? 0
            : 0;

        if (current > 0) current--;

        tx.delete(ref);
        tx.set(statsRef, {"current": current}, SetOptions(merge: true));
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
              _modeButton("Jungkönig", "jung"),
              _modeButton("Altkönig", "alt"),
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
          if (newData['isActive'] == true) {
            _lastValidData[eventType] = newData;
          } else {
            _lastValidData.remove(eventType);
          }
        }

        final data = _lastValidData[eventType] ?? {};
        final shots = data['shots'] ?? 0;
        final king = data['kingName'];
        final results = Map<String, dynamic>.from(data['results'] ?? {});

        final sorted = results.entries.toList()
          ..sort((a, b) =>
              (b.value['order'] ?? 0).compareTo(a.value['order'] ?? 0));

        return Column(
          children: [

            if (king != null)
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "👑 $king ist König mit $shots Schuss",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "Schüsse: $shots",
                style: const TextStyle(color: Colors.white),
              ),
            ),

            Expanded(
              child: ListView(
                children: sorted.map((e) {
                  final r = e.value;
                  final time = r['time'] != null
                      ? _formatTime(DateTime.parse(r['time']))
                      : "--:--";

                  return ListTile(
                    title: Text(e.key,
                        style: const TextStyle(color: Colors.white)),
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