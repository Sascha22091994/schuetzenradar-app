import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';

// 👉 NEU: Admin Screens
import 'news_screen.dart';
import 'home_screen.dart';
import 'submission_admin_screen.dart';
import 'location_admin_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  //--------------------------------------------------
  // 🔓 LOGOUT
  //--------------------------------------------------
  void _logout(BuildContext context) {
    AdminService.isAdmin = false;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🔓 Admin-Modus deaktiviert"),
      ),
    );
  }

  //--------------------------------------------------
  // 🧠 ARCHIV + RESET ADLER EVENTS
  //--------------------------------------------------
  Future<void> _resetAllAdlerEvents(BuildContext context) async {

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Events archivieren & zurücksetzen?"),
        content: const Text(
          "⚠️ Alle Adlerschießen werden archiviert und zurückgesetzt.\n\n"
          "Die Ergebnisse bleiben im Archiv erhalten.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("JA"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = FirebaseFirestore.instance;
      final locations = await db.collection('locations').get();

      for (final loc in locations.docs) {

        final locationId = loc.id;

        for (final type in ['jung', 'alt']) {

          final ref = db
              .collection('adler_events')
              .doc(locationId)
              .collection('events')
              .doc(type);

          final snapshot = await ref.get();

          if (snapshot.exists) {

            //--------------------------------------------------
            // ✅ ARCHIVIEREN
            //--------------------------------------------------
            await db.collection('adler_archive').add({
              "locationId": locationId,
              "eventType": type,
              "data": snapshot.data(),
              "archivedAt": FieldValue.serverTimestamp(),
            });

            //--------------------------------------------------
            // ✅ RESET
            //--------------------------------------------------
            await ref.set({
              "isActive": false,
              "shots": 0,
              "kingName": null,
              "results": {},
              "participants": [],
              "eventType": type,
              "lastUpdate": FieldValue.serverTimestamp(),
            });
          }
        }

        //--------------------------------------------------
        // ✅ GLOBAL LIVE AUS
        //--------------------------------------------------
        await db.collection('locations').doc(locationId).set({
          "isLive": false,
        }, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Events archiviert & zurückgesetzt"),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Fehler: $e")),
      );
    }
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Bereich"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text(
            "Verwaltung",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          //--------------------------------------------------
          // ✅ NEWS (NEU!)
          //--------------------------------------------------
          Card(
            child: ListTile(
              leading: const Icon(Icons.article),
              title: const Text("News verwalten"),
              subtitle: const Text("Erstellen • Bearbeiten • Löschen"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NewsScreen(),
                  ),
                );
              },
            ),
          ),

          //--------------------------------------------------
          // ✅ TERMINE (NEU!)
          //--------------------------------------------------
          Card(
            child: ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Termine verwalten"),
              subtitle: const Text("Alle Felder bearbeiten"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );
              },
            ),
          ),

          //--------------------------------------------------
          // ✅ ORTE
          //--------------------------------------------------
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text("Orte verwalten"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationAdminScreen(),
                  ),
                );
              },
            ),
          ),

          //--------------------------------------------------
          // ✅ EINSENDUNGEN
          //--------------------------------------------------
          Card(
            child: ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text("Einsendungen"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubmissionAdminScreen(),
                  ),
                );
              },
            ),
          ),

          //--------------------------------------------------
          // ✅ RESET / ARCHIV
          //--------------------------------------------------
          const SizedBox(height: 20),

          Card(
            color: Colors.red.shade100,
            child: ListTile(
              leading: const Icon(
                Icons.archive,
                color: Colors.red,
              ),
              title: const Text("Events archivieren & zurücksetzen"),
              subtitle: const Text("Speichert Ergebnisse + startet neu"),
              onTap: () => _resetAllAdlerEvents(context),
            ),
          ),
        ],
      ),
    );
  }
}
