import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FavoriteService {

  static const String _key = "favorites";

  static final Set<String> _favorites = {};
  static SharedPreferences? _prefs;

  //--------------------------------------------------
  // ✅ INIT
  //--------------------------------------------------
  static Future<void> loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();

    final list = _prefs!.getStringList(_key) ?? [];
    _favorites
      ..clear()
      ..addAll(list);

    // ✅ Sicherheit: Topics synchronisieren
    for (final id in _favorites) {
      await FirebaseMessaging.instance.subscribeToTopic("festival_$id");
    }
  }

  //--------------------------------------------------
  static bool isFavorite(String id) {
    return _favorites.contains(id);
  }

  //--------------------------------------------------
  // ✅ TOGGLE + PUSH
  //--------------------------------------------------
  static Future<void> toggleFavorite(String id) async {

    if (_favorites.contains(id)) {
      _favorites.remove(id);

      await FirebaseMessaging.instance
          .unsubscribeFromTopic("festival_$id");

    } else {
      _favorites.add(id);

      await FirebaseMessaging.instance
          .subscribeToTopic("festival_$id");
    }

    await _prefs?.setStringList(_key, _favorites.toList());
  }

  //--------------------------------------------------
  static Future<void> addFavorite(String id) async {
    _favorites.add(id);

    await FirebaseMessaging.instance
        .subscribeToTopic("festival_$id");

    await _prefs?.setStringList(_key, _favorites.toList());
  }

  //--------------------------------------------------
  static Future<void> removeFavorite(String id) async {
    _favorites.remove(id);

    await FirebaseMessaging.instance
        .unsubscribeFromTopic("festival_$id");

    await _prefs?.setStringList(_key, _favorites.toList());
  }

  //--------------------------------------------------
  static int get favoriteCount => _favorites.length;

  static List<String> get allFavorites =>
      _favorites.toList();

  //--------------------------------------------------
  static Future<void> clearAll() async {
    for (final id in _favorites) {
      await FirebaseMessaging.instance
          .unsubscribeFromTopic("festival_$id");
    }

    _favorites.clear();
    await _prefs?.remove(_key);
  }
}
