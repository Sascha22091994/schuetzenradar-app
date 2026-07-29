import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../main.dart';
import '../models/event_category.dart';
import '../services/event_query_service.dart';
import '../services/favorite_service.dart';
import '../services/user_preferences_service.dart';
import '../theme/app_colors.dart';
import 'weekend_planner_screen.dart';
import 'legal_screen.dart';
import 'admin_pending_events_screen.dart';
import 'admin_event_reports_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- Standardfilter ---
  Set<String> _defaultCities = {};
  Set<EventCategory> _defaultCategories = {};
  List<String> _availableCities = [];
  bool _isLoadingPreferences = true;

  // --- Einstellungen (zusammengeführt aus settings_screen.dart) ---
  bool _adminNewsEnabled = true;
  bool _supportDialogEnabled = true;
  bool _isLoadingSettings = true;
  String _version = "";

  // ✅ Ein gemeinsamer Ladezustand für einen sauberen, einzigen Spinner
  // beim ersten Öffnen, statt mehrerer nacheinander auftauchender
  // Teil-Ladeanzeigen (fühlt sich flüssiger/intuitiver an).
  bool get _isLoading => _isLoadingPreferences || _isLoadingSettings;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadSettings();
    _loadVersion();

    EventQueryService.fetchAvailableCities().then((cities) {
      if (mounted) setState(() => _availableCities = cities);
    });
  }

  //--------------------------------------------------
  // ✅ STANDARDFILTER
  //--------------------------------------------------
  Future<void> _loadPreferences() async {
    final cities = await UserPreferencesService.getDefaultCities();
    final categoryValues =
        await UserPreferencesService.getDefaultCategoryValues();

    final categories = categoryValues
        .map((v) => EventCategoryExtension.fromString(v))
        .whereType<EventCategory>()
        .toSet();

    if (!mounted) return;

    setState(() {
      _defaultCities = cities;
      _defaultCategories = categories;
      _isLoadingPreferences = false;
    });
  }

  Future<void> _saveDefaultCities(Set<String> cities) async {
    await UserPreferencesService.setDefaultCities(cities);
    setState(() => _defaultCities = cities);
  }

  Future<void> _saveDefaultCategories(Set<EventCategory> categories) async {
    final values = categories.map((c) => c.firestoreValue).toSet();
    await UserPreferencesService.setDefaultCategoryValues(values);
    setState(() => _defaultCategories = categories);
  }

  void _showEditCitiesSheet() {
    String citySearchQuery = '';
    final workingSet = Set<String>.from(_defaultCities);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredCities = citySearchQuery.isEmpty
                ? _availableCities
                : _availableCities
                    .where((c) =>
                        c.toLowerCase().contains(citySearchQuery.toLowerCase()))
                    .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Standard-Orte",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (workingSet.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setSheetState(() => workingSet.clear());
                              },
                              child: const Text("Zurücksetzen"),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Diese Orte werden auf \"Entdecken\" automatisch vorausgewählt.",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Ort suchen...",
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() => citySearchQuery = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filteredCities.length,
                          itemBuilder: (context, index) {
                            final city = filteredCities[index];
                            final isSelected = workingSet.contains(city);

                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              title: Text(city),
                              onChanged: (value) {
                                setSheetState(() {
                                  if (value == true) {
                                    workingSet.add(city);
                                  } else {
                                    workingSet.remove(city);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            await _saveDefaultCities(workingSet);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text("Speichern"),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEditCategoriesSheet() {
    final workingSet = Set<EventCategory>.from(_defaultCategories);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Standard-Kategorien",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (workingSet.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setSheetState(() => workingSet.clear());
                          },
                          child: const Text("Zurücksetzen"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Diese Kategorien werden auf \"Entdecken\" automatisch vorausgewählt.",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EventCategory.values.map((category) {
                      final selected = workingSet.contains(category);
                      return FilterChip(
                        selected: selected,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selected ? AppColors.primary : Colors.grey.shade300,
                          ),
                        ),
                        selectedColor: AppColors.primary.withValues(alpha: 0.12),
                        label: Text(category.label),
                        onSelected: (value) {
                          setSheetState(() {
                            if (value) {
                              workingSet.add(category);
                            } else {
                              workingSet.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        await _saveDefaultCategories(workingSet);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text("Speichern"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  //--------------------------------------------------
  // ✅ EINSTELLUNGEN (zusammengeführt aus settings_screen.dart)
  //--------------------------------------------------
  Future<void> _loadSettings() async {
    final adminNews = await UserPreferencesService.getAdminNewsEnabled();
    final supportDialog = await UserPreferencesService.getSupportDialogEnabled();

    if (!mounted) return;
    setState(() {
      _adminNewsEnabled = adminNews;
      _supportDialogEnabled = supportDialog;
      _isLoadingSettings = false;
    });
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = "${info.version} (${info.buildNumber})");
      }
    } catch (_) {
      if (mounted) setState(() => _version = "unbekannt");
    }
  }

  Future<void> _toggleAdminNews(bool value) async {
    setState(() => _adminNewsEnabled = value);
    await UserPreferencesService.setAdminNewsEnabled(value);

    try {
      if (value) {
        await FirebaseMessaging.instance.subscribeToTopic("all");
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic("all");
      }
    } catch (e) {
      debugPrint("Fehler beim Ändern des Push-Abos: $e");
    }
  }

  Future<void> _toggleSupportDialog(bool value) async {
    setState(() => _supportDialogEnabled = value);
    await UserPreferencesService.setSupportDialogEnabled(value);
  }

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, _) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Darstellung",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: currentMode,
                    activeColor: AppColors.primary,
                    title: const Text("Systemeinstellung folgen"),
                    onChanged: (mode) {
                      setThemeMode(mode!);
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: currentMode,
                    activeColor: AppColors.primary,
                    title: const Text("Hell"),
                    onChanged: (mode) {
                      setThemeMode(mode!);
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: currentMode,
                    activeColor: AppColors.primary,
                    title: const Text("Dunkel"),
                    onChanged: (mode) {
                      setThemeMode(mode!);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return "Systemeinstellung";
      case ThemeMode.light:
        return "Hell";
      case ThemeMode.dark:
        return "Dunkel";
    }
  }

  Future<void> _confirmAndResetAppData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("App-Daten zurücksetzen?"),
        content: const Text(
          "Favoriten und gespeicherte Standardfilter werden entfernt. "
          "Diese Aktion kann nicht rückgängig gemacht werden.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text("Zurücksetzen"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FavoriteService.clearAll();
    await UserPreferencesService.setDefaultCities({});
    await UserPreferencesService.setDefaultCategoryValues({});

    // ✅ Ergänzt: Standardfilter im UI sofort zurücksetzen, damit die
    // Anzeige mit den tatsächlich gespeicherten (nun leeren) Werten
    // übereinstimmt, ohne dass ein manueller Neustart nötig ist.
    if (mounted) {
      setState(() {
        _defaultCities = {};
        _defaultCategories = {};
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("App-Daten wurden zurückgesetzt.")),
      );
    }
  }

  //--------------------------------------------------
  Widget _settingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final dividerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [

                //--------------------------------------------------
                // ✅ ENTDECKEN (vormals "Standardfilter"-Card, jetzt mit
                // gleichem Sektions-Label-Stil wie der Rest der Seite)
                //--------------------------------------------------
                _sectionLabel("Entdecken", secondaryTextColor),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune_rounded, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text(
                              "Standardfilter für Entdecken",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Wird automatisch angewendet, ohne dass du Filter erneut setzen musst.",
                          style: TextStyle(fontSize: 12, color: secondaryTextColor),
                        ),
                        const SizedBox(height: 8),
                        _settingsRow(
                          icon: Icons.location_on_outlined,
                          title: "Orte",
                          subtitle: _defaultCities.isEmpty
                              ? "Keine Standard-Orte gesetzt"
                              : _defaultCities.join(", "),
                          onTap: _showEditCitiesSheet,
                        ),
                        Divider(color: dividerColor, height: 1),
                        _settingsRow(
                          icon: Icons.category_outlined,
                          title: "Kategorien",
                          subtitle: _defaultCategories.isEmpty
                              ? "Keine Standard-Kategorien gesetzt"
                              : _defaultCategories.map((c) => c.label).join(", "),
                          onTap: _showEditCategoriesSheet,
                        ),
                        Divider(color: dividerColor, height: 1),
                        _settingsRow(
                          icon: Icons.weekend_rounded,
                          title: "Wochenendplaner",
                          subtitle: "Events für das kommende Wochenende",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WeekendPlannerScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                //--------------------------------------------------
                // ✅ DARSTELLUNG
                //--------------------------------------------------
                _sectionLabel("Darstellung", secondaryTextColor),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, mode, _) {
                      return ListTile(
                        leading: const Icon(Icons.palette_outlined, color: AppColors.primary),
                        title: const Text("Theme"),
                        subtitle: Text(_themeModeLabel(mode)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _showThemeSheet,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                //--------------------------------------------------
                // ✅ BENACHRICHTIGUNGEN
                //--------------------------------------------------
                _sectionLabel("Benachrichtigungen", secondaryTextColor),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeThumbColor: AppColors.primary,
                        secondary: const Icon(Icons.campaign_outlined, color: AppColors.secondary),
                        title: const Text("Admin-Neuigkeiten"),
                        subtitle: const Text("Wichtige Ankündigungen zur App"),
                        value: _adminNewsEnabled,
                        onChanged: _toggleAdminNews,
                      ),
                      Divider(height: 1, color: dividerColor),
                      SwitchListTile(
                        activeThumbColor: AppColors.primary,
                        secondary: const Icon(Icons.favorite_outline, color: Color(0xFFEF4444)),
                        title: const Text("Support-Erinnerung"),
                        subtitle: const Text("Gelegentlicher Hinweis, das Projekt zu unterstützen"),
                        value: _supportDialogEnabled,
                        onChanged: _toggleSupportDialog,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                //--------------------------------------------------
                // ✅ ADMIN-BEREICH
                //--------------------------------------------------
                _sectionLabel("Admin", secondaryTextColor),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings_outlined),
                        title: const Text("Freigaben"),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminPendingEventsScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, color: dividerColor),
                      ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: const Text("Gemeldete Events"),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminEventReportsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    "⚠️ Noch ohne Zugriffsschutz – nur intern verlinkt.",
                    style: TextStyle(fontSize: 11, color: secondaryTextColor),
                  ),
                ),

                const SizedBox(height: 20),

                //--------------------------------------------------
                // ✅ DATEN
                //--------------------------------------------------
                _sectionLabel("Daten", secondaryTextColor),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    title: const Text("App-Daten zurücksetzen"),
                    subtitle: const Text("Favoriten & Standardfilter entfernen"),
                    onTap: _confirmAndResetAppData,
                  ),
                ),

                const SizedBox(height: 20),

//--------------------------------------------------
                // ✅ INFO
                //--------------------------------------------------
                _sectionLabel("Info", secondaryTextColor),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text("App-Version"),
                    trailing: Text(
                      _version,
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}