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
      "results": <String, dynamic>{},
      "players": <String>[],
    },
    "alt": {
      "shots": 0,
      "kingName": null,
      "results": <String, dynamic>{},
      "players": <String>[],
    },
  };

  final List<String> parts = [
    "Krone 👑",
    "Zepter ⚜️",
    "Reichsapfel 🌍",
    "Flügel links 🪽",
    "Flügel rechts 🪽",
    "Adler 🦅",
  ];

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  Map<String, dynamic> get current => eventData[selectedEvent]!;

  @override
  void initState() {
    super.initState();
    _loadBothEvents();
  }

  //--------------------------------------------------
  // ✅ FIX: isActive reset wenn KEINE Spieler
  //--------------------------------------------------
  Future<void> _loadBothEvents() async {
    for (var event in ["jung", "alt"]) {

      final doc = await FirebaseFirestore.instance
          .collection('adler_events')
          .doc(widget.locationId)
          .collection('events')
          .doc(event)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        final players = List<String>.from(data['participants'] ?? []);

        eventData[event] = {
          "shots": data['shots'] ?? 0,
          "kingName": data['kingName'],
          "results": Map<String, dynamic>.from(
            (data['results'] ?? {}).map((k, v) =>
                MapEntry(k.toString(), Map<String, dynamic>.from(v))),
          ),
          "players": players,
        };

        //--------------------------------------------------
        // ✅ WICHTIG: wenn keine Spieler → nicht aktiv
        //--------------------------------------------------
        if (players.isEmpty && data['isActive'] == true) {
          await FirebaseFirestore.instance
              .collection('adler_events')
              .doc(widget.locationId)
              .collection('events')
              .doc(event)
              .set({
            "isActive": false,
          }, SetOptions(merge: true));
        }
      }
    }

    setState(() {});
  }

  //--------------------------------------------------
Future<void> _saveData() async {

  print("🔥 SAVE START");
  print("📍 Location: ${widget.locationId}");
  print("🎯 Event: $selectedEvent");

  try {
    await FirebaseFirestore.instance
        .collection('adler_events')
        .doc(widget.locationId)
        .collection('events')
        .doc(selectedEvent)
        .set({

      "isActive": true,
      "shots": current['shots'],
      "kingName": current['kingName'],
      "results": current['results'],
      "participants": current['players'],
      "eventType": selectedEvent,

      //--------------------------------------------------
      // ✅ SERVER TIME = BESSER
      //--------------------------------------------------
      "lastUpdate": FieldValue.serverTimestamp(),

    }, SetOptions(merge: true));

    //--------------------------------------------------
    // ✅ NEU: LOCATION LIVE STATUS
    //--------------------------------------------------
    await FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.locationId)
        .set({
      "isLive": true,
    }, SetOptions(merge: true));

    print("✅ SAVE ERFOLGREICH");

  } catch (e) {
    print("❌ FEHLER BEIM SPEICHERN: $e");
  }
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

  //--------------------------------------------------
  Future<void> _resetGame() async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset?"),
        content: const Text("Wirklich alles löschen?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Abbrechen")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("OK")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      current['results'].clear();
      current['shots'] = 0;
      current['kingName'] = null;
      current['players'].clear();
    });

    await FirebaseFirestore.instance
    .collection('adler_events')
    .doc(widget.locationId)
    .collection('events')
    .doc(selectedEvent)
    .set({
  "isActive": false,
  "shots": 0,
  "kingName": null,
  "results": {},
  "participants": [],
  "eventType": selectedEvent,

  //--------------------------------------------------
  // ✅ SERVER TIME = BESSER
  //--------------------------------------------------
  "lastUpdate": FieldValue.serverTimestamp(),

}, SetOptions(merge: true));

//--------------------------------------------------
// ✅ NEU: LIVE STATUS AUS
//--------------------------------------------------

  await FirebaseFirestore.instance
      .collection('locations')
      .doc(widget.locationId)
      .set({
    "isLive": false,
  }, SetOptions(merge: true));
}


  //--------------------------------------------------
  void _switchEvent(String type) {
    setState(() {
      selectedEvent = type;
    });
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    final shots = current['shots'];
    final players = List<String>.from(current['players']);
    final results = current['results'];

    return Scaffold(
      appBar: AppBar(
        title: Text("Adler - ${widget.locationName} (${selectedEvent.toUpperCase()})"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchEvent("jung"),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: selectedEvent == "jung" ? Colors.green : Colors.grey,
                      child: const Center(child: Text("Jungkönig")),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchEvent("alt"),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: selectedEvent == "alt" ? Colors.green : Colors.grey,
                      child: const Center(child: Text("Altkönig")),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text("Jetzt: ${_formatTime(DateTime.now())}"),

            const SizedBox(height: 10),

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

            Card(
              color: Colors.green.shade100,
              child: ListTile(
                title: Text("Schüsse: $shots"),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    setState(() {
                      current['shots']++;
                    });
                    await _saveData();
                  },
                ),
              ),
            ),

            Expanded(
              child: ListView(
                children: parts.map((part) {

                  final result = results[part];

                  return ListTile(
                    title: Text(part),
                    subtitle: result != null
                        ? Text("${result['name']} • Schuss ${result['shots']} • ${_formatTime(DateTime.parse(result['time']))}")
                        : null,
                    trailing: result != null
                        ? const Icon(Icons.check, color: Colors.green)
                        : DropdownButton<String>(
                            hint: const Text("Schütze"),
                            items: players.map((p) =>
                                DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (value) async {
                              if (value == null) return;

                              setState(() {
                                current['results'][part] = {
                                  "name": value,
                                  "shots": current['shots'],
                                  "time": DateTime.now().toIso8601String(),
                                  "order": DateTime.now().millisecondsSinceEpoch,
                                };

                                if (part == "Adler 🦅") {
                                  current['kingName'] = value;
                                }
                              });

                              await _saveData();
                            },
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
}
