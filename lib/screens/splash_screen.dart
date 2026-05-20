import 'dart:async';
import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';

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
Future<void> _navigate() async {
  await Future.delayed(const Duration(seconds: 2));

  if (!mounted) return;

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => const MainNavigationScreen(),
    ),
  );
}

  

  //--------------------------------------------------
  // BUILD
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