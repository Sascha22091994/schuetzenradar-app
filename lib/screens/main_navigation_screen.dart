import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_screen.dart';
import 'news_screen.dart';
import 'contact_screen.dart';
import 'misc_screen.dart';
import '../main.dart';
import 'archiv_screen.dart';


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
      
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {

  int _currentIndex = 1;
  
  int _usageCount = 0;
  bool _supportShown = false;

  

  //--------------------------------------------------
  // ✅ WEBSITE öffnen
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
  // ✅ SUPPORT DIALOG
  //--------------------------------------------------
void _openSupportDialog() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: const Text("🍺 Gefällt dir SchützenRadar?"),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [

          Text(
            "Mit SchützenRadar findest du schnell die nächsten Feste 🎯",
          ),
          SizedBox(height: 12),

          Text(
            "Die App entsteht komplett in meiner Freizeit 💪",
          ),
          SizedBox(height: 12),

          Text(
            "👉 Wenn sie dir hilft, kannst du mich gerne "
            "auf ein Bier einladen 🍺",
          ),

          SizedBox(height: 16),

          // ✅ SOCIAL PROOF
          Text(
            "Schon einige Nutzer unterstützen das Projekt 🙌",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),

      actions: [
        TextButton(
          child: const Text("Später"),
          onPressed: () => Navigator.pop(context),
        ),

        // ✅ HAUPT-AKTION
        ElevatedButton(
          child: const Text("🍺 Unterstützen"),
          onPressed: () async {
            Navigator.pop(context);

            await _openWebsite();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "💛 Danke dir! Du bist jetzt Supporter 🍺",
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
    ),
  );
}


  //--------------------------------------------------
  // ✅ MEHR MENÜ
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

          //--------------------------------------------------
          // 🌙 / ☀️ THEME SWITCH (OBEN)
          //--------------------------------------------------
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

          //--------------------------------------------------
          // 📬 KONTAKT
          //--------------------------------------------------
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

          //--------------------------------------------------
          // 🗂️ ARCHIV
          //--------------------------------------------------
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

          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

  //--------------------------------------------------
  // ✅ PAGE SWITCH (FIX für Orte!)
  //--------------------------------------------------
  Widget _buildPage() {
    switch (_currentIndex) {

      case 0:
        return const NewsScreen();

      case 1:
        return const HomeScreen(); // Termine

      case 2:
        return const MiscScreen(); // ✅ ORTE FIX

      default:
        return const HomeScreen();
    }
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      //--------------------------------------------------
      // ✅ BODY
      //--------------------------------------------------
      body: _buildPage(),

      //--------------------------------------------------
      // ✅ NAVIGATION
      //--------------------------------------------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

       onTap: (index) {

  //--------------------------------------------------
  // 🔥 SUPPORT BUTTON
  //--------------------------------------------------
  if (index == 3) {
    _openSupportDialog();
    return;
  }

  //--------------------------------------------------
  // ⋯ MEHR
  //--------------------------------------------------
  if (index == 4) {
    _showMoreMenu();
    return;
  }

  //--------------------------------------------------
  // NORMAL NAV
  //--------------------------------------------------
  setState(() => _currentIndex = index);

  //--------------------------------------------------
  // ✅ USAGE TRACKING + SMART TRIGGER
  //--------------------------------------------------
  _usageCount++;

  if (_usageCount >= 5 && !_supportShown) {
    _supportShown = true;

    // kleiner Delay → fühlt sich natürlicher an
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _openSupportDialog();
      }
    });
  }
},


        //--------------------------------------------------
        // ✅ ITEMS
        //--------------------------------------------------
        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: 'News',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Termine',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Orte',
          ),

          //--------------------------------------------------
          // 🔥 SUPPORT
          //--------------------------------------------------
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.local_fire_department_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            label: '💚App unterstützen💚',
          ),

          //--------------------------------------------------
          // ⋯ MEHR
          //--------------------------------------------------
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Mehr',
          ),
        ],
      ),
    );
  }
}
