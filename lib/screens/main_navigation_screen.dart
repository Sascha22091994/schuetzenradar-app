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

onTap: (index) {

  if (index == 4) {
    // ✅ DARK MODE SWITCH
    if (themeNotifier.value == ThemeMode.light) {
      themeNotifier.value = ThemeMode.dark;
    } else if (themeNotifier.value == ThemeMode.dark) {
      themeNotifier.value = ThemeMode.system;
    } else {
      themeNotifier.value = ThemeMode.light;
    }
    return;
  }

  setState(() => _currentIndex = index);
},

   items: const [
  BottomNavigationBarItem(
    icon: Icon(Icons.newspaper),
    label: 'News',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.event),
    label: 'Termine',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.sports_martial_arts),
    label: 'Kontakt',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.more_horiz),
    label: 'Sonstiges',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.dark_mode),
    label: 'Modus',
  ),
],

      ),
    );
  }
}
