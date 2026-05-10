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

  List<String> players = [];

  final List<String> parts = [
    "Krone 👑",
    "Zepter ⚜️",
    "Reichsapfel 🌍",
    "Flügel links 🪽",
    "Flügel rechts 🪽",
    "Adler 🦅",
  ];

  Map<String, dynamic> results = {};

  int shots = 0;
  String? kingName;

  //--------------------------------------------------
  // ✅ ZEIT FORMAT
  //--------------------------------------------------
  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  //--------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  //--------------------------------------------------
  Future<void> _loadData() async {

    final doc = await FirebaseFirestore.instance
        .collection('adler_events')
        .doc(widget.locationId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        shots = data['shots'] ?? 0;
        kingName = data['kingName'];
        results = Map<String, dynamic>.from(data['results'] ?? {});
        players = (data['participants'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
      });
    }
  }

  //--------------------------------------------------
  Future<void> _saveData() async {

    await FirebaseFirestore.instance
        .collection('adler_events')
        .doc(widget.locationId)
        .set({

      "isActive": true,
      "shots": shots,
      "kingName": kingName,
      "results": results,
      "participants": players,

      "lastUpdate": DateTime.now().toIso8601String(),

    }, SetOptions(merge: true));
  }

  //--------------------------------------------------
  Future<void> _addPlayer() async {

    final name = nameController.text.trim();
    if (name.isEmpty || players.contains(name)) return;

    setState(() {
      players.add(name);
      nameController.clear();
    });

    await FirebaseFirestore.instance
        .collection('adler_events')
        .doc(widget.locationId)
        .set({
      "isActive": true,
      "participants": players,
    }, SetOptions(merge: true));
  }

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
              child: const Text("Abbrechen")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("OK")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      results.clear();
      shots = 0;
      kingName = null;
      players.clear();
    });

    await FirebaseFirestore.instance
        .collection('adler_events')
        .doc(widget.locationId)
        .set({
      "isActive": false,
      "shots": 0,
      "kingName": null,
      "results": {},
      "participants": [],
      "lastUpdate": DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🔄 Neues Spiel gestartet")),
    );
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text("Adler - ${widget.locationName}"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reset",
            onPressed: _resetGame,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            //--------------------------------------------------
            // ADD PLAYER
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
                ElevatedButton(
                  onPressed: _addPlayer,
                  child: const Text("Hinzufügen"),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (players.isNotEmpty)
              Wrap(
                spacing: 6,
                children:
                    players.map((p) => Chip(label: Text(p))).toList(),
              ),

            const SizedBox(height: 10),

            //--------------------------------------------------
            // SCHÜSSE
            //--------------------------------------------------
            Card(
              color: Colors.green.shade100,
              child: ListTile(
                title: Text("Schüsse: $shots"),
                trailing: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Schuss"),
                  onPressed: () async {
                    setState(() {
                      shots++;
                    });
                    await _saveData();
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            //--------------------------------------------------
            // ✅ AKTUELLE UHRZEIT
            //--------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Jetzt: ${_formatTime(DateTime.now())}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            //--------------------------------------------------
            // TREFFER LISTE
            //--------------------------------------------------
            Expanded(
              child: ListView(
                children: parts.map((part) {

                  final result = results[part];

                  return Card(
                    child: ListTile(
                      title: Text(part),

                      //--------------------------------------------------
                      // ✅ TREFFER + ZEIT
                      //--------------------------------------------------
                      subtitle: result != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${result['name']} • Schuss: ${result['shots']}"),

                                if (result['time'] != null)
                                  Text(
                                    "um ${_formatTime(DateTime.parse(result['time']))}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            )
                          : null,

                      trailing: result != null
                          ? const Icon(Icons.check, color: Colors.green)
                          : DropdownButton<String>(
                              hint: const Text("Schütze"),
                              items: players.map((p) =>
                                  DropdownMenuItem(
                                      value: p, child: Text(p)))
                                  .toList(),

                              onChanged: (value) async {
                                if (value == null) return;

                                setState(() {
                                  results[part] = {
                                    "name": value,
                                    "shots": shots,
                                    "order": DateTime.now().millisecondsSinceEpoch,
                                    "time": DateTime.now().toIso8601String(),
                                  };
                                });

                                if (part == "Adler 🦅") {
                                  kingName = value;

                                  await FirebaseFirestore.instance
                                      .collection('news')
                                      .add({
                                    "title": "👑 Neuer König in ${widget.locationName}",
                                    "content": "$value hat den Adler abgeschossen!",
                                    "date": DateTime.now().toIso8601String(),
                                    "type": "highlight",
                                    "isImportant": true,
                                  });
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection('news')
                                      .add({
                                    "title": "🦅 ${widget.locationName}",
                                    "content": "$value hat $part getroffen!",
                                    "date": DateTime.now().toIso8601String(),
                                    "type": "live",
                                    "isImportant": false,
                                  });
                                }

                                await _saveData();
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
}