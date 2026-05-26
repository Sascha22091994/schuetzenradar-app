import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_navigation_screen.dart';
import 'onboarding_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  //--------------------------------------------------
  // ✅ NAVIGATION MIT ONBOARDING CHECK
  //--------------------------------------------------
  Future<void> _navigate() async {

    // Splash Zeit
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool("seenOnboarding") ?? false;

    if (!mounted) return;

    //--------------------------------------------------
    // ✅ ENTSCHEIDUNG
    //--------------------------------------------------
    if (seenOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
    }
  }

  //--------------------------------------------------
  // UI
  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          //--------------------------------------------------
          // ICON
          //--------------------------------------------------
          Center(
            child: Image.asset(
              'assets/icon.png',
              width: 120,
            ),
          ),

          const SizedBox(height: 30),

          //--------------------------------------------------
          // CLAIM
          //--------------------------------------------------
          const Text(
            "Schützenfeste in deiner Region",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 20),

          //--------------------------------------------------
          // LOADING TEXT
          //--------------------------------------------------
          const Text(
            "Lade Inhalte...",
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 20),

          //--------------------------------------------------
          // LOADING SPINNER
          //--------------------------------------------------
          const CircularProgressIndicator(
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}