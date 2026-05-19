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
      title: const Text("💛 Unterstützen"),
      content: const Text(


"SchützenRadar ist ein privates Projekt 🦅\n\n"
"Wenn sie dir gefällt,\n"
"freue ich mich über ein Bier 🍺\n\n"
"oder teile die App gerne mit deinen Freunden 📱\n\n"
"Danke für deinen Support 🙌"


      ),
      actions: [
        TextButton(
          child: const Text("Abbrechen"),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: const Text("Prost 🍺"),
          onPressed: () async {
            Navigator.pop(context);

            // ✅ WEBSITE öffnen
            await _openWebsite();

            // ✅ 🍺 SNACKBAR (danach anzeigen)
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🍺 Danke dir! Prost!"),
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
          // 🔥 SUPPORT (JETZT MIT DIALOG)
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
            label: 'Support',
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
