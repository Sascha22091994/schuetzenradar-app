import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';

import 'location_admin_screen.dart';
import 'news_screen.dart';
import 'home_screen.dart';

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
  // 🧹 RESET ALL ADLER EVENTS (NEU!)
  //--------------------------------------------------
  Future<void> _resetAllAdlerEvents(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Alle Adler Events löschen?"),
        content: const Text(
          "⚠️ Dadurch werden ALLE laufenden Adlerschießen zurückgesetzt.\n\n"
          "Diese Aktion kann nicht rückgängig gemacht werden.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("JA, löschen"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final db = FirebaseFirestore.instance;

      //--------------------------------------------------
      // ✅ ALLE ORTE HOLEN
      //--------------------------------------------------
      final locations = await db.collection('locations').get();

      for (final loc in locations.docs) {
        final locationId = loc.id;

        for (final eventType in ["jung", "alt"]) {
          await db
              .collection('adler_events')
              .doc(locationId)
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

        //--------------------------------------------------
        // ✅ GLOBAL LIVE AUS
        //--------------------------------------------------
        await db.collection('locations').doc(locationId).set({
          "isLive": false,
        }, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Alle Adler Events wurden zurückgesetzt")),
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
          // NEWS
          //--------------------------------------------------
          Card(
            child: ListTile(
              leading: const Icon(Icons.article),
              title: const Text("News verwalten"),
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
          // TERMINE
          //--------------------------------------------------
          Card(
            child: ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Termine verwalten"),
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
          // ORTE
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
          // 🔴 NEUER BUTTON: RESET
          //--------------------------------------------------
          const SizedBox(height: 20),

          Card(
            color: Colors.red.shade100,
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Alle Adler Events zurücksetzen"),
              subtitle: const Text("Löscht ALLE laufenden Schießen"),
              onTap: () => _resetAllAdlerEvents(context),
            ),
          ),
        ],
      ),
    );
  }
}