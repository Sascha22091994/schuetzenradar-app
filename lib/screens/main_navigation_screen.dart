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

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {

  int _currentIndex = 1;
  int _usageCount = 0;
  bool _supportShown = false;

  //--------------------------------------------------
  // ❤️ PULSE ANIMATION
  //--------------------------------------------------
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
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
            Text(
              "Mit SchützenRadar findest du schnell die besten Schützenfeste 🎯",
            ),
            SizedBox(height: 12),
            Text(
              "Die App wird kontinuierlich weiterentwickelt und verbessert.",
            ),
            SizedBox(height: 12),
            Text(
              "👉 Wenn du das Projekt unterstützen möchtest, freue ich mich über deinen Support.",
            ),
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
            onPressed: () => Navigator.pop(context),
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
    );
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
        return const MiscScreen();
      default:
        return const HomeScreen();
    }
  }

  //--------------------------------------------------
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);

        _usageCount++;
        if (_usageCount >= 4 && !_supportShown) {
          _supportShown = true;
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _openSupportDialog();
          });
        }
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
      body: Stack(
        children: [

          _buildPage(),

          //--------------------------------------------------
          // ❤️ PULSIERENDER SUPPORT BUTTON
          //--------------------------------------------------
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: (_usageCount >= 2)
                ? MediaQuery.of(context).padding.top + 10
                : -80,
            right: 12,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: (_usageCount >= 2) ? 1 : 0,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: GestureDetector(
                  onTap: _openSupportDialog,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha:0.4),
                          blurRadius: 12,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      //--------------------------------------------------
      // ✅ CLEAN NAV
      //--------------------------------------------------
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.article_outlined, "News"),
              _buildNavItem(1, Icons.calendar_today_outlined, "Termine"),
              _buildNavItem(2, Icons.home_outlined, "Orte"),
              _buildMoreButton(),
            ],
          ),
        ),
      ),
    );
  }
}
