import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static const _citiesKey = 'default_cities';
  static const _categoriesKey = 'default_categories';

//--------------------------------------------------
// ✅ NEU: Push-Einstellungen
//--------------------------------------------------
static const _adminNewsKey = 'admin_news_enabled';
static const _supportDialogKey = 'support_dialog_enabled';

static Future<bool> getAdminNewsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_adminNewsKey) ?? true;
}

static Future<void> setAdminNewsEnabled(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_adminNewsKey, value);
}

static Future<bool> getSupportDialogEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  // ✅ Nutzt denselben Key wie main_navigation_screen.dart ("supportDisabled"),
  // hier nur invertiert für eine natürlichere Formulierung im UI
  return !(prefs.getBool('supportDisabled') ?? false);
}

static Future<void> setSupportDialogEnabled(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('supportDisabled', !value);
}
  //--------------------------------------------------
  static Future<Set<String>> getDefaultCities() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_citiesKey) ?? []).toSet();
  }

  static Future<void> setDefaultCities(Set<String> cities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_citiesKey, cities.toList());
  }

  //--------------------------------------------------
  // ✅ Kategorien als firestoreValue-Strings gespeichert
  //--------------------------------------------------
  static Future<Set<String>> getDefaultCategoryValues() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_categoriesKey) ?? []).toSet();
  }

  static Future<void> setDefaultCategoryValues(Set<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, values.toList());
  }
}