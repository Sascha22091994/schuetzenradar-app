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

  //--------------------------------------------------
  // ✅ NEWS SYSTEM
  //--------------------------------------------------
  Future<void> _addNews({
    required String title,
    required String content,
    required String type,
    required bool isImportant,
  }) async {
    await FirebaseFirestore.instance.collection('news').add({
      "title": title,
      "content": content,
      "date": DateTime.now().toIso8601String(),
      "type": type,
      "isImportant": isImportant,
      "location": widget.locationName,
    });
  }

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

      final data = doc.data() as Map<String, dynamic>;
      final players = List<String>.from(data['participants'] ?? []);

      eventData[event] = {
        "shots": data['shots'] ?? 0,
        "kingName": data['kingName'],
        "results": Map<String, dynamic>.from(data['results'] ?? {}),
        "players": players,
      };
    }

    setState(() {});
  }

  //--------------------------------------------------
  // ✅ FIX: ECHTER LIVE STATUS
  //--------------------------------------------------
  Future<void> _saveData() async {

    final isActive =
        (current['shots'] ?? 0) > 0 ||
        (current['players'] as List).isNotEmpty ||
        (current['results'] as Map).isNotEmpty;

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

    //--------------------------------------------------
    // ✅ GLOBAL LIVE (FIX)
    //--------------------------------------------------
    await FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.locationId)
        .set({
      "isLive": isActive,
    }, SetOptions(merge: true));
  }

  //--------------------------------------------------
  // ✅ RESET FIXED
  //--------------------------------------------------
  Future<void> _resetGame() async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset?"),
        content: const Text("Wirklich alles löschen?"),
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
    }, SetOptions(merge: true));

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

    final theme = Theme.of(context);

    final shots = current['shots'];
    final players = List<String>.from(current['players']);
    final results = current['results'];

    return Scaffold(
      appBar: AppBar(
        title: Text("Adler - ${widget.locationName} (${selectedEvent.toUpperCase()})"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
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
                      color: selectedEvent == "jung"
                          ? Colors.green
                          : (theme.brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey),
                      child: Center(
                        child: Text(
                          "Jungkönig",
                          style: TextStyle(
                            color: selectedEvent == "jung"
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchEvent("alt"),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: selectedEvent == "alt"
                          ? Colors.green
                          : (theme.brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey),
                      child: Center(
                        child: Text(
                          "Altkönig",
                          style: TextStyle(
                            color: selectedEvent == "alt"
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              "Jetzt: ${_formatTime(DateTime.now())}",
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
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
                children: players.map((p) =>
                    Chip(label: Text(
                      p,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ))).toList(),
              ),

            const SizedBox(height: 10),

            Card(
              color: theme.brightness == Brightness.dark
                  ? Colors.green.shade900
                  : Colors.green.shade100,
              child: ListTile(
                title: Text("Schüsse: $shots",
                    style: TextStyle(color: theme.colorScheme.onSurface)),
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
                    title: Text(part,
                        style: TextStyle(color: theme.colorScheme.onSurface)),
                    subtitle: result != null
                        ? Text(
                            "${result['name']} • Schuss ${result['shots']} • ${_formatTime(DateTime.parse(result['time']))}",
                            style: TextStyle(color: theme.colorScheme.onSurface),
                          )
                        : null,
                    trailing: result != null
                        ? const Icon(Icons.check, color: Colors.green)
                        : DropdownButton<String>(
                            hint: Text("Schütze",
                                style: TextStyle(color: theme.colorScheme.onSurface)),
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

                              await _addNews(
                                title: "🎯 Treffer: $part",
                                content: "$value hat $part abgeschossen (${widget.locationName})",
                                type: "live",
                                isImportant: false,
                              );

                              if (part == "Adler 🦅") {
                                await _addNews(
                                  title: "👑 Neuer König!",
                                  content: "$value ist König in ${widget.locationName}",
                                  type: "highlight",
                                  isImportant: true,
                                );
                              }
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
