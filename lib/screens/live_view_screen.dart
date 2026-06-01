import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adler_live_screen.dart';

class LiveViewScreen extends StatefulWidget {
  const LiveViewScreen({super.key});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {

  @override
  void initState() {
    super.initState();

    // Direkt nach Aufbau Dialog öffnen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openLiveDialog();
    });
  }

  //--------------------------------------------------
  // ✅ MAIN LOGIK (dein bestehender Code)
  //--------------------------------------------------
  Future<void> _openLiveDialog() async {
    final locationsSnapshot =
        await FirebaseFirestore.instance.collection('locations').get();

    final futures = locationsSnapshot.docs.map((doc) async {

      final jung = await FirebaseFirestore.instance
          .collection('adler_events')
          .doc(doc.id)
          .collection('events')
          .doc('jung')
          .get();

      final alt = await FirebaseFirestore.instance
          .collection('adler_events')
          .doc(doc.id)
          .collection('events')
          .doc('alt')
          .get();

      final isLive =
          (jung.data()?['isActive'] == true) ||
          (alt.data()?['isActive'] == true);

      return MapEntry(doc, isLive);
    });

    final results = await Future.wait(futures);

    final map = Map.fromEntries(results);

    final sorted = [
      ...map.entries.where((e) => e.value == true),
      ...map.entries.where((e) => e.value != true),
    ];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ort auswählen"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            children: sorted.map((entry) {

              final doc = entry.key;
              final isLive = entry.value;

              return ListTile(
                title: Text(doc['name'] ?? ""),

                subtitle: Text(
                  isLive
                      ? "🔥 Live aktiv"
                      : "Keine aktuellen Daten",
                ),

                leading: Icon(
                  Icons.circle,
                  size: 10,
                  color: isLive ? Colors.red : Colors.grey,
                ),

                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdlerLiveScreen(
                        locationId: doc.id,
                        locationName: doc['name'] ?? "",
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Live wird geladen..."),
      ),
    );
  }
}
