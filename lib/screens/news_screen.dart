import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/news.dart';
import 'adler_live_screen.dart';
import '../screens/contact_screen.dart';
import 'submit_news_screen.dart';


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
      Icon(Icons.radar, color: Colors.white, size: 35),
      SizedBox(width: 8),
      Text(
        "News",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 30,
          letterSpacing: 0.4,
        ),
      ),
    ],
  ),


),


      floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubmitNewsScreen(),
      ),
    );
  },
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
  final isLiveEvent = data['type'] == 'liveEvent';
  final isActive = data['isActive'] == true;





  //--------------------------------------------------
  // ✅ LIVE EVENTS NUR WENN AKTIV
  //--------------------------------------------------
  if (isLiveEvent && !isActive) {
    return false;
  }

  //--------------------------------------------------
  // 🔥 HIGHLIGHTS
  //--------------------------------------------------
  if (selectedFilter == "highlights") {
    final isKingSet =
        (data['kingName'] != null &&
         data['kingName'].toString().isNotEmpty);

    return data['isImportant'] == true || isKingSet;
  }

  //--------------------------------------------------
  // ⚡ LIVE FILTER
  //--------------------------------------------------
  if (selectedFilter == "live") {
    return isLiveEvent;
  }

  //--------------------------------------------------
  // ✅ STANDARD
  //--------------------------------------------------
  return true;

}).toList();

//--------------------------------------------------
// ✅ SORTIERUNG (NEUSTE ZUERST)
//--------------------------------------------------
final sortedDocs = filteredDocs
  ..sort((a, b) {
    final da = NewsItem.fromMap(a.data() as Map<String, dynamic>).date;
    final db = NewsItem.fromMap(b.data() as Map<String, dynamic>).date;

    return db.compareTo(da);
  });



          return ListView(
            padding: const EdgeInsets.all(12),
            children: [

if (_showInfo)
  Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: theme.brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Icon(Icons.sensors, size: 22, color: Colors.green),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Willkommen & danke, dass du SchützenRadar nutzt! 🙌",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const Text(
                "🦅 Adlerschießen eintragen & live verfolgen\n"
                "👑 Jungkönig & Altkönig in Echtzeit\n"
                "📅 Alle Schützenfeste im Kreis + Infos\n"
                "📢 News & Highlights rund ums Fest",
                style: TextStyle(height: 1.35),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContactScreen(),
                    ),
                  );
                },
                child: const Text(
                  "💬 Fehlt eine Veranstaltung oder ist dir etwas aufgefallen?\n"
                  "→ Schau gern auf die Kontaktseite – ich freue mich auf deine Nachricht 😊",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),

        GestureDetector(
          onTap: _hideInfo,
          child: const Padding(
            padding: EdgeInsets.only(left: 6, top: 2),
            child: Icon(Icons.close, size: 18, color: Colors.grey),
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 12),

//--------------------------------------------------
// ✅ FILTER (IMMER SICHTBAR!)
//--------------------------------------------------
Wrap(
  alignment: WrapAlignment.center,
  spacing: 8,
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
            onTap: hasLive ? _openLiveSelection : null,

            child: Row(
              children: [

                Icon(
                  hasLive ? Icons.visibility : Icons.info_outline,
                  color: textColor,
                  size: 28,
                ),

                const SizedBox(width: 12),

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

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2, vertical: 1),
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
    // ✅ NEWS LISTE
    //--------------------------------------------------
    ...sortedDocs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      //--------------------------------------------------
      // ✅ LIVE EVENT
      //--------------------------------------------------
     if (data['type'] == 'liveEvent') {
final docId = doc.id;
final expanded = _expandedLiveEvents.contains(docId);



  final isActive = data['isActive'] == true;
  final locationId = (data['locationId'] ?? "").toString();

  if (locationId.isEmpty) {
    return const SizedBox();
  }

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    
color: isActive
    ? (theme.brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)   // 🔥 dunkles Grau
        : Colors.orange.shade50)
    : (theme.brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)   // 🔥 Standard Dark Card
        : Colors.grey.shade200),


    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        //--------------------------------------------------
        // ✅ HEADER
        //--------------------------------------------------
        ListTile(
  onTap: () {
    setState(() {
      expanded
  ? _expandedLiveEvents.remove(docId)
  : _expandedLiveEvents.add(docId);

    });
  },

  trailing: Icon(
    expanded ? Icons.expand_less : Icons.expand_more,
  ),
          leading: Icon(
            Icons.whatshot,
            color: isActive ? Colors.orange : Colors.grey,
          ),

          title: Text(
            "${data['location'] ?? "Unbekannt"} – Adlerschießen",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          subtitle: Text(
            isActive
                ? "🟠 Live‑Ticker aktiv"
                : "Keine Live‑Events aktiv",
          ),
        ),

        //--------------------------------------------------
        // 🔥 LIVE TREFFER
        //--------------------------------------------------

//--------------------------------------------------
// 🔥 LIVE TREFFER (KORREKT)
//--------------------------------------------------


...(isActive && expanded
    ? [

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

          

              //--------------------------------------
              // 🧒 JUNGKÖNIG
              //--------------------------------------
              Text(
  "🧒 Jungkönig",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.orange.shade300
        : Colors.orange,
  ),
),
              const SizedBox(height: 6),

              ..._buildLiveHits(locationId, "jung"),

              const SizedBox(height: 12),

              //--------------------------------------
              // 👑 ALTKÖNIG
              //--------------------------------------
              const Text(
                "👑 Altkönig",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),

              const SizedBox(height: 6),

              ..._buildLiveHits(locationId, "alt"),
            ],
          ),
        ),
      ]
    : []),

],
    ),
  );
}

    



