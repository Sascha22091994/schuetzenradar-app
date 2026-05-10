import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
//import 'screens/main_navigation_screen.dart';
import 'screens/splash_screen.dart';
import 'services/favorite_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //--------------------------------------------------
  // ✅ FIREBASE ZUERST
  //--------------------------------------------------
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //--------------------------------------------------
  // ✅ DANN SERVICES
  //--------------------------------------------------
  await FavoriteService.loadFavorites();

  runApp(const MyApp());
}

//--------------------------------------------------
// APP
//--------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Schützenfest App',

      //--------------------------------------------------
      // ✅ MODERNES THEME (STABIL!)
      //--------------------------------------------------
      theme: ThemeData(
        useMaterial3: true,

        //--------------------------------------------------
        // FARBEN
        //--------------------------------------------------
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),

        //--------------------------------------------------
        // HINTERGRUND
        //--------------------------------------------------
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),

        //--------------------------------------------------
        // APPBAR
        //--------------------------------------------------
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        //--------------------------------------------------
        // ✅ CARD THEME FIX (WICHTIG!)
        //--------------------------------------------------
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        //--------------------------------------------------
        // BUTTONS
        //--------------------------------------------------
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        //--------------------------------------------------
        // TEXTFIELD DESIGN
        //--------------------------------------------------
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          prefixIconColor: Colors.grey,

          contentPadding:
              const EdgeInsets.symmetric(vertical: 12),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF2E7D32),
              width: 2,
            ),
          ),
        ),
      ),

      //--------------------------------------------------
      // ✅ STARTSCREEN
      //--------------------------------------------------
      home: const SplashScreen(),
    );
  }
}