import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';
import 'firebase_options.dart';
import 'services/favorite_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_radius.dart';
import 'package:google_fonts/google_fonts.dart';

//--------------------------------------------------
// ✅ GLOBAL NAVIGATOR KEY
//--------------------------------------------------
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//--------------------------------------------------
// ✅ GLOBAL THEME CONTROLLER
//--------------------------------------------------
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.system);

//--------------------------------------------------
// ✅ ROBUSTER TOGGLE
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

// ✅ NEU: neben toggleTheme() ergänzen
Future<void> setThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();

  themeNotifier.value = mode;

  String value;
  switch (mode) {
    case ThemeMode.dark:
      value = 'dark';
      break;
    case ThemeMode.light:
      value = 'light';
      break;
    case ThemeMode.system:
      value = 'system';
      break;
  }

  await prefs.setString('theme', value);
}

//--------------------------------------------------
// ✅ MAIN
//--------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    //--------------------------------------------------
    // ✅ FIREBASE INIT
    //--------------------------------------------------
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    //--------------------------------------------------
    // ✅ THEME LADEN
    //--------------------------------------------------
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme');

    if (savedTheme == 'dark') {
      themeNotifier.value = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      themeNotifier.value = ThemeMode.light;
    } else {
      themeNotifier.value = ThemeMode.system;
    }

    //--------------------------------------------------
    // ✅ FAVORITES
    //--------------------------------------------------
    await FavoriteService.loadFavorites();

    //--------------------------------------------------
    // ✅ PUSH SETUP
    //--------------------------------------------------
    if (!kIsWeb) {
      try {
        final settings =
            await FirebaseMessaging.instance.requestPermission();

        debugPrint("Push Permission: ${settings.authorizationStatus}");

        final token = await FirebaseMessaging.instance.getToken();
        debugPrint("FCM Token: $token");

        await FirebaseMessaging.instance.subscribeToTopic("all");

        //--------------------------------------------------
        // ✅ PUSH IM VORDERGRUND ANZEIGEN
        //--------------------------------------------------
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {

          debugPrint("Push erhalten:");
          debugPrint("Titel: ${message.notification?.title}");
          debugPrint("Text: ${message.notification?.body}");

          final context = navigatorKey.currentContext;

          if (context == null) return;

          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              title: Text(message.notification?.title ?? "Neu"),
              content: Text(message.notification?.body ?? ""),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        });

      } catch (e) {
        debugPrint("Push Fehler: $e");
      }
    }

    //--------------------------------------------------
    // ✅ CRASHLYTICS
    //--------------------------------------------------
    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(true);
    }

    debugPrint("INIT FERTIG");

  } catch (e) {
    debugPrint("INIT ERROR: $e");
  }

  //--------------------------------------------------
  // ✅ APP START
  //--------------------------------------------------
  runApp(const MyApp());
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
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'ErlebnisRadar',

          //--------------------------------------------------
          // ✅ DEUTSCH GLOBAL
          //--------------------------------------------------
          locale: const Locale('de', 'DE'),
          supportedLocales: const [
            Locale('de', 'DE'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          themeMode: mode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),

          scrollBehavior: const MaterialScrollBehavior().copyWith(
            overscroll: false,
          ),

          home: const MainNavigationScreen(),
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

    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.cardLight,
      error: AppColors.danger,
    ),

    textTheme: GoogleFonts.interTextTheme(),
    scaffoldBackgroundColor: AppColors.backgroundLight,

    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide.none,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
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

    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.cardDark,
      error: AppColors.danger,
    ),

    scaffoldBackgroundColor: AppColors.backgroundDark,

    // ✅ ANGEPASST: Inter-Font auf Flutters DUNKLES Typography-Schema
    // aufbauen (statt implizit auf das helle) – dadurch bekommen ALLE
    // Textstile (bodyMedium, titleLarge, etc.) automatisch die korrekte,
    // helle Farbe im Dark Mode, ohne dass jeder einzelne Text() im
    // gesamten Projekt manuell eine Farbe setzen muss.
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),

    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide.none,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    ),
  );
}