//--------------------------------------------------
// ✅ NORMALE NEWS
//--------------------------------------------------

final news = NewsItem.fromMap(data);
//final important = data['isImportant'] == true;


return Card(
  margin: const EdgeInsets.only(bottom: 12),
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: BorderSide(
      color: Colors.black.withValues(alpha:0.08),
      width: 1,
    ),
  ),
  color: Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF242424)
      : Colors.white,


  child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        //--------------------------------------------------
        // ✅ TITEL + DATUM
        //--------------------------------------------------
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                news.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Text(
              _formatDate(news.date),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        //--------------------------------------------------
        // ✅ ORT
        //--------------------------------------------------
        if ((data['location'] ?? '').toString().isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data['location'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),

        //--------------------------------------------------
        // ✅ TEXT
        //--------------------------------------------------
        Text(
          news.text,
          style: const TextStyle(
            height: 1.4,
            fontSize: 14,
          ),
        ),
      ],
    ),
  ),
);

    }).toList(),


  ],
); // ✅ ListView

}, // ✅ StreamBuilder builder

), // ✅ StreamBuilder

); // ✅ Scaffold  ← DAS HAT DIR GEFEHLT

} //



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

//--------------------------------------------------
// ✅ LIVE TREFFER DIREKT AUS FIREBASE (VERBESSERT)
//--------------------------------------------------
List<Widget> _buildLiveHits(String locationId, String eventType) {
  if (locationId.trim().isEmpty) {
    return [];
  }

  return [
    StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('adler_events')
          .doc(locationId)
          .collection('events')
          .doc(eventType)
          .snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final raw = snapshot.data!.data();

        if (raw == null || raw is! Map) {
          return const SizedBox();
        }

        final data = Map<String, dynamic>.from(raw);

        final results = data['results'] is Map
            ? Map<String, dynamic>.from(data['results'])
            : {};

        final king = (data['kingName'] ?? "").toString();
        final shots = data['shots'] ?? 0;

        final sorted = results.entries.toList()
          ..sort((a, b) =>
              ((a.value is Map ? a.value['order'] : 0) ?? 0)
                  .compareTo((b.value is Map ? b.value['order'] : 0) ?? 0));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //--------------------------------------------------
            // ✅ TREFFER (JETZT SCHÖN LESBAR)
            //--------------------------------------------------
            ...sorted.map((e) {

              final r = e.value is Map ? e.value : {};
              final partShots = r['shots'] ?? "-";

              String time = "--:--";
              if (r['time'] != null && r['time'].toString().isNotEmpty) {
                final parsed = DateTime.tryParse(r['time'].toString());
                if (parsed != null) {
                  time = _formatTime(parsed);
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 18),

                    const SizedBox(width: 8),

                    //--------------------------------------------------
                    // TEXT BLOCK (JETZT MEHR ZEILEN)
                    //--------------------------------------------------
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          
Text(
  e.key.toString(),
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.orange.shade300
        : Colors.black,
  ),
),


                          const SizedBox(height: 2),

                          Text(
                            
 (r['name'] ?? "-").toString(),
  style: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black,

  ),
)
,

                          const SizedBox(height: 2),

                          Text(
                            "$partShots Schuss",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    //--------------------------------------------------
                    // UHRZEIT RECHTS
                    //--------------------------------------------------
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),

            //--------------------------------------------------
            // ✅ KÖNIG (MEHR HERVORGEHOBEN)
            //--------------------------------------------------
            if (king != "")
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "👑 $king ($shots Schuss)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    )
  ];
}

//--------------------------------------------------
// ✅ LIVE UPDATES AUS NEWS (CRASH-SAFE)
//--------------------------------------------------
List<Widget> _buildNewsUpdates(Map<String, dynamic> data) {

  final updatesRaw = data['updates'];

  if (updatesRaw is! List) return [];

  return updatesRaw.map<Widget>((item) {

    final u = item is Map ? Map<String, dynamic>.from(item) : {};

    //--------------------------------------------------
    // ✅ ALTES FORMAT (text)
    //--------------------------------------------------
    if (u.containsKey('text')) {

      String time = "--:--";
      if (u['time'] != null) {
        final parsed = DateTime.tryParse(u['time'].toString());
        if (parsed != null) {
          time = _formatTime(parsed);
        }
      }

      return ListTile(
        leading: const Icon(Icons.flash_on, color: Colors.orange),
        title: Text(u['text'].toString()),
        trailing: Text(time),
      );
    }

    //--------------------------------------------------
    // ✅ NEUES FORMAT (name + shots)
    //--------------------------------------------------
    final name = (u['name'] ?? "-").toString();
    final shots = (u['shots'] ?? "-").toString();

    String time = "--:--";
    if (u['time'] != null) {
      final parsed = DateTime.tryParse(u['time'].toString());
      if (parsed != null) {
        time = _formatTime(parsed);
      }
    }

    return ListTile(
      leading: const Icon(Icons.check_circle, color: Colors.green),
      title: Text(name),
      subtitle: Text("$shots Schuss"),
      trailing: Text(time),
    );

  }).toList();
}

}
