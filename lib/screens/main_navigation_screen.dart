import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_screen.dart';
import 'news_screen.dart';
import 'contact_screen.dart';
import 'misc_screen.dart';
import '../main.dart';
import 'archiv_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adler_live_screen.dart';
import 'live_view_screen.dart';


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {

  int _currentIndex = 1;
late Stream<bool> _liveStatusStream;
bool _isActive = true;

//--------------------------------------------------
// ✅ LIVE CHECK GLOBAL
//--------------------------------------------------
Stream<bool> _liveStream() async* {

  while (_isActive) {

    final locations =
        await FirebaseFirestore.instance.collection('locations').get();

    bool hasLive = false;

    for (final doc in locations.docs) {
      final jung = await FirebaseFirestore.instance
          .collection('adler_events')
          .doc(doc.id)
          .collection('events')
          .doc('jung')
          .get();

      final alt = await FirebaseFirestore.instance
          .collection('adler_events')
          .doc(doc.id)
          .collection('events')
          .doc('alt')
          .get();

      if (jung.data()?['isActive'] == true ||
          alt.data()?['isActive'] == true) {
        hasLive = true;
        break;
      }
    }

    yield hasLive;

    await Future.delayed(const Duration(seconds: 10));
  }
}


//--------------------------------------------------
// ✅ LIVE ORT AUSWAHL
//--------------------------------------------------
Future<void> _openLiveSelection() async {
  final locationsSnapshot =
      await FirebaseFirestore.instance.collection('locations').get();

  // ✅ Status für jeden Ort holen
  final futures = locationsSnapshot.docs.map((doc) async {

    final jung = await FirebaseFirestore.instance
        .collection('adler_events')
        .doc(doc.id)
        .collection('events')
        .doc('jung')
        .get();

    final alt = await FirebaseFirestore.instance
        .collection('adler_events')
        .doc(doc.id)
        .collection('events')
        .doc('alt')
        .get();

    final isLive =
        (jung.data()?['isActive'] == true) ||
        (alt.data()?['isActive'] == true);

    return MapEntry(doc, isLive);
  });

  final results = await Future.wait(futures);

  // ✅ Map bauen
  final map = Map.fromEntries(results);

  // ✅ SORTIERUNG → zuerst LIVE
  final sorted = [
    ...map.entries.where((e) => e.value == true),
    ...map.entries.where((e) => e.value != true),
  ];

  //--------------------------------------------------
  // ✅ DIALOG
  //--------------------------------------------------
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Ort auswählen"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          children: sorted.map((entry) {

            final doc = entry.key;
            final isLive = entry.value;

            return ListTile(
              title: Text(doc['name'] ?? ""),


              // 🔥 DAS IST DER WICHTIGE TEIL
              subtitle: Text(
                isLive
                    ? "🔥 Live aktiv"
                    : "Keine aktuellen Daten",
              ),

              leading: Icon(
                Icons.circle,
                size: 10,
                color: isLive ? Colors.red : Colors.grey,
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


  //--------------------------------------------------
  // ❤️ PULSE ANIMATION
  //--------------------------------------------------
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

@override
void initState() {
  super.initState();

  _maybeShowSupport();

  _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
    CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ),
  );

  // ✅ WICHTIG: Stream nur einmal starten
  _liveStatusStream = _liveStream();
}



 @override
void dispose() {
  _isActive = false;
  _pulseController.dispose();
  super.dispose();
}


  //--------------------------------------------------
  Future<void> _openWebsite() async {
    final url = Uri.parse(
        "https://sascha22091994.github.io/schuetzenradar-legal/");

    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  //--------------------------------------------------
void _openSupportDialog() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: const Text("Gefällt dir SchützenRadar? 💛"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Mit SchützenRadar findest du schnell die besten Schützenfeste 🎯"),
          SizedBox(height: 12),
          Text("Die App wird kontinuierlich weiterentwickelt und verbessert."),
          SizedBox(height: 12),
          Text("👉 Wenn du das Projekt unterstützen möchtest, freue ich mich über deinen Support."),
          SizedBox(height: 16),
          Text(
            "So hilfst du, neue Features und Updates möglich zu machen 🙌",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [

        TextButton(
          child: const Text("Später"),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        TextButton(
          child: const Text("Nicht mehr anzeigen"),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool("supportDisabled", true);

            Navigator.pop(context);
          },
        ),

        ElevatedButton(
          child: const Text("Unterstützen 💛"),
          onPressed: () async {
            Navigator.pop(context);
            await _openWebsite();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("💛 Vielen Dank für deine Unterstützung!"),
                ),
              );
            }
          },
        ),
      ],
    ),
  ); // ✅ DAS HAT GEFEHLT
}


