import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/location.dart';
import 'adler_login_screen.dart';



class LocationDetailScreen extends StatelessWidget {
  final Location location;

  const LocationDetailScreen({super.key, required this.location});

  //--------------------------------------------------
  // LINK ÖFFNEN
  //--------------------------------------------------
  Future<void> _open(String url) async {
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  //--------------------------------------------------
  // BUILD
  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(location.name),
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [

          const SizedBox(height: 10),

          //--------------------------------------------------
          // 📸 INSTAGRAM
          //--------------------------------------------------
          if (location.instagram.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Instagram"),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _open(location.instagram),
              ),
            ),

          //--------------------------------------------------
          // 🌐 WEBSITE
          //--------------------------------------------------
          if (location.website.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: const Text("Website"),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _open(location.website),
              ),
            ),

          //--------------------------------------------------
          // 🦅 ADLERSCHIESSEN
          //--------------------------------------------------
if (location.hasAdler)
  Card(
    child: ListTile(
      leading: const Icon(Icons.emoji_events),
      title: const Text("Adlerschießen"),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdlerLoginScreen(
              locationId: location.id,
              locationName: location.name,
            ),
          ),
        );
      },
    ),
  ),

          //--------------------------------------------------
          // FALLBACK (wenn nichts vorhanden)
          //--------------------------------------------------
          if (location.instagram.isEmpty &&
              location.website.isEmpty &&
              !location.hasAdler)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: Text(
                  "Noch keine Infos für diesen Ort verfügbar.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}