import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/news.dart';
import '../services/email_service.dart';
import '../services/admin_service.dart';
import 'adler_live_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {

  bool _showInfo = true;
  String selectedFilter = "all";

  @override
  void initState() {
    super.initState();
    _loadInfoState();
  }

  Future<void> _loadInfoState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showInfo = prefs.getBool("showInfo") ?? true;
    });
  }

  Future<void> _hideInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("showInfo", false);

    setState(() {
      _showInfo = false;
    });
  }

  //--------------------------------------------------
  // ✅ LIVE CHECK
  //--------------------------------------------------
  Future<bool> _isLocationLive(String locationId) async {
    final jung = await FirebaseFirestore.instance
        .collection('adler_events')
        .doc(locationId)
        .collection('events')
        .doc('jung')
        .get();

    final alt = await FirebaseFirestore.instance
        .collection('adler_events')
        .doc(locationId)
        .collection('events')
        .doc('alt')
        .get();

    return (jung.data()?['isActive'] == true) ||
           (alt.data()?['isActive'] == true);
  }

  //--------------------------------------------------
  // ✅ LIVE AUSWAHL DIALOG
  //--------------------------------------------------
  Future<void> _openLiveSelection() async {

    final locationsSnapshot =
        await FirebaseFirestore.instance.collection('locations').get();

    final futures = locationsSnapshot.docs.map((doc) async {
      final isLive = await _isLocationLive(doc.id);
      return MapEntry(doc.id, isLive);
    });

    final results = await Future.wait(futures);
    final activeMap = Map.fromEntries(results);
    final docs = locationsSnapshot.docs;

    final activeDocs =
        docs.where((doc) => activeMap[doc.id] == true).toList();

    final inactiveDocs =
        docs.where((doc) => activeMap[doc.id] != true).toList();

    final sortedDocs = [...activeDocs, ...inactiveDocs];

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ort auswählen"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            children: [

              if (activeDocs.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    "🔴 LIVE AKTUELL",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

              ...sortedDocs.map((doc) {

                final isActive = activeMap[doc.id] == true;

                return Card(
                  color: isActive
                      ? (theme.brightness == Brightness.dark
                          ? Colors.green.shade900
                          : Colors.green.shade50)
                      : null,
                  child: ListTile(
                    title: Text(
                      doc['name'] ?? "",
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      isActive
                          ? "🔥 Live aktiv"
                          : "Keine aktuellen Daten",
                      style: TextStyle(color: theme.colorScheme.onSurface),
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
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  //--------------------------------------------------
  String _formatDate(DateTime d) {
    return "${d.day}.${d.month}.${d.year}";
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("News"),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            onPressed: () => EmailService.sendFeedback(),
          ),
        ],
      ),

      //--------------------------------------------------
      // FAB
      //--------------------------------------------------
      floatingActionButton: AdminService.isAdmin
          ? FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            )
          : FloatingActionButton.extended(
              onPressed: () => EmailService.sendFeedback(),
              icon: const Icon(Icons.add),
              label: const Text("News melden"),
            ),

      //--------------------------------------------------
      // STREAM
      //--------------------------------------------------
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('news')
            .orderBy('date', descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;

          //--------------------------------------------------
          // ✅ FILTER
          //--------------------------------------------------
          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            if (selectedFilter == "highlights") {
              return data['isImportant'] == true;
            }
            if (selectedFilter == "live") {
              return data['type'] == "live";
            }
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [

              //--------------------------------------------------
              // INFO BOX
              //--------------------------------------------------
              if (_showInfo)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Text(
                        "📢 NEWS & COMMUNITY\n\n"
                        "Alles rund um dein Schützenfest:\n\n"
                        "🔥 Aktuelle Meldungen\n"
                        "⚡ Live Updates direkt vom Fest (z.B. Adlerschießen)\n"
                        "👑 Wichtige Highlights vor Ort\n\n"
                        "👉 Teile deine Infos mit der Community!",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: _hideInfo,
                          child: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                ),

              //--------------------------------------------------
              // FILTER BUTTONS
              //--------------------------------------------------
              SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _filterButton("Alle", "all"),
                    _filterButton("🔥 Wichtig", "highlights"),
                    _filterButton("⚡ Live", "live"),
                  ],
                ),
              ),

              const SizedBox(height: 10),

        //--------------------------------------------------
// LIVE CARD (FIXED + AUFFÄLLIG)
//--------------------------------------------------
FutureBuilder(
  future: FirebaseFirestore.instance.collection('locations').get(),
  builder: (context, snapshot) {

    if (!snapshot.hasData) return const SizedBox();

    final docs = snapshot.data!.docs;

    return FutureBuilder(
      future: Future.wait(
        docs.map((doc) => _isLocationLive(doc.id)),
      ),
      builder: (context, liveSnap) {

        if (!liveSnap.hasData) return const SizedBox();

        final results = liveSnap.data as List<bool>;
        final hasLive = results.contains(true);

        return Card(
          elevation: hasLive ? 6 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: hasLive
                ? BorderSide(color: Colors.redAccent, width: 2)
                : BorderSide.none,
          ),

          //--------------------------------------------------
          // ✅ DEUTLICH SICHTBAR
          //--------------------------------------------------
          color: hasLive
              ? (theme.brightness == Brightness.dark
                  ? Colors.red.shade800
                  : Colors.red.shade200)
              : null,

          child: ListTile(
            leading: Icon(
              Icons.visibility,
              size: 28,
              color: hasLive ? Colors.redAccent : Colors.grey,
            ),

            //--------------------------------------------------
            // ✅ LIVE BADGE IM TITEL
            //--------------------------------------------------
            title: Row(
              children: [
                Text(
                  "Adlerschießen verfolgen",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: hasLive ? 17 : 15,
                  ),
                ),

                if (hasLive)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "LIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            //--------------------------------------------------
            // ✅ TEXT
            //--------------------------------------------------
            subtitle: Text(
              hasLive
                  ? "🔥 Gerade aktiv! Jetzt reinschauen!"
                  : "Momentan kein Live Event",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: hasLive ? FontWeight.bold : FontWeight.normal,
              ),
            ),

            trailing: const Icon(Icons.arrow_forward_ios),

            //--------------------------------------------------
            // ✅ CLICK
            //--------------------------------------------------
            onTap: _openLiveSelection,
          ),
        );
      },
    );
  },
),

              //--------------------------------------------------
              // NEWS LIST
              //--------------------------------------------------
              ...filteredDocs.map((doc) {

                final data = doc.data() as Map<String, dynamic>;
                final news = NewsItem.fromMap(data);

                final important = data['isImportant'] == true;

                return Card(
                  color: important
                      ? (theme.brightness == Brightness.dark
                          ? const Color(0xFF3A2E00)
                          : Colors.amber.shade50)
                      : null,
                  child: ListTile(
                    title: Text(
                      news.title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "${_formatDate(news.date)}\n${news.text}",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  //--------------------------------------------------
  Widget _filterButton(String label, String value) {

    final active = selectedFilter == value;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? Colors.green
              : (theme.brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}