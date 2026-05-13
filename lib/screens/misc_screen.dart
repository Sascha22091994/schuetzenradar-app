import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/location.dart';
import '../services/admin_service.dart';

import 'location_detail_screen.dart';
import 'admin_dashboard_screen.dart';

class MiscScreen extends StatelessWidget {
  const MiscScreen({super.key});

  //--------------------------------------------------
  // 🔐 ADMIN LOGIN (UPDATED)
  //--------------------------------------------------
  void _showAdminLogin(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Admin Login"),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: "Passwort eingeben",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {

              final success = await AdminService.login(
                controller.text.trim(),
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Admin aktiviert"),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ Falsches Passwort"),
                  ),
                );
              }

              Navigator.pop(context);
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
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
    children: const [
      Icon(Icons.widgets_outlined, color: Colors.white, size: 35),
      SizedBox(width: 8),
      Text(
        "Sonstiges",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 30,
          letterSpacing: 0.4,
        ),
      ),
    ],
  ),

        //--------------------------------------------------
        // 🔐 / ⚙️ BUTTONS
        //--------------------------------------------------
        actions: [

          // 🔐 Login (nur wenn nicht Admin)
          if (!AdminService.isAdmin)
            IconButton(
              icon: const Icon(Icons.lock),
              onPressed: () => _showAdminLogin(context),
            ),

          // ⚙️ Admin Bereich (nur wenn Admin)
          if (AdminService.isAdmin)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen(),
                  ),
                );
              },
            ),
        ],
      ),

      //--------------------------------------------------
      // 📍 ORTE
      //--------------------------------------------------
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('locations')
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final locations = snapshot.data!.docs.map((doc) {
            return Location.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [

              //--------------------------------------------------
              // HEADER
              //--------------------------------------------------
              const Text(
                "Orte im Kreis",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              //--------------------------------------------------
              // LISTE
              //--------------------------------------------------
              ...locations.map((loc) {
                return Card(
                  child: ListTile(
                    title: Text(loc.name),
                    trailing:
                        const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LocationDetailScreen(
                                  location: loc),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
