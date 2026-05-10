import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {

  static const String _key = "favorites";

  static final Set<String> _favorites = {};

  static SharedPreferences? _prefs;

  //--------------------------------------------------
  // ✅ INIT (WICHTIG!)
  //--------------------------------------------------
  static Future<void> loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();

    final list = _prefs!.getStringList(_key) ?? [];
    _favorites.clear();
    _favorites.addAll(list);
  }

  //--------------------------------------------------
  // ✅ CHECK
  //--------------------------------------------------
  static bool isFavorite(String id) {
    return _favorites.contains(id);
  }

  //--------------------------------------------------
  // ✅ TOGGLE
  //--------------------------------------------------
  static Future<void> toggleFavorite(String id) async {

    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }

    await _prefs?.setStringList(_key, _favorites.toList());
  }

  //--------------------------------------------------
  // ✅ OPTIONAL: DIRECT ADD
  //--------------------------------------------------
  static Future<void> addFavorite(String id) async {
    _favorites.add(id);
    await _prefs?.setStringList(_key, _favorites.toList());
  }

  //--------------------------------------------------
  // ✅ OPTIONAL: REMOVE
  //--------------------------------------------------
  static Future<void> removeFavorite(String id) async {
    _favorites.remove(id);
    await _prefs?.setStringList(_key, _favorites.toList());
  }

  //--------------------------------------------------
  // ✅ COUNT (für Badge etc.)
  //--------------------------------------------------
  static int get favoriteCount {
    return _favorites.length;
  }

  //--------------------------------------------------
  // ✅ ALLE FAVORITEN
  //--------------------------------------------------
  static List<String> get allFavorites {
    return _favorites.toList();
  }

  //--------------------------------------------------
  // ✅ RESET (für Debug / Admin)
  //--------------------------------------------------
  static Future<void> clearAll() async {
    _favorites.clear();
    await _prefs?.remove(_key);
  }
}