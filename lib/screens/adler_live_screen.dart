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
String _formatTime(DateTime t) {
  return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
}

  //--------------------------------------------------
  // 🧠 STATE
  //--------------------------------------------------
  String viewMode = "jung";

  late AnimationController _pulseController;
  late Animation<double> _pulse;

  String? viewerId;
  Timer? _heartbeatTimer;

  final Map<String, Map<String, dynamic>> _lastValidData = {};
bool _chatCleared = false; 
StreamSubscription? _eventSub;

  

  //--------------------------------------------------
  // 💬 COMMENTS
  //--------------------------------------------------
  final TextEditingController _commentController = TextEditingController();

  String _username =
      "Gast_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";

  DateTime? _lastCommentTime;

  //--------------------------------------------------
  // ✅ INIT
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
      _watchEventEnd(); // ✅ HIER
      
  }

  //--------------------------------------------------
  // ❌ DISPOSE
  //--------------------------------------------------
  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _pulseController.dispose();
    _commentController.dispose();
    _eventSub?.cancel();


    super.dispose();
  }

  //--------------------------------------------------
  // 🔥 LIVE CHECK
  //--------------------------------------------------
  Future<bool> _isLiveActive() async {
    final db = FirebaseFirestore.instance;

    final jung = await db
        .collection('adler_events')
        .doc(widget.locationId)
        .collection('events')
        .doc('jung')
        .get();

    final alt = await db
        .collection('adler_events')
        .doc(widget.locationId)
        .collection('events')
        .doc('alt')
        .get();

    return (jung.data()?['isActive'] == true) ||
        (alt.data()?['isActive'] == true);
  }


//CLEAR CHAT

Future<void> _clearChat(String eventType) async {
  final isLive = await _isLiveActive();

  if (isLive) return; // ✅ nur löschen wenn wirklich vorbei

  final snapshot = await FirebaseFirestore.instance
      .collection('adler_comments')
      .doc(widget.locationId)
      .collection('messages')
      .get();

  for (final doc in snapshot.docs) {
    await doc.reference.delete();
  }
}

void _watchEventEnd() {
  _eventSub = FirebaseFirestore.instance
      .collection('adler_events')
      .doc(widget.locationId)
      .collection('events')
      .snapshots()
      .listen((snapshot) async {

    bool anyActive = false;

    for (final doc in snapshot.docs) {
      if (doc.data()['isActive'] == true) {
        anyActive = true;
        break;
      }
    }

    if (!anyActive && !_chatCleared) {
      _chatCleared = true;

      await _clearChat("all");
    }

    if (anyActive) {
      _chatCleared = false;
    }
  });
}



  //--------------------------------------------------
  // 👀 HEARTBEAT
  //--------------------------------------------------
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
      });
    });
  }

  //--------------------------------------------------
  // 👀 REGISTER VIEWER
  //--------------------------------------------------
  Future<void> _registerViewer() async {
    final db = FirebaseFirestore.instance;

    final ref = db
        .collection('adler_viewers')
        .doc(widget.locationId)
        .collection('users')
        .doc();

    viewerId = ref.id;

    await ref.set({
      "joinedAt": FieldValue.serverTimestamp(),
      "lastSeen": FieldValue.serverTimestamp(),
    });

    _startHeartbeat();
  }

  //--------------------------------------------------
  // 💬 SEND COMMENT
  //--------------------------------------------------
  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (_lastCommentTime != null &&
        DateTime.now().difference(_lastCommentTime!).inSeconds < 3) {
      return;
    }

    final isLive = await _isLiveActive();
    if (!isLive) return;

    _lastCommentTime = DateTime.now();


await FirebaseFirestore.instance
    .collection('adler_comments')
    .doc(widget.locationId)
    .collection('messages')
    .add({
  "text": text,
  "user": _username,
  "userId": viewerId, // ✅ WICHTIG!
  "createdAt": FieldValue.serverTimestamp(),
});


    _commentController.clear();
  }

  //--------------------------------------------------
  // 👀 BUILD
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
              _modeButton("Jungkönig", "jung"),
              _modeButton("Altkönig", "alt"),
              _modeButton("Beide", "split"),
            ],
          ),

     //--------------------------------------------------
          // LIVECHAT INFO
          //--------------------------------------------------

Container(
  padding: const EdgeInsets.all(8),
  color: const Color.fromARGB(255, 194, 96, 16),
  width: double.infinity,
  child: const Text(
    "💬 Live Chat aktiv – schreib mit!",
    textAlign: TextAlign.center,
    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  ),
),

          //--------------------------------------------------
          // LIVE + CHAT
          //--------------------------------------------------
          
          
          Expanded(
            child: Column(
              children: [

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

                _buildComments(),
                _buildCommentInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  // MODE BUTTON
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
          child: Center(child: Text(label)),
        ),
      ),
    );
  }

  //--------------------------------------------------
  // COMMENTS LIST
  //--------------------------------------------------
