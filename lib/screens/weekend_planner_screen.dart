import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/event.dart';
import '../models/event_category.dart';
import '../services/event_query_service.dart';
import '../services/user_preferences_service.dart';
import '../services/weather_service.dart';
import '../widgets/event_card.dart';
import '../theme/app_colors.dart';
import '../widgets/weather_forecast_sheet.dart';

class WeekendPlannerScreen extends StatefulWidget {
  const WeekendPlannerScreen({super.key});

  @override
  State<WeekendPlannerScreen> createState() => _WeekendPlannerScreenState();
}

class _WeekendPlannerScreenState extends State<WeekendPlannerScreen> {
  final Set<EventCategory> _selectedCategories = {};
  final Set<String> _selectedCities = {};
  List<String> _availableCities = [];

  DateTime _saturday = DateTime.now();
  DateTime _sunday = DateTime.now();

  List<Event> _events = [];
  bool _isLoading = true;

  // ✅ NEU: Wetter
  List<DailyWeather> _forecast = [];
  bool _isLoadingWeather = true;
  bool _weatherFailed = false;

  @override
  void initState() {
    super.initState();
    _computeWeekend();
    _loadDefaultFiltersAndFetch();
    _loadWeather();

    EventQueryService.fetchAvailableCities().then((cities) {
      if (mounted) setState(() => _availableCities = cities);
    });
  }

  //--------------------------------------------------
  void _computeWeekend() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int daysUntilSaturday = (DateTime.saturday - today.weekday + 7) % 7;

    if (today.weekday == DateTime.sunday) {
      daysUntilSaturday = 6;
    }

