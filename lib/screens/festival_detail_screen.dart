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
  void _shareEvent() {
    final text =
        "🎉 ${festival.name}\n\n"
        "📍 ${festival.address}\n"
        "📅 ${_formatDate()}\n\n"
        "👉 Komm vorbei zum Schützenfest!";

    Share.share(text);
  }

  //--------------------------------------------------
  Future<void> _openMaps() async {
    final query = Uri.encodeComponent(festival.address);

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          // ✅ HEADER (FINAL)
          //--------------------------------------------------
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade700,
                  Colors.green.shade500,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [

                    Expanded(
                      child: Text(
                        festival.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        festival.address,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          //--------------------------------------------------
          // ✅ DATEN CARD
          //--------------------------------------------------
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [

                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Datum'),
                  subtitle: Text(_formatDate()),
                ),

                Divider(height: 1, color: Colors.grey.shade300),

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
          // ✅ MUSIKPROGRAMM
          //--------------------------------------------------
          if (festival.musicDays.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "🎵 Musikprogramm",
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
          // ✅ ORT BUTTON (FINAL)
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
                borderRadius: BorderRadius.circular(16),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.green.shade900
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.green.shade700
                          : Colors.green,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [

                      Icon(
                        Icons.location_on,
                        color: isDark
                            ? Colors.green.shade300
                            : Colors.green,
                      ),

                      const SizedBox(width: 10),

                      const Expanded(
                        child: Text(
                          "Mehr Infos zum Ort ansehen",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          //--------------------------------------------------
          // ✅ FLYER (ZOOMBAR)
          //--------------------------------------------------
          if (festival.flyerUrl.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "📄 Flyer & Infos",
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
                        child: InteractiveViewer(
                          child: Image.network(
                            festival.flyerUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      festival.flyerUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),

          //--------------------------------------------------
          // ✅ PRIMARY CTA
          //--------------------------------------------------
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openMaps,
              icon: const Icon(Icons.navigation),
              label: const Text("Navigation starten"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
