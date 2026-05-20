import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

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

  Timer? _heartbeatTimer;

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (viewerId == null) return;

      FirebaseFirestore.instance
          .collection('adler_viewers')
          .doc(widget.locationId)
          .collection('users')
          .doc(viewerId)
          .update({
        "lastSeen": FieldValue.serverTimestamp(),
      }).catchError((e) {
        _heartbeatTimer?.cancel();
      });
    });
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

    _registerViewer();
  }

  //--------------------------------------------------
  @override
  void dispose() {
    _heartbeatTimer?.cancel();
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

        tx.set(ref, {
          "joinedAt": FieldValue.serverTimestamp(),
          "lastSeen": FieldValue.serverTimestamp(),
        });

        tx.set(statsRef, {
          "current": current,
          "peak": peak,
          "total": total,
        }, SetOptions(merge: true));
      });

      _startHeartbeat();

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

        tx.set(
          statsRef,
          {"current": current},
          SetOptions(merge: true),
        );
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

          //--------------------------------------------------
          // 👀 VIEWER COUNT
          //--------------------------------------------------
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('adler_viewers')
                .doc(widget.locationId)
                .collection('users')
                .snapshots(),

            builder: (context, snapshot) {

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Fehler: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final now = DateTime.now();

              final activeViewers = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final lastSeen = data['lastSeen'];

                if (lastSeen == null) return false;

                final last = (lastSeen as Timestamp).toDate();

                return now.difference(last).inMinutes < 10;

              }).length;

              return Container(
                padding: const EdgeInsets.all(10),
                child: Text(
                  "👀 $activeViewers Zuschauer",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),

          //--------------------------------------------------
          // 🔘 BUTTONS
          //--------------------------------------------------
          Row(
            children: [
              _modeButton("Jungkönig", "jung"),
              _modeButton("Altkönig", "alt"),
              _modeButton("Beide", "split"),
            ],
          ),

          //--------------------------------------------------
          // 📺 LIVE CONTENT
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

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Fehler: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

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

        Map<String, dynamic> results = {};

        try {
          if (data['results'] is Map) {
            results = Map<String, dynamic>.from(data['results']);
          }
        } catch (e) {
          debugPrint("RESULTS ERROR: $e");
        }

        final sorted = results.entries.toList()
          ..sort((a, b) {
            final aOrder = (a.value['order'] ?? 0) as num;
            final bOrder = (b.value['order'] ?? 0) as num;

            return bOrder.compareTo(aOrder);
          });

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

                  String time = "--:--";

                  try {
                    final rawTime = r['time'];

                    if (rawTime is String) {
                      time = _formatTime(DateTime.parse(rawTime));
                    } else if (rawTime is Timestamp) {
                      time = _formatTime(rawTime.toDate());
                    }
                  } catch (e) {
                    debugPrint("TIME PARSE ERROR: $e");
                  }

                  return ListTile(
                    title: Text(
                      e.key,
                      style: const TextStyle(color: Colors.white),
                    ),

                    subtitle: Text(
                      "${(r['name'] ?? "-").toString()} • $time",
                      style: const TextStyle(color: Colors.white70),
                    ),

                    trailing: Text(
                      "${r['shots']}",
                      style: const TextStyle(
                        color: Colors.greenAccent,
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
}