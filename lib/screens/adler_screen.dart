import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdlerScreen extends StatefulWidget {
  final String locationId;
  final String locationName;
  

  const AdlerScreen({
    super.key,
    required this.locationId,
    required this.locationName,
    
  });

  @override
  State<AdlerScreen> createState() => _AdlerScreenState();
}

class _AdlerScreenState extends State<AdlerScreen> {
  bool showInfo = true;
  final TextEditingController nameController = TextEditingController();
  String selectedEvent = "jung";

  Map<String, Map<String, dynamic>> eventData = {
    "jung": {
      "shots": 0,
      "kingName": null,
      "results": {},
      "players": <String>[],
    },
    "alt": {
      "shots": 0,
      "kingName": null,
      "results": {},
      "players": <String>[],
    },
  };

  final List<String> parts = [
    "Krone 👑",
    "Zepter ⚜️",
    "Reichsapfel 🍎",
    "Flügel links 🕊️",
    "Flügel rechts 🕊️",
    "Adler 🦅",
  ];

  Map<String, dynamic> get current => eventData[selectedEvent]!;

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  //--------------------------------------------------
  // ✅ LIVE EVENT
  //--------------------------------------------------
Future<DocumentReference> _ensureLiveEvent() async {
  final db = FirebaseFirestore.instance;

  final docRef = db
      .collection('news')
      .doc("live_${widget.locationId}"); // ✅ FIXE ID

  final doc = await docRef.get();

  if (doc.exists) {
    await docRef.update({
      "eventType": selectedEvent,
      "locationId": widget.locationId,
      "location": widget.locationName,
      "isActive": true,
    });

    return docRef;
  }

  await docRef.set({
    "title": "🦅 Adlerschießen LIVE",
    "location": widget.locationName,
    "locationId": widget.locationId,
    "type": "liveEvent",
    "eventType": selectedEvent,
    "updates": [],
    "isActive": true,
    "date": DateTime.now().toIso8601String(),
  });

  return docRef;
}


  //--------------------------------------------------
  Future<void> _addLiveUpdate(String text) async {
    final ref = await _ensureLiveEvent();

    await ref.update({
      "updates": FieldValue.arrayUnion([
        {
          "text": text,
          "time": DateTime.now().toIso8601String()
        }
      ]),
    });
  }

