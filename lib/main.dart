import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/favorite_service.dart';

//--------------------------------------------------
// ✅ GLOBALER THEME SWITCH
//--------------------------------------------------
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.system);

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      //--------------------------------------------------
      // ✅ ALLES IN DERSSELBEN ZONE (FIX!)
      //--------------------------------------------------
      WidgetsFlutterBinding.ensureInitialized();

      //--------------------------------------------------
      // FIREBASE
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
      // SERVICES
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

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SchützenRadar',

          //--------------------------------------------------
          // ✅ THEME MODE
          //--------------------------------------------------
          themeMode: mode,

          //--------------------------------------------------
          // ✅ UX (kein Glow)
          //--------------------------------------------------
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            overscroll: false,
          ),

          //--------------------------------------------------
          // ✅ LIGHT THEME
          //--------------------------------------------------
          theme: ThemeData(
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

            textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.black87,
              displayColor: Colors.black87,
            ),
          ),

          //--------------------------------------------------
          // ✅ DARK THEME
          //--------------------------------------------------
          darkTheme: ThemeData(
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

            textTheme: ThemeData.dark().textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
          ),

          //--------------------------------------------------
          home: const SplashScreen(),
        );
      },
    );
  }
}