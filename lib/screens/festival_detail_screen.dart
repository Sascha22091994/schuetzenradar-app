import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../models/festival.dart';
import '../models/location.dart';
import 'location_detail_screen.dart';

class FestivalDetailScreen extends StatelessWidget {
  final Festival festival;

  const FestivalDetailScreen({
    super.key,
    required this.festival,
  });

  //--------------------------------------------------
  // ✅ SHARE
  //--------------------------------------------------
  void _shareEvent() {
    final text =
        "🎉 ${festival.name}\n\n"
        "📍 ${festival.address}\n"
        "📅 ${_formatDate()}\n\n"
        "👉 Komm vorbei zum Schützenfest!";

    Share.share(text);
  }

  //--------------------------------------------------
  // GOOGLE MAPS
  //--------------------------------------------------
  Future<void> _openMaps() async {
    final query = Uri.encodeComponent(festival.address);

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query', // ✅ FIX
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  //--------------------------------------------------
  String _formatDate() {
    return '${festival.startDate.day}.${festival.startDate.month}.${festival.startDate.year}'
        ' – ${festival.endDate.day}.${festival.endDate.month}.${festival.endDate.year}';
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(festival.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareEvent,
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          //--------------------------------------------------
          // HEADER
          //--------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  festival.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  festival.address,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          //--------------------------------------------------
          // DATUM + ADRESSE
          //--------------------------------------------------
          Card(
            child: Column(
              children: [

                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Datum'),
                  subtitle: Text(_formatDate()),
                ),

                const Divider(height: 0),

                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Adresse'),
                  subtitle: Text(festival.address),
                  onTap: _openMaps,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // MUSIK
          //--------------------------------------------------
          if (festival.musicDays.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Musikprogramm",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if ((festival.musicDays['friday'] ?? '').isNotEmpty)
                      Text("Freitag: ${festival.musicDays['friday']}"),

                    if ((festival.musicDays['saturday'] ?? '').isNotEmpty)
                      Text("Samstag: ${festival.musicDays['saturday']}"),

                    if ((festival.musicDays['sunday'] ?? '').isNotEmpty)
                      Text("Sonntag: ${festival.musicDays['sunday']}"),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // ORT BUTTON
          //--------------------------------------------------
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('locations')
                .doc(festival.id)
                .get(),
            builder: (context, snapshot) {

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox();
              }

              final location = Location.fromMap(
                snapshot.data!.id,
                snapshot.data!.data() as Map<String, dynamic>,
              );

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LocationDetailScreen(location: location),
                    ),
                  );
                },

                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [

                      const Icon(Icons.location_on, color: Colors.green),
                      const SizedBox(width: 10),

                      const Expanded(
                        child: Text("Mehr Infos zum Ort ansehen"),
                      ),

                      const Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          //--------------------------------------------------
          // ✅ FLYER (WIEDER DRIN!)
          //--------------------------------------------------
          if (festival.flyerUrl.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Flyer & Infos",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.black,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: InteractiveViewer(
                            child: Image.network(
                              festival.flyerUrl, // ✅ ORIGINAL wieder drin
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  },

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      festival.flyerUrl,

                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return const SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },

                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              "Flyer konnte nicht geladen werden",
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),

          //--------------------------------------------------
          // NAVIGATION
          //--------------------------------------------------
          ElevatedButton.icon(
            onPressed: _openMaps,
            icon: const Icon(Icons.navigation),
            label: const Text('Navigation starten'),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}