  //--------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadBothEvents();
    _checkInactivityAuto();
  }

  Future<void> _loadBothEvents() async {
    for (var event in ["jung", "alt"]) {
      final doc = await FirebaseFirestore.instance
          .collection('adler_events')
          .doc(widget.locationId)
          .collection('events')
          .doc(event)
          .get();

      if (!doc.exists) continue;

      final data = doc.data()!;
      eventData[event] = {
        "shots": data['shots'] ?? 0,
        "kingName": data['kingName'],
        "results": Map<String, dynamic>.from(data['results'] ?? {}),
        "players": List<String>.from(data['participants'] ?? []),
      };
    }


    setState(() {});
  }

  //--------------------------------------------------
  Future<void> _saveData() async {
    final isActive =
        current['shots'] > 0 ||
        current['players'].isNotEmpty ||
        current['results'].isNotEmpty;

    await FirebaseFirestore.instance
        .collection('adler_events')
        .doc(widget.locationId)
        .collection('events')
        .doc(selectedEvent)
        .set({
      "isActive": isActive,
      "shots": current['shots'],
      "kingName": current['kingName'],
      "results": current['results'],
      "participants": current['players'],
      "eventType": selectedEvent,
      "lastUpdate": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.locationId)
        .set({"isLive": isActive}, SetOptions(merge: true));
  }

//--------------------------------------------------
// ✅ ARCHIVIEREN (NEU)
//--------------------------------------------------
Future<void> _archiveCurrentGame() async {
  final db = FirebaseFirestore.instance;

  for (var event in ["jung", "alt"]) {
    final data = eventData[event]!;

    // ✅ nur archivieren wenn Daten vorhanden
    if (data['shots'] == 0 &&
        data['players'].isEmpty &&
        data['results'].isEmpty) {
      continue;
    }


await db.collection('adler_archive').add({
  "locationId": widget.locationId,
  "locationName": widget.locationName,
  "eventType": event,
  "kingName": data['kingName'],
  "shots": data['shots'],
  "participants": data['participants'],
  "results": data['results'],
  "createdAt": DateTime.now().toIso8601String(),
  "endedAt": DateTime.now().toIso8601String(),
});

await db
    .collection('adler_events')
    .doc(widget.locationId)
    .collection('events')
    .doc(event)
    .set({
  "archived": true,
}, SetOptions(merge: true));


  }
}

//--------------------------------------------------
// ✅ LIVE TICKER BEENDEN (FINAL)
//--------------------------------------------------
Future<void> _stopLiveTicker() async {
  final db = FirebaseFirestore.instance;

  final docRef = db
      .collection('news')
      .doc("live_${widget.locationId}"); // ✅ FIXE ID

  final doc = await docRef.get();

  if (!doc.exists) return; // ✅ Sicherheitscheck

  await docRef.update({
    "isActive": false,
    "updates": [],
  });
}

//--------------------------------------------------
// ✅ AUTO INAKTIV CHECK (FINAL)
//--------------------------------------------------
Future<void> _checkInactivityAuto() async {
  final db = FirebaseFirestore.instance;

  bool somethingReset = false; // ✅ NEU

  for (var event in ["jung", "alt"]) {
    final docRef = db
        .collection('adler_events')
        .doc(widget.locationId)
        .collection('events')
        .doc(event);

    final doc = await docRef.get();
    if (!doc.exists) continue;

    final data = doc.data()!;
    final lastUpdate = data['lastUpdate'];

    if (lastUpdate == null) continue;

    final last = (lastUpdate as Timestamp).toDate();
    final diff = DateTime.now().difference(last);

    //--------------------------------------------------
    // ✅ 12h überschritten
    //--------------------------------------------------
    if (diff.inHours >= 12) {

      somethingReset = true; // ✅ WICHTIG

      //--------------------------------------------------
      // ✅ ARCHIV (nur wenn noch nicht passiert)
      //--------------------------------------------------
      if (data['archived'] != true) {

        if ((data['shots'] ?? 0) > 0 ||
            (data['participants'] ?? []).isNotEmpty ||
            (data['results'] ?? {}).isNotEmpty) {

          await db.collection('adler_archive').add({
            "locationId": widget.locationId,
            "locationName": widget.locationName,
            "eventType": event,
            "kingName": data['kingName'],
            "shots": data['shots'],
            "participants": data['participants'],
            "results": data['results'],
            "createdAt": DateTime.now().toIso8601String(),
            "endedAt": DateTime.now().toIso8601String(),
          });
        }
      }

      //--------------------------------------------------
      // ✅ RESET
      //--------------------------------------------------
      await docRef.set({
        "isActive": false,
        "shots": 0,
        "kingName": null,
        "results": {},
        "participants": [],
        "eventType": event,
        "lastUpdate": FieldValue.serverTimestamp(),
        "archived": true,
      }, SetOptions(merge: false));
    }
  }

  //--------------------------------------------------
  // ✅ NUR AUSFÜHREN WENN WIRKLICH RESET
  //--------------------------------------------------
  if (somethingReset) {
    await _stopLiveTicker();

    await db.collection('locations').doc(widget.locationId).set({
      "isLive": false,
    }, SetOptions(merge: true));
  }
}



  //--------------------------------------------------
Future<void> _resetGame() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Reset?"),
      content: const Text("Alles zurücksetzen und archivieren?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Abbrechen"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("OK"),
        ),
      ],
    ),
  );

  if (confirm != true) return;



  //--------------------------------------------------
  // ✅ 1. ARCHIVIEREN
  //--------------------------------------------------
  try {
    await _archiveCurrentGame();
    await _stopLiveTicker(); 
    
  } catch (e) {
    debugPrint("Archiv Fehler: $e");
  }



  //--------------------------------------------------
  // ✅ 2. RESET LOCAL STATE
  //--------------------------------------------------
  setState(() {
    current['shots'] = 0;
    current['kingName'] = null;
    current['results'].clear();
    current['players'].clear();
  });

  //--------------------------------------------------
  // ✅ 3. FIREBASE UPDATE
  //--------------------------------------------------
  await _saveData();

  //--------------------------------------------------
  // ✅ FEEDBACK
  //--------------------------------------------------
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("✅ Ergebnis archiviert")),
  );
}


  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shots = current['shots'];
    final players = List<String>.from(current['players']);
    final results = current['results'];

    return Scaffold(
      appBar: AppBar(
  elevation: 0,
  backgroundColor: Colors.green.shade700,

  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.green.shade800,
          Colors.green.shade600,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),

  title: Row(
    children: [
      const Icon(Icons.my_location, color: Colors.white, size: 35),
      const SizedBox(width: 8),

      Expanded(
        child: Text(
          "${widget.locationName} • ${selectedEvent.toUpperCase()}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            letterSpacing: 0.4,
          ),
        ),
      ),
    ],
  ),

  actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: "Reset",
      onPressed: _resetGame,
    ),
  ],
),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

//--------------------------------------------------
// ℹ️ INFO FÜR PROTOKOLLFÜHRER
//--------------------------------------------------

