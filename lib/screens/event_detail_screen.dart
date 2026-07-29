import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../models/event.dart';
import '../models/event_category.dart';
import '../theme/app_colors.dart';
import '../widgets/rating_section.dart';
import '../widgets/report_event_sheet.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  //--------------------------------------------------
  void _shareEvent(BuildContext context) {
    final text =
        "${event.name}\n\n"
        "${event.address}\n"
        "${_formatDate()}\n\n"
        "Entdecke dieses Event mit ErlebnisRadar!";

    final box = context.findRenderObject();

    if (box is RenderBox && box.hasSize) {
      Share.share(
        text,
        sharePositionOrigin:
            box.localToGlobal(Offset.zero) & box.size,
      );
    } else {
      Share.share(text);
    }
  }

  //--------------------------------------------------
  Future<void> _openMaps() async {
    final query = Uri.encodeComponent(event.address);

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  //--------------------------------------------------
  String _formatDate() {
    return '${event.startDate.day}.${event.startDate.month}.${event.startDate.year}'
        ' – ${event.endDate.day}.${event.endDate.month}.${event.endDate.year}';
  }

  //--------------------------------------------------
  String _categoryLabel() {
    return EventCategoryExtension.fromString(event.category)?.label ??
        event.category;
  }

  //--------------------------------------------------
  // ✅ NEU: Vollbild-Ansicht mit Zoom, konsistent zu Flyer/Galerie
  //--------------------------------------------------
  void _showFullscreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final secondaryTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final dividerColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    // ✅ TIER 4: Hinweis, falls das Event keiner festen Kategorie
    // zugeordnet werden konnte (nur bei "sonstiges" != null).
    final categoryHint =
        EventCategoryExtension.fromString(event.category)?.hint;

    //--------------------------------------------------
    // ✅ BILDER-DEDUPLIZIERUNG
    //--------------------------------------------------
    final headerImage = event.images.isNotEmpty ? event.images.first : '';

    final showFlyerSeparately =
        event.flyerUrl.isNotEmpty && event.flyerUrl != headerImage;

    final galleryImages = event.images
        .where((url) => url != headerImage && url != event.flyerUrl)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          event.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: "Event melden",
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => showReportEventSheet(
              context,
              eventId: event.id,
              eventName: event.name,
            ),
          ),
          IconButton(
            tooltip: "Teilen",
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareEvent(context),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          //--------------------------------------------------
          // ✅ HEADER
          //--------------------------------------------------
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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

                // ✅ ANGEPASST: antippbar, öffnet Vollbild-Ansicht mit Zoom
                if (headerImage.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showFullscreenImage(context, headerImage),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Hero(
                        tag: event.id,
                        child: Image.network(
                          headerImage,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                if (headerImage.isNotEmpty) const SizedBox(height: 16),

                Text(
                  event.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _categoryLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.address,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ✅ TIER 4: Info-Banner bei nicht zuordenbaren Events
          if (categoryHint != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blueGrey.shade900.withValues(alpha: 0.4)
                    : Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dividerColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: secondaryTextColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      categoryHint,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

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
                  leading: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                  ),
                  title: const Text('Datum'),
                  subtitle: Text(_formatDate()),
                ),

                Divider(height: 1, color: dividerColor),

                ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: AppColors.secondary,
                  ),
                  title: const Text('Adresse'),
                  subtitle: Text(event.address),
                  onTap: _openMaps,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // ✅ MUSIKPROGRAMM
          //--------------------------------------------------
          if (event.musicDays.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        const Icon(Icons.music_note_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          "Live-Programm",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    if ((event.musicDays['friday'] ?? '').isNotEmpty)
                      Text("Freitag: ${event.musicDays['friday']}"),

                    if ((event.musicDays['saturday'] ?? '').isNotEmpty)
                      Text("Samstag: ${event.musicDays['saturday']}"),

                    if ((event.musicDays['sunday'] ?? '').isNotEmpty)
                      Text("Sonntag: ${event.musicDays['sunday']}"),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // ✅ HIGHLIGHTS
          //--------------------------------------------------
          if (event.highlights.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          "Highlights",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(event.highlights),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // ✅ BESCHREIBUNG
          //--------------------------------------------------
          if (event.description.isNotEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          "Beschreibung",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(event.description),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // ✅ BEWERTUNGEN
          //--------------------------------------------------
          RatingSection(eventId: event.id),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // ✅ ORT BUTTON
          //--------------------------------------------------
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('locations')
                .doc(event.id)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox();
              }

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark
                        : const Color(0xFFF4F7FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [

                      const Icon(
                        Icons.location_on,
                        color: AppColors.secondary,
                      ),

                      const SizedBox(width: 10),

                      const Expanded(
                        child: Text(
                          "Standort & Umgebung",
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
          // ✅ FLYER
          //--------------------------------------------------
          if (showFlyerSeparately)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    const Icon(Icons.description_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      "Flyer & Informationen",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () => _showFullscreenImage(context, event.flyerUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      event.flyerUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),

          //--------------------------------------------------
          // ✅ WEITERE BILDER (SLIDER)
          //--------------------------------------------------
          if (galleryImages.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  "Weitere Bilder",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Column(
              children: [

                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: galleryImages.length,
                    itemBuilder: (context, index) {
                      final url = galleryImages[index];

                      return GestureDetector(
                        onTap: () => _showFullscreenImage(context, url),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    galleryImages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],

          //--------------------------------------------------
          // ✅ PRIMARY CTA
          //--------------------------------------------------
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openMaps,
              icon: const Icon(Icons.navigation_rounded),
              label: const Text("Route starten"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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