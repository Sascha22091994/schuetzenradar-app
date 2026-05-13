import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/favorite_service.dart';

//--------------------------------------------------
// ✅ GLOBAL THEME CONTROLLER (FIXED)
//--------------------------------------------------
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.light); // ✅ KEIN system mehr!

//--------------------------------------------------
// ✅ ROBUSTER TOGGLE (1 CLICK FIX)
//--------------------------------------------------
void toggleTheme() {
  final current = themeNotifier.value;

  if (current == ThemeMode.dark) {
    themeNotifier.value = ThemeMode.light;
  } else {
    themeNotifier.value = ThemeMode.dark;
  }
}

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      //--------------------------------------------------
      // ✅ FIREBASE INIT
      //--------------------------------------------------
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      //--------------------------------------------------
      // ✅ CRASHLYTICS
      //--------------------------------------------------
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      //--------------------------------------------------
      // ✅ SERVICES
      //--------------------------------------------------
      await FavoriteService.loadFavorites();

      runApp(const MyApp());
    },
    (error, stack) {
      FirebaseCrashlytics.instance
          .recordError(error, stack, fatal: true);
    },
  );
}

//--------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {

        final theme = mode == ThemeMode.dark
            ? _buildDarkTheme()
            : _buildLightTheme();

        return AnimatedTheme(
          data: theme,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,

          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SchützenRadar',

            themeMode: mode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),

            scrollBehavior: const MaterialScrollBehavior().copyWith(
              overscroll: false,
            ),

            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}

//--------------------------------------------------
// ✅ LIGHT THEME
//--------------------------------------------------
ThemeData _buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    listTileTheme: const ListTileThemeData(
      textColor: Colors.black87,
      iconColor: Colors.grey,
    ),

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

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      prefixIconColor: Colors.grey,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

//--------------------------------------------------
// ✅ DARK THEME
//--------------------------------------------------
ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      elevation: 3,
      color: const Color(0xFF222222),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    listTileTheme: const ListTileThemeData(
      textColor: Colors.white,
      iconColor: Colors.white70,
    ),

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

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      hintStyle: const TextStyle(color: Colors.white54),
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIconColor: Colors.white70,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}