if (showInfo)
  Container(
    margin: const EdgeInsets.only(top: 8, bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      
color: isDark
    ? Colors.blue.shade900
    : Colors.blue.shade50,

border: Border.all(
  color: isDark
      ? Colors.blue.shade700
      : Colors.blue.shade200,
),

    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: Colors.blue),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            "Hinweis:\n"
            "Nach 12 Stunden Inaktivität werden die Ergebnisse hier automatisch zurückgesetzt.\n\n"
            "✅ Alle Daten bleiben im Archiv gespeichert (Siehe unter Bereich 'Orte')\n"
            "📜 und sind jederzeit für jeden einsehbar.",
            style: const TextStyle(fontSize: 11),
          ),
        ),

        //--------------------------------------------------
        // ❌ CLOSE BUTTON
        //--------------------------------------------------
        GestureDetector(
          onTap: () {
            setState(() {
              showInfo = false;
            });
          },
          child: const Icon(Icons.close, size: 18, color: Colors.grey),
        ),
      ],
    ),
  ),


            //--------------------------------------------------
            // SWITCH
            //--------------------------------------------------
            Row(
              children: [
                _eventButton("Jungkönig", "jung"),
                _eventButton("Altkönig", "alt"),
              ],
            ),

            const SizedBox(height: 10),
const SizedBox(height: 10),




            //--------------------------------------------------
            // KÖNIG
            //--------------------------------------------------
            if (current['kingName'] != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
    ? Colors.amber.shade700
    : Colors.amber.shade300,

                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "👑 ${current['kingName']} ist König!",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

            //--------------------------------------------------
            // SPIELER
            //--------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Schütze hinzufügen",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addPlayer, child: const Text("Hinzufügen")),
              ],
            ),

            const SizedBox(height: 10),

            //--------------------------------------------------
// 🔥 GROSSER SCHUSS BUTTON
//--------------------------------------------------
SizedBox(
  width: double.infinity,
  height: 60,
  child: ElevatedButton.icon(
    icon: const Icon(Icons.add_circle, size: 28),
    label: const Text(
      "Schuss hinzufügen",
      style: TextStyle(fontSize: 18),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    onPressed: () async {
      setState(() => current['shots']++);
      await _saveData();
    },
  ),
),
            //--------------------------------------------------
            // SCHUSS COUNTER
            //--------------------------------------------------
  Card(
  color: isDark
    ? Colors.green.shade900
    : Colors.green.shade100,
  child: ListTile(
    title: Text(
      "Schüsse: $shots",
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
),


            if (players.isNotEmpty)
              Wrap(
                spacing: 6,
                children: players.map((p) => Chip(label: Text(p))).toList(),
              ),

            const SizedBox(height: 10),

            //--------------------------------------------------
            // PARTS
            //--------------------------------------------------
            Expanded(
              child: ListView(
                children: parts.map((part) {
                  final result = results[part];
                  final isKingPart = part == "Adler 🦅";

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: result != null
    ? (isDark
        ? Colors.green.shade900
        : Colors.green.shade50)
    : (isDark
        ? Colors.grey.shade800
        : Colors.grey.shade100),
                    child: ListTile(
                      title: Text(
                        part,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isKingPart ? Colors.red : Colors.black,
                        ),
                      ),
                      subtitle: result != null
                          ? Text("${result['name']} • Schuss ${result['shots']} • ${_formatTime(DateTime.parse(result['time']))}")
                          : null,

                      trailing: result != null
                          ? Icon(
                              isKingPart
                                  ? Icons.emoji_events
                                  : Icons.check_circle,
                              color: isKingPart
                                  ? Colors.amber
                                  : Colors.green,
                            )
                          : DropdownButton<String>(
                              hint: const Text("Schütze"),
                              items: players.map((p) =>
                                  DropdownMenuItem(value: p, child: Text(p)))
                                  .toList(),
                              onChanged: players.isEmpty
                                  ? null
                                  : (value) async {
                                      if (value == null) return;

                                      setState(() {
                                        current['results'][part] = {
                                          "name": value,
                                          "shots": current['shots'],
                                          "time": DateTime.now().toIso8601String(),
                                          "order": DateTime.now().millisecondsSinceEpoch,
                                        };

                                        if (isKingPart) {
                                          current['kingName'] = value;
                                        }
                                      });

                                      await _saveData();

                                      await _addLiveUpdate("✅ $part – $value");

                                      if (isKingPart) {
                                       await _addLiveUpdate(
  selectedEvent == "alt"
      ? "👑 Altkönig: $value (${current['shots']} Schuss)"
      : "👑 Jungkönig: $value (${current['shots']} Schuss)",
);

                                      }
                                    },
                            ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //--------------------------------------------------
Widget _eventButton(String label, String value) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final active = selectedEvent == value;

  return Expanded(
    child: GestureDetector(
      onTap: () => setState(() => selectedEvent = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        color: active
            ? (isDark ? Colors.green.shade700 : Colors.green)
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black),
            ),
          ),
        ),
      ),
    ),
  );
}

  //--------------------------------------------------
  Future<void> _addPlayer() async {
    final name = nameController.text.trim();
    if (name.isEmpty || current['players'].contains(name)) return;

    setState(() {
      current['players'].add(name);
      nameController.clear();
    });

    await _saveData();
  }
}