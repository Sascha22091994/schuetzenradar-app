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

    final query = await db.collection('news')
        .where('type', isEqualTo: 'liveEvent')
        .where('location', isEqualTo: widget.locationName)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.reference;
    }

    return await db.collection('news').add({
      "title": "🦅 Adlerschießen LIVE",
      "location": widget.locationName,
      "type": "liveEvent",
      "updates": [],
      "isActive": true,
      "date": DateTime.now().toIso8601String(),
    });
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
  Future<void> _resetGame() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset?"),
        content: const Text("Alles zurücksetzen?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Abbrechen")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("OK")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      current['shots'] = 0;
      current['kingName'] = null;
      current['results'].clear();
      current['players'].clear();
    });

    await _saveData();
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    final shots = current['shots'];
    final players = List<String>.from(current['players']);
    final results = current['results'];

    return Scaffold(
      appBar: AppBar(
        title: Text("Adler – ${widget.locationName} (${selectedEvent.toUpperCase()})"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            //--------------------------------------------------
            // SWITCH
            //--------------------------------------------------
            Row(
              children: [
                _eventButton("Jung", "jung"),
                _eventButton("Alt", "alt"),
              ],
            ),

            const SizedBox(height: 10),

            //--------------------------------------------------
            // SCHUSS COUNTER
            //--------------------------------------------------
            Card(
              color: Colors.green.shade100,
              child: ListTile(
                title: Text("Schüsse: $shots",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    setState(() => current['shots']++);
                    await _saveData();
                  },
                ),
              ),
            ),

            //--------------------------------------------------
            // KÖNIG
            //--------------------------------------------------
            if (current['kingName'] != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade300,
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
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
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
                                          "👑 König: $value (${current['shots']} Schuss)",
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
    final active = selectedEvent == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedEvent = value),
        child: Container(
          padding: const EdgeInsets.all(12),
          color: active ? Colors.green : Colors.grey,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                  color: active ? Colors.white : Colors.black),
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