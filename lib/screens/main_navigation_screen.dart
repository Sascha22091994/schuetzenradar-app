import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_screen.dart';
import 'favorites_screen.dart';
import 'legal_screen.dart';

import 'home_screen.dart';
import 'contact_screen.dart';
import 'map_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  //--------------------------------------------------
  Future<void> _openWebsite() async {
    final uri = Uri.parse(
      "https://sascha22091994.github.io/ErlebnisRadar-legal/",
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  //--------------------------------------------------
  @override
  void initState() {
    super.initState();
    _maybeShowSupport();
  }

  //--------------------------------------------------
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
  void _openSupportDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Gefällt dir ErlebnisRadar?"),
        content: const Text(
          "ErlebnisRadar wird kontinuierlich weiterentwickelt.\n\n"
          "Wenn du das Projekt unterstützen möchtest, freue ich mich über deinen Support.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Später"),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool("supportDisabled", true);

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Nicht mehr anzeigen"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _openWebsite();
            },
            child: const Text("Unterstützen"),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text("Profil"),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),

            const Divider(height: 24),

            ListTile(
              leading: const Icon(Icons.mail_outline),
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
              leading: const Icon(
                Icons.favorite_outline,
                color: Color(0xFFEF4444),
              ),
              title: const Text("Support"),
              onTap: () {
                Navigator.pop(context);
                _openSupportDialog();
              },
            ),

            // ✅ NEU: Impressum & Datenschutz, verschoben aus dem Profil
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text("Impressum & Datenschutz"),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LegalScreen(),
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
        return const HomeScreen();
      case 1:
        return const MapScreen();
      case 2:
        return const FavoritesScreen();
      default:
        return const HomeScreen();
    }
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 3) {
            _showMoreMenu();
            return;
          }

          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: "Entdecken",
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: "Karte",
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: "Favoriten",
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: "Mehr",
          ),
        ],
      ),
    );
  }
}