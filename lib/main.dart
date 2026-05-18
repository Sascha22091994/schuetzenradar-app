import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/favorite_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';



//--------------------------------------------------
// ✅ GLOBAL THEME CONTROLLER
//--------------------------------------------------
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.system);

//--------------------------------------------------
// ✅ ROBUSTER TOGGLE (FIXED)
//--------------------------------------------------

Future<void> toggleTheme() async {
  final prefs = await SharedPreferences.getInstance();

  ThemeMode newMode =
      themeNotifier.value == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;

  themeNotifier.value = newMode;
  await prefs.setString(
    'theme',
    newMode == ThemeMode.dark ? 'dark' : 'light',
  );
}


//--------------------------------------------------
// ✅ MAIN
//--------------------------------------------------
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
// ✅ THEME LADEN (NEU)
final prefs = await SharedPreferences.getInstance();
final savedTheme = prefs.getString('theme');

if (savedTheme == 'dark') {
  themeNotifier.value = ThemeMode.dark;
} else if (savedTheme == 'light') {
  themeNotifier.value = ThemeMode.light;
} else {
  themeNotifier.value = ThemeMode.system;
}


// ✅ HIER NEU
if (!kIsWeb) {
  final settings =
      await FirebaseMessaging.instance.requestPermission();

  debugPrint("Push Permission: ${settings.authorizationStatus}");

  final token = await FirebaseMessaging.instance.getToken();
  debugPrint("🔥 FCM Token: $token");

  //--------------------------------------------------
  // ✅ NEU: GLOBAL ADMIN TOPIC
  //--------------------------------------------------
  await FirebaseMessaging.instance.subscribeToTopic("all");
  debugPrint("📢 Subscribed to global topic: all");

  //--------------------------------------------------
  // ✅ PUSH IM VORDERGRUND
  //--------------------------------------------------
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("📩 Push erhalten:");
    debugPrint("Titel: ${message.notification?.title}");
    debugPrint("Text: ${message.notification?.body}");
  });
}
      

      //--------------------------------------------------
      // ✅ CRASHLYTICS SETUP (ERWEITERT)
      //--------------------------------------------------
//--------------------------------------------------
// ✅ CRASHLYTICS SETUP (FINAL BEST PRACTICE)
//--------------------------------------------------
if (!kIsWeb) {

  // Flutter Fehler
  FlutterError.onError =
      FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Async / native Fehler
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // optional aktivieren
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(true);
}

      //--------------------------------------------------
      // ✅ SERVICES (HIER WAR DEIN BUG ✅)
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
// ✅ APP
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

          themeMode: mode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),

          scrollBehavior: const MaterialScrollBehavior().copyWith(
            overscroll: false,
          ),

          home: const SplashScreen(),
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
