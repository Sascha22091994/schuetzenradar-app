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

  //--------------------------------------------------
  // ✅ FILTER
  //--------------------------------------------------
  String selectedFilter = "all";

  //--------------------------------------------------
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
  // ✅ ADD NEWS
  //--------------------------------------------------
  void _showAddNewsDialog() {
    final title = TextEditingController();
    final content = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Neue News"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: "Titel"),
            ),
            TextField(
              controller: content,
              decoration: const InputDecoration(labelText: "Text"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('news').add({
                "title": title.text,
                "content": content.text,
                "date": DateTime.now().toIso8601String(),
                "type": "highlight",
                "isImportant": true,
              });

              Navigator.pop(context);
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  // ✅ EDIT NEWS
  //--------------------------------------------------
  void _editNews(String id, NewsItem news) {
    final title = TextEditingController(text: news.title);
    final content = TextEditingController(text: news.text);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("News bearbeiten"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: "Titel"),
            ),
            TextField(
              controller: content,
              decoration: const InputDecoration(labelText: "Text"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('news')
                  .doc(id)
                  .update({
                "title": title.text,
                "content": content.text,
              });

              Navigator.pop(context);
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );
  }

  // 🔽 NUR DIESE METHODE WURDE ANGEPASST
//--------------------------------------------------
// ✅ LIVE AUSWAHL
//--------------------------------------------------
Future<void> _openLiveSelection() async {

  final locationsSnapshot =
      await FirebaseFirestore.instance.collection('locations').get();

  final adlerSnapshot =
      await FirebaseFirestore.instance.collection('adler_events').get();

  Map<String, bool> activeMap = {};

  for (var doc in adlerSnapshot.docs) {
    final data = doc.data();

    if (data['results'] != null &&
        (data['results'] as Map).isNotEmpty) {
      activeMap[doc.id] = true;
    }
  }

  //--------------------------------------------------
  // ✅ SORTIERUNG LIVE OBEN
  //--------------------------------------------------
  final docs = locationsSnapshot.docs;

  final activeDocs =
      docs.where((doc) => activeMap[doc.id] == true).toList();

  final inactiveDocs =
      docs.where((doc) => activeMap[doc.id] != true).toList();

  final sortedDocs = [
    ...activeDocs,
    ...inactiveDocs,
  ];

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Ort auswählen"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          children: [

            //--------------------------------------------------
            // ✅ HEADER (OPTIONAL)
            //--------------------------------------------------
            if (activeDocs.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  "🔴 LIVE AKTUELL",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            //--------------------------------------------------
            // ✅ LISTE
            //--------------------------------------------------
            ...sortedDocs.map((doc) {

              final name = doc['name'] ?? "";
              final isActive = activeMap[doc.id] == true;

              return Card(
                color: isActive ? Colors.green.shade50 : null,
                child: ListTile(
                  title: Text(name),
                  subtitle: isActive
                      ? const Text("🔥 Live aktiv")
                      : const Text("Keine aktuellen Daten"),
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdlerLiveScreen(
                          locationId: doc.id,
                          locationName: name,
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
      // ✅ FAB
      //--------------------------------------------------
      floatingActionButton: AdminService.isAdmin
          ? FloatingActionButton(
              onPressed: _showAddNewsDialog,
              child: const Icon(Icons.add),
            )
          : FloatingActionButton.extended(
              onPressed: () => EmailService.sendFeedback(),
              icon: const Icon(Icons.add),
              label: const Text("News melden"),
            ),

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
          final docs = allDocs.where((doc) {
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

              if (_showInfo)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      const Text(
                        '🚀 Community News Plattform\n\n✔ Infos\n✔ Live Updates\n✔ Highlights',
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
              // LIVE BUTTON
              //--------------------------------------------------
           FutureBuilder<QuerySnapshot>(
  future: FirebaseFirestore.instance
      .collection('adler_events')
      .get(),
  builder: (context, snapshot) {

    bool hasLive = false;

    if (snapshot.hasData) {
      for (var doc in snapshot.data!.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['results'] != null &&
            (data['results'] as Map).isNotEmpty) {
          hasLive = true;
          break;
        }
      }
    }

    return Card(
      color: hasLive ? Colors.red.shade100 : null,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.visibility,
          color: hasLive ? Colors.red : Colors.grey,
        ),
        title: Row(
          children: [
            Text(
              "Adlerschießen verfolgen",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hasLive ? Colors.red : Colors.black,
              ),
            ),

            //--------------------------------------------------
            // ✅ LIVE BADGE
            //--------------------------------------------------
            if (hasLive)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "LIVE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          hasLive
              ? "🔥 Gerade aktiv!"
              : "Momentan kein Live Event",
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _openLiveSelection,
      ),
    );
  },
),

              //--------------------------------------------------
              // ✅ NEWS LIST
              //--------------------------------------------------
              ...docs.map((doc) {

                final news = NewsItem.fromMap(
                    doc.data() as Map<String, dynamic>);

                final important = (doc.data()
                        as Map<String, dynamic>)['isImportant'] ==
                    true;

                return Dismissible(
                  key: Key(doc.id),
                  direction: AdminService.isAdmin
                      ? DismissDirection.endToStart
                      : DismissDirection.none,

                  confirmDismiss: (_) async {
  return await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Löschen?"),
      content: const Text("Bist du sicher?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text("Abbrechen"),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text("Löschen"),
        ),
      ],
    ),
  );
},

onDismissed: (_) async {
  await FirebaseFirestore.instance
      .collection('news')
      .doc(doc.id)
      .delete();
},

                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete,
                        color: Colors.white),
                  ),

                  child: GestureDetector(
                    onLongPress: () {
                      if (AdminService.isAdmin) {
                        _editNews(doc.id, news);
                      }
                    },

                    child: Card(
                      color:
                          important ? Colors.amber.shade50 : null,
                      child: ListTile(
                        title: Text(news.title),
                        subtitle: Text(
                          "${_formatDate(news.date)}\n${news.text}",
                        ),
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

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.green : Colors.grey.shade200,
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
