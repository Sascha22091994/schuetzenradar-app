import 'package:flutter/material.dart';
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

    Navigator.pop(context); // zurück zu vorherigem Screen

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🔓 Admin-Modus deaktiviert"),
      ),
    );
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Bereich"),

        //--------------------------------------------------
        // ✅ LOGOUT BUTTON OBEN RECHTS
        //--------------------------------------------------
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
        ],
      ),
    );
  }
}