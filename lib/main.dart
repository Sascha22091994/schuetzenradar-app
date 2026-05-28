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
import 'package:flutter_localizations/flutter_localizations.dart';

//--------------------------------------------------
// ✅ GLOBAL NAVIGATOR KEY (NEU!)
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
    // ✅ PUSH SETUP (JETZT MIT UI!)
    //--------------------------------------------------
    if (!kIsWeb) {
      try {
        final settings =
            await FirebaseMessaging.instance.requestPermission();

        debugPrint("Push Permission: ${settings.authorizationStatus}");

        final token = await FirebaseMessaging.instance.getToken();
        debugPrint("🔥 FCM Token: $token");

        await FirebaseMessaging.instance.subscribeToTopic("all");

        //--------------------------------------------------
        // ✅ PUSH IM VORDERGRUND ANZEIGEN (NEU!)
        //--------------------------------------------------
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {

          debugPrint("📩 Push erhalten:");
          debugPrint("Titel: ${message.notification?.title}");
          debugPrint("Text: ${message.notification?.body}");

          final context = navigatorKey.currentContext;

          if (context == null) return;

          // ✅ Hier kannst du wählen:

          // 🔥 OPTION 1: Dialog
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(message.notification?.title ?? "Neu"),
              content: Text(message.notification?.body ?? ""),
            ),
          );

          // 🔥 OPTION 2 (statt Dialog):
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(
          //       message.notification?.title ?? "Neue Nachricht",
          //     ),
          //   ),
          // );
        });

      } catch (e) {
        debugPrint("⚠️ Push Fehler: $e");
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

    debugPrint("✅ INIT FERTIG");

  } catch (e) {
    debugPrint("🔥 INIT ERROR: $e");
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
          navigatorKey: navigatorKey, // ✅ EXTREM WICHTIG
          debugShowCheckedModeBanner: false,
          title: 'SchützenRadar',

          //--------------------------------------------------
          // ✅ DEUTSCH GLOBAL
          //--------------------------------------------------
          locale: const Locale('de', 'DE'),
          supportedLocales: const [
            Locale('de', 'DE'),
          ],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          //--------------------------------------------------

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
  );
}