Widget _buildComments() {
final isDark = Theme.of(context).brightness == Brightness.dark;

return Container(
  height: 110,
  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  padding: const EdgeInsets.symmetric(vertical: 6),
  decoration: BoxDecoration(
    color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
    ),
  ),

    child: StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('adler_comments')
          .doc(widget.locationId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;

        return ListView(
          reverse: true,
          children: docs.map((doc) {

            final data = doc.data();
            final isMine = data['userId'] == viewerId; // ✅ CHECK

            return ListTile(
              title: Text(
                data['text'] ?? '',
                style: TextStyle(
  color: isDark ? Colors.white : Colors.black87,
),

              ),
              subtitle: Text(
                data['user'] ?? '',
                style: TextStyle(
  color: isDark ? Colors.grey : Colors.grey.shade700,
),
              ),

              //----------------------------------
              // 🗑️ DELETE BUTTON (NUR DU)
              //----------------------------------
              trailing: isMine
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await doc.reference.delete();
                      },
                    )
                  : null,
            );

          }).toList(),
        );
      },
    ),
  );
}


  //--------------------------------------------------
  // COMMENT INPUT
  //--------------------------------------------------
  Widget _buildCommentInput() {
    return Container(
      color: Colors.black,
      child: Row(
        children: [

          IconButton(
            icon: const Text("🔥"),
            onPressed: () => _commentController.text += "🔥",
          ),

          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Kommentieren...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: _sendComment,
          ),
        ],
      ),
    );
  }

//--------------------------------------------------
// 👥 TEILNEHMER
//--------------------------------------------------
Widget _buildParticipants(String eventType) {
  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('adler_events')
        .doc(widget.locationId)
        .collection('events')
        .doc(eventType)
        .snapshots(),
    builder: (context, snapshot) {

      if (!snapshot.hasData || !snapshot.data!.exists) {
        return const SizedBox();
      }

      final data =
          snapshot.data!.data() as Map<String, dynamic>? ?? {};

      final participants =
          List<String>.from(data['participants'] ?? []);

      final king = data['kingName'];

      if (participants.isEmpty) {
        return const SizedBox();
      }

      participants.sort();

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(10, 5, 10, 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "👥 Teilnehmer (${participants.length})",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: participants.map((p) {

                final isKing = p == king;

                return Chip(
                  label: Text(
                    p,
                    style: TextStyle(
                      color: isKing ? Colors.black : Colors.white,
                      fontWeight:
                          isKing ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  backgroundColor: isKing
                      ? Colors.amber
                      : Colors.green.shade700,
                );
              }).toList(),
            ),
          ],
        ),
      );
    },
  );
}
  //--------------------------------------------------
  // LIVE
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
        return const Center(
          child: Text("Fehler", style: TextStyle(color: Colors.red)),
        );
      }

      //--------------------------------------------------
      // ✅ CACHE + CHAT CLEAR
      //--------------------------------------------------
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

      //--------------------------------------------------
      // ✅ RESULTS
      //--------------------------------------------------
      Map<String, dynamic> results = {};

      if (data['results'] is Map) {
        results = Map<String, dynamic>.from(data['results']);
      }

      final sorted = results.entries.toList()
        ..sort((a, b) {
          final aOrder = (a.value['order'] ?? 0) as num;
          final bOrder = (b.value['order'] ?? 0) as num;
          return bOrder.compareTo(aOrder);
        });

      //--------------------------------------------------
      // ✅ UI
      //--------------------------------------------------
      return Column(
        children: [

          //--------------------------------------------------
          // 👑 KÖNIG
          //--------------------------------------------------
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

          //--------------------------------------------------
          // 🔢 SCHÜSSE
          //--------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Schüsse: $shots",
              style: const TextStyle(color: Colors.white),
            ),
          ),

          //--------------------------------------------------
          // 🏆 + 👥
          //--------------------------------------------------
          Expanded(
            child: Column(
              children: [

                //--------------------------------------------------
                // 🏆 LISTE
                //--------------------------------------------------
                Expanded(
                  child: ListView(
                    children: sorted.map((e) {
                      final r = e.value;

                      String time = "--:--";

                      final rawTime = r['time'];

                      if (rawTime is String) {
                        time = _formatTime(DateTime.parse(rawTime));
                      } else if (rawTime is Timestamp) {
                        time = _formatTime(rawTime.toDate());
                      }

                      return ListTile(
                        title: Text(
                          e.key,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "${(r['name'] ?? "-")} • $time",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Text(
                          "${r['shots']}",
                          style: const TextStyle(
                              color: Colors.greenAccent),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                //--------------------------------------------------
                // 👥 TEILNEHMER
                //--------------------------------------------------
                _buildParticipants(eventType),
              ],
            ),
          )
        ],
      );
    },
  );
}}