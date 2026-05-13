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

  final Set<String> _expandedLiveEvents = {};

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
    setState(() => _showInfo = false);
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
  // ✅ LIVE AUSWAHL
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

    final sortedDocs = [
      ...docs.where((d) => activeMap[d.id] == true),
      ...docs.where((d) => activeMap[d.id] != true),
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ort auswählen"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            children: sortedDocs.map((doc) {
              final isActive = activeMap[doc.id] == true;
              return ListTile(
                title: Text(doc['name'] ?? ""),
                subtitle: Text(
                  isActive ? "🔥 Live aktiv" : "Keine aktuellen Daten",
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

  String _formatDate(DateTime d) =>
      "${d.day}.${d.month}.${d.year}";

  String _formatTime(DateTime d) =>
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

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

      floatingActionButton: AdminService.isAdmin
          ? FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add))
          : FloatingActionButton.extended(
              onPressed: () => EmailService.sendFeedback(),
              icon: const Icon(Icons.add),
              label: const Text("News melden"),
            ),

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

          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (selectedFilter == "highlights") {
              return data['isImportant'] == true;
            }
            if (selectedFilter == "live") {
              return data['type'] == "liveEvent";
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
                      const Text(
                        "📢 NEWS & COMMUNITY\n\n"
                        "🔥 Aktuelle Meldungen\n"
                        "⚡ Live‑Ticker vom Fest\n"
                        "👑 Wichtige Highlights\n",
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
              // FILTER
              //--------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _filterButton("Alle", "all"),
                  _filterButton("🔥 Wichtig", "highlights"),
                  _filterButton("⚡ Live", "live"),
                ],
              ),

              const SizedBox(height: 12),

              //--------------------------------------------------
// 🔴 LIVE PRESENTER (IMMER SICHTBAR)
//--------------------------------------------------
FutureBuilder(
  future: FirebaseFirestore.instance.collection('locations').get(),
  builder: (context, snap) {
    if (!snap.hasData) return const SizedBox();

    return FutureBuilder(
      future: Future.wait(
        snap.data!.docs.map((d) => _isLocationLive(d.id)),
      ),
      builder: (context, liveSnap) {

        if (!liveSnap.hasData) return const SizedBox();

        final hasLive = (liveSnap.data as List<bool>).contains(true);

        //--------------------------------------------------
        // ✅ FARBEN
        //--------------------------------------------------
        final bgColor = hasLive
            ? Colors.red.shade400
            : Colors.grey.shade300;

        final textColor = hasLive
            ? Colors.white
            : Colors.black87;

        final subColor = hasLive
            ? Colors.white70
            : Colors.black54;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),

          child: InkWell(
            borderRadius: BorderRadius.circular(14),

            //--------------------------------------------------
            // ✅ CLICK NUR WENN LIVE
            //--------------------------------------------------
            onTap: hasLive ? _openLiveSelection : null,

            child: Row(
              children: [

                Icon(
                  hasLive ? Icons.visibility : Icons.info_outline,
                  color: textColor,
                  size: 28,
                ),

                const SizedBox(width: 12),

                //--------------------------------------------------
                // TEXT BLOCK
                //--------------------------------------------------
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        hasLive
                            ? "Live‑Ticker läuft"
                            : "Keine Live‑Events aktiv",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        hasLive
                            ? "Adlerschießen jetzt live verfolgen"
                            : "Aktuell finden keine Live‑Events statt",
                        style: TextStyle(
                          color: subColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                //--------------------------------------------------
                // BADGE
                //--------------------------------------------------
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasLive
                        ? Colors.red.shade700
                        : Colors.grey.shade500,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasLive ? "LIVE" : "INFO",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  },
),

              //--------------------------------------------------
              // NEWS
              //--------------------------------------------------
              ...filteredDocs.map((doc) {

                final data = doc.data() as Map<String, dynamic>;

                // ✅ LIVE EVENT
                if (data['type'] == 'liveEvent') {
                  final rawUpdates = List.from(data['updates'] ?? []);

                  final updates = rawUpdates.map<Map<String, dynamic>>((u) {
                    if (u is Map<String, dynamic>) return u;
                    return {"text": u.toString(), "time": null};
                  }).toList();

                  final isActive = data['isActive'] == true;
                  final expanded = _expandedLiveEvents.contains(doc.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isActive
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.whatshot,
                            color: isActive ? Colors.red : Colors.green,
                          ),
                          title: Text(
                            "${data['location']} – Adlerschießen",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isActive ? Colors.red : Colors.green,
                            ),
                          ),
                          subtitle: Text(
                            isActive
                                ? "🔴 Live‑Ticker aktiv – Treffer in Echtzeit"
                                : "✅ Event beendet – Ergebnisse vollständig",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  isActive ? Colors.red : Colors.green,
                            ),
                          ),
                          trailing: Icon(
                            expanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: isActive ? Colors.red : Colors.green,
                          ),
                          onTap: () {
                            setState(() {
                              expanded
                                  ? _expandedLiveEvents.remove(doc.id)
                                  : _expandedLiveEvents.add(doc.id);
                            });
                          },
                        ),

                        if (expanded)
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 20),

                                ...updates.map((u) {
                                  final text = u['text'] ?? '';
                                  final time = DateTime.tryParse(
                                      u['time'] ?? '');
                                  final isKing =
                                      text.contains("👑");

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            text,
                                            style: TextStyle(
                                              fontWeight: isKing
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isKing
                                                  ? Colors.amber.shade800
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (time != null)
                                          Text(
                                            _formatTime(time),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }

                // ✅ NORMALE NEWS
                final news = NewsItem.fromMap(data);
                final important = data['isImportant'] == true;

                return Card(
                  color: important
                      ? Colors.amber.shade50
                      : null,
                  child: ListTile(
                    title: Text(
                      news.title,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${_formatDate(news.date)}\n${news.text}",
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
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.green : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}