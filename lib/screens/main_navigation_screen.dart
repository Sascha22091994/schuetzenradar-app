import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'news_screen.dart';
import 'contact_screen.dart';
import 'misc_screen.dart';
import '../main.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {

  int _currentIndex = 1;

  final List<Widget> _pages = const [
    NewsScreen(),
    HomeScreen(),
    ContactScreen(),
    MiscScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

        //--------------------------------------------------
        // ✅ FIXED TOGGLE (1 CLICK)
        //--------------------------------------------------
        onTap: (index) {

          if (index == 4) {
            toggleTheme(); // ✅ sauberer Wechsel
            return;
          }

          setState(() => _currentIndex = index);
        },

        //--------------------------------------------------
        // ✅ ITEMS (MIT DYNAMIC ICON)
        //--------------------------------------------------
        items: [

          const BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'News',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Termine',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.sports_martial_arts),
            label: 'Kontakt',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Sonstiges',
          ),

          //--------------------------------------------------
          // ✅ DYNAMIC THEME ICON
          //--------------------------------------------------
          BottomNavigationBarItem(
            icon: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, _) {
                return Icon(
                  mode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                );
              },
            ),
            label: 'Modus',
          ),
        ],
      ),
    );
  }
}