    _saturday = today.add(Duration(days: daysUntilSaturday));
    _sunday = _saturday.add(const Duration(days: 1));
  }

  //--------------------------------------------------
  // ✅ NEU: Wetter für den Nutzerstandort laden
  //--------------------------------------------------
  Future<void> _loadWeather() async {
    setState(() {
      _isLoadingWeather = true;
      _weatherFailed = false;
    });

    try {
      final position = await Geolocator.getCurrentPosition();

      final forecast = await WeatherService.fetchForecast(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _forecast = forecast;
        _isLoadingWeather = false;
      });
    } catch (e) {
      debugPrint("Wetter konnte nicht geladen werden: $e");
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
          _weatherFailed = true;
        });
      }
    }
  }

  //--------------------------------------------------
  Future<void> _loadDefaultFiltersAndFetch() async {
    final defaultCities = await UserPreferencesService.getDefaultCities();
    final defaultCategoryValues =
        await UserPreferencesService.getDefaultCategoryValues();

    final defaultCategories = defaultCategoryValues
        .map((v) => EventCategoryExtension.fromString(v))
        .whereType<EventCategory>()
        .toSet();

    _selectedCities.addAll(defaultCities);
    _selectedCategories.addAll(defaultCategories);

    await _fetchWeekendEvents();
  }

  //--------------------------------------------------
  Future<void> _fetchWeekendEvents() async {
    setState(() => _isLoading = true);

    final start = DateTime(_saturday.year, _saturday.month, _saturday.day);
    final end = DateTime(_sunday.year, _sunday.month, _sunday.day, 23, 59, 59);

    final categoryValues =
        _selectedCategories.map((c) => c.firestoreValue).toSet();

    try {
      final events = await EventQueryService.fetchRange(
        start: start,
        end: end,
        categories: categoryValues,
        cities: _selectedCities,
      );

      events.sort((a, b) => a.startDate.compareTo(b.startDate));

      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fehler beim Laden des Wochenendplaners: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //--------------------------------------------------
  bool _isOnDay(Event e, DateTime day) {
    final start = DateTime(e.startDate.year, e.startDate.month, e.startDate.day);
    final end = DateTime(e.endDate.year, e.endDate.month, e.endDate.day);
    final target = DateTime(day.year, day.month, day.day);
    return !target.isBefore(start) && !target.isAfter(end);
  }

  //--------------------------------------------------
  void _showLocationSheet() {
    String citySearchQuery = '';

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
              initialChildSize: 0.75,
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
                          const Text("Orte",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          if (_selectedCities.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setSheetState(() => _selectedCities.clear());
                              },
                              child: const Text("Zurücksetzen"),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                            final isSelected = _selectedCities.contains(city);

                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              title: Text(city),
                              onChanged: (value) {
                                setSheetState(() {
                                  if (value == true) {
                                    _selectedCities.add(city);
                                  } else {
                                    _selectedCities.remove(city);
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
                          onPressed: () {
                            Navigator.pop(context);
                            _fetchWeekendEvents();
                          },
                          child: const Text("Anwenden"),
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

  //--------------------------------------------------
  void _showCategorySheet() {
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
                      const Text("Kategorien",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (_selectedCategories.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setSheetState(() => _selectedCategories.clear());
                          },
                          child: const Text("Zurücksetzen"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EventCategory.values.map((category) {
                      final selected = _selectedCategories.contains(category);
                      return FilterChip(
                        selected: selected,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        selectedColor: AppColors.primary.withValues(alpha: 0.12),
                        label: Text(category.label),
                        onSelected: (value) {
                          setSheetState(() {
                            if (value) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
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
                      onPressed: () {
                        Navigator.pop(context);
                        _fetchWeekendEvents();
                      },
                      child: const Text("Anwenden"),
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

  String _categoryChipLabel() {
    if (_selectedCategories.isEmpty) return "Kategorie";
    if (_selectedCategories.length <= 2) {
      return _selectedCategories.map((c) => c.label).join(", ");
    }
    return "${_selectedCategories.length} Kategorien";
  }

  String _weekdayLabel(DateTime day) {
    const names = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];
    return names[day.weekday - 1];
  }

  //--------------------------------------------------
  // ✅ NEU: Kompakte Wetter-Zeile neben dem Tagesnamen
  //--------------------------------------------------
  // ✅ ANGEPASST: Container jetzt in GestureDetector, öffnet dieselbe
// Mehrtages-Vorhersage wie Home und Karte.
Widget _buildWeatherChip(DateTime day) {
  if (_isLoadingWeather) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  if (_weatherFailed) return const SizedBox();

  final weather = WeatherService.findForDate(_forecast, day);
  if (weather == null) return const SizedBox();

  final isRainy = WeatherService.isRainy(weather.weatherCode);
  final accentColor = isRainy ? AppColors.secondary : AppColors.warning;

  return GestureDetector(
    onTap: () => showWeatherForecastSheet(context, _forecast),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            WeatherService.iconForCode(weather.weatherCode),
            size: 16,
            color: accentColor,
          ),
          const SizedBox(width: 4),
          Text(
            "${weather.maxTemp.round()}° · ${weather.precipitationProbability}% Regen",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    ),
  );
}

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final saturdayEvents = _events.where((e) => _isOnDay(e, _saturday)).toList();
    final sundayEvents = _events.where((e) => _isOnDay(e, _sunday)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wochenendplaner"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [

          //--------------------------------------------------
          // ✅ ZEITRAUM-HINWEIS
          //--------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Text(
              "${_saturday.day}.${_saturday.month}. – ${_sunday.day}.${_sunday.month}.${_sunday.year}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          //--------------------------------------------------
          // ✅ FILTERZEILE
          //--------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _selectedCities.isNotEmpty,
                      showCheckmark: false,
                      avatar: Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: _selectedCities.isNotEmpty
                            ? AppColors.primary
                            : secondaryTextColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectedCities.isNotEmpty
                              ? AppColors.primary
                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                      ),
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      label: Text(
                        _selectedCities.isEmpty
                            ? "Ort"
                            : _selectedCities.length == 1
                                ? _selectedCities.first
                                : "${_selectedCities.length} Orte",
                      ),
                      onSelected: (_) => _showLocationSheet(),
                    ),
                  ),
                  FilterChip(
                    selected: _selectedCategories.isNotEmpty,
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.category_outlined,
                      size: 18,
                      color: _selectedCategories.isNotEmpty
                          ? AppColors.primary
                          : secondaryTextColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: _selectedCategories.isNotEmpty
                            ? AppColors.primary
                            : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                      ),
                    ),
                    selectedColor: AppColors.primary.withValues(alpha: 0.12),
                    label: Text(_categoryChipLabel()),
                    onSelected: (_) => _showCategorySheet(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          //--------------------------------------------------
          // ✅ INHALT
          //--------------------------------------------------
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.weekend_outlined, size: 60, color: secondaryTextColor),
                              const SizedBox(height: 16),
                              Text(
                                "Für dieses Wochenende wurde nichts gefunden.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [

                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Samstag, ${_weekdayLabel(_saturday)} ${_saturday.day}.${_saturday.month}.",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                _buildWeatherChip(_saturday), // ✅ NEU
                              ],
                            ),
                          ),

                          if (saturdayEvents.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Text(
                                "Keine Events am Samstag.",
                                style: TextStyle(color: secondaryTextColor, fontSize: 13),
                              ),
                            )
                          else
                            ...saturdayEvents.map(
                              (event) => EventCard(
                                event: event,
                                onFavoriteChanged: () => setState(() {}),
                              ),
                            ),

                          const SizedBox(height: 8),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Sonntag, ${_weekdayLabel(_sunday)} ${_sunday.day}.${_sunday.month}.",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                _buildWeatherChip(_sunday), // ✅ NEU
                              ],
                            ),
                          ),

                          if (sundayEvents.isEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Text(
                                "Keine Events am Sonntag.",
                                style: TextStyle(color: secondaryTextColor, fontSize: 13),
                              ),
                            )
                          else
                            ...sundayEvents.map(
                              (event) => EventCard(
                                event: event,
                                onFavoriteChanged: () => setState(() {}),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}