Future<void> _maybeShowSupport() async {
  final prefs = await SharedPreferences.getInstance();

  final disabled = prefs.getBool("supportDisabled") ?? false;

  if (!disabled) {
    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      _openSupportDialog();
    }
  }
}


  //--------------------------------------------------
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ListTile(
              leading: Icon(
                themeNotifier.value == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              title: Text(
                themeNotifier.value == ThemeMode.dark
                    ? "Zu Hell wechseln"
                    : "Zu Dunkel wechseln",
              ),
              onTap: () {
                Navigator.pop(context);
                toggleTheme();
              },

              
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.contact_mail_outlined),
              title: const Text("Kontakt"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ContactScreen(),
                  ),
                );
              },
            ),
ListTile(
  leading: const Text("🍺", style: TextStyle(fontSize: 20)),
  title: const Text("Support"),
  onTap: () {
    Navigator.pop(context);
    _openSupportDialog();
  },
),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text("Archiv (Adlerschießen)"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ArchivScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  //--------------------------------------------------

Widget _buildPage() {
  switch (_currentIndex) {
    case 0:
      return const NewsScreen();
    case 1:
      return const HomeScreen();
    case 2:
      return const LiveViewScreen(); // ✅ NEU
    case 3:
      return const MiscScreen();
    default:
      return const HomeScreen();
  }
}


  //--------------------------------------------------
 

 Widget _buildNavItem(int index, IconData icon, String label) {
  final isActive = _currentIndex == index;

  //--------------------------------------------------
  // 🔴 LIVE SPECIAL
  //--------------------------------------------------
  if (index == 2) {
    return StreamBuilder<bool>(
      stream: _liveStatusStream,
      builder: (context, snapshot) {
        final hasLive = snapshot.data == true;

        return InkWell(
          onTap: () {
            setState(() => _currentIndex = index);
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isActive ? 1.2 : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                //--------------------------------------------------
                // 🔴 ICON (WIRD ROT)
                //--------------------------------------------------
                Icon(
                  icon,
                  color: hasLive
                      ? Colors.red // 🔥 LIVE → ROT
                      : (isActive
                          ? const Color(0xFF2E7D32)
                          : Colors.grey),
                ),

                const SizedBox(height: 4),

                //--------------------------------------------------
                // 🔴 TEXT BLINKT
                //--------------------------------------------------
                hasLive
                    ? FadeTransition(
                        opacity: _pulseAnimation, // 🔥 BLINK EFFECT
                        child: const Text(
                          "LIVE",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: isActive
                              ? const Color(0xFF2E7D32)
                              : Colors.grey,
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  //--------------------------------------------------
  // ✅ STANDARD NAV ITEM
  //--------------------------------------------------
  return InkWell(
    onTap: () {
      setState(() => _currentIndex = index);
    },
    child: AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: isActive ? 1.2 : 1.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive
                ? const Color(0xFF2E7D32)
                : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive
                  ? const Color(0xFF2E7D32)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}



  Widget _buildMoreButton() {
    return InkWell(
      onTap: _showMoreMenu,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.more_horiz),
          SizedBox(height: 4),
          Text("Mehr", style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  //--------------------------------------------------
@override
Widget build(BuildContext context) {
  return Scaffold(

    //--------------------------------------------------
    // ✅ BODY
    //--------------------------------------------------
    body: Stack(
      children: [

        _buildPage(),

Positioned(
  top: MediaQuery.of(context).padding.top + 12,
  right: 10, // 👈 weniger am Rand!
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [

Positioned(
  top: MediaQuery.of(context).padding.top + 10,
  right: 4, // 🔥 noch weiter nach rechts (fast am Rand)
  child: GestureDetector(
    onTap: _openSupportDialog,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: 16, // 🔥 breiter
        vertical: 12,   // 🔥 höher
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange,
          ],
        ),
        borderRadius: BorderRadius.circular(26), // etwas runder
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Text(
        "🍺 Support",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15, // 🔥 größer
        ),
      ),
    ),
  ),
),


    ],
  ),
),

      ],
    ),

    //--------------------------------------------------
    // ✅ NAV BAR
    //--------------------------------------------------
    bottomNavigationBar: BottomAppBar(
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.article_outlined, "News"),
            _buildNavItem(1, Icons.calendar_today_outlined, "Termine"),
            _buildNavItem(2, Icons.visibility, "Live"),
            _buildNavItem(3, Icons.home_outlined, "Orte"),
            _buildMoreButton(),
          ],
        ),
      ),
    ),
  );
}
    }