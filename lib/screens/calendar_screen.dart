import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/event.dart';
import '../models/event_category.dart';
import '../services/event_query_service.dart';
import '../services/favorite_service.dart';
import '../services/user_preferences_service.dart';
import '../theme/app_colors.dart';
import 'event_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final PageController _pageController = PageController(initialPage: 1000);

  DateTime _baseMonth = DateTime.now();
  bool _onlyFavorites = false;

  final Set<EventCategory> _selectedCategories = {};
  final Set<String> _selectedCities = {};
  List<String> _availableCities = [];

  // ✅ ANGEPASST: sinnvoller Standardwert statt 500 km, konsistent zum
  // Home Screen (löst dasselbe UX-Problem: Umkreis-Default untergräbt
  // sonst den Zweck des Filters).
  static const double _defaultMaxDistance = 50;
  double _maxDistance = _defaultMaxDistance;

  double? _userLatitude;
  double? _userLongitude;

  final Map<String, List<Event>> _monthCache = {};

  @override
  void initState() {
    super.initState();
    _loadDefaultFilters(); // ✅ NEU
    EventQueryService.fetchAvailableCities().then((cities) {
      if (mounted) setState(() => _availableCities = cities);
    });
    _loadLocation();
  }

  //--------------------------------------------------
  // ✅ NEU: Ort-Schalter – gespeicherte Standardfilter übernehmen
  //--------------------------------------------------
  Future<void> _loadDefaultFilters() async {
    final defaultCities = await UserPreferencesService.getDefaultCities();
    final defaultCategoryValues =
        await UserPreferencesService.getDefaultCategoryValues();

    final defaultCategories = defaultCategoryValues
        .map((v) => EventCategoryExtension.fromString(v))
        .whereType<EventCategory>()
        .toSet();

    if (!mounted) return;

    setState(() {
      _selectedCities.addAll(defaultCities);
      _selectedCategories.addAll(defaultCategories);
    });
  }

  Future<void> _loadLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
        });
      }
    } catch (_) {}
  }

  String _cacheKey(DateTime month) {
    final catKey = (_selectedCategories.map((c) => c.firestoreValue).toList()..sort()).join(",");
    final cityKey = (_selectedCities.toList()..sort()).join(",");
    return "${month.year}-${month.month}|$catKey|$cityKey";
  }

  //--------------------------------------------------
  Future<List<Event>> _loadMonth(DateTime month) async {
    final key = _cacheKey(month);

    if (_monthCache.containsKey(key)) {
      return _applyClientOnlyFilters(_monthCache[key]!);
    }

    final stopwatch = Stopwatch()..start();

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final categoryValues =
        _selectedCategories.map((c) => c.firestoreValue).toSet();

    final events = await EventQueryService.fetchRange(
      start: start,
      end: end,
      categories: categoryValues,
      cities: _selectedCities,
    );

    debugPrint(
      "⏱️ Kalender Query (${month.month}/${month.year}) dauerte: "
      "${stopwatch.elapsedMilliseconds}ms, ${events.length} Events",
    );

    _monthCache[key] = events;
    return _applyClientOnlyFilters(events);
  }

  List<Event> _applyClientOnlyFilters(List<Event> events) {
    return events.where((f) {
      if (_onlyFavorites && !FavoriteService.isFavorite(f.id)) {
        return false;
      }

      final hasCoordinates = f.latitude != 0 || f.longitude != 0;

      if (_userLatitude != null && _userLongitude != null && hasCoordinates) {
        final distanceKm = Geolocator.distanceBetween(
              _userLatitude!,
              _userLongitude!,
              f.latitude,
              f.longitude,
            ) /
            1000;

        if (distanceKm > _maxDistance) return false;
      }

      return true;
    }).toList();
  }

  void _onFiltersChanged() {
    setState(() {});
  }

  //--------------------------------------------------
  String _monthName(int month) {
    const names = [
      "Januar", "Februar", "März", "April", "Mai", "Juni",
      "Juli", "August", "September", "Oktober", "November", "Dezember"
    ];
    return names[month - 1];
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  //--------------------------------------------------
  Map<int, List<Event>> _groupEventsByDay(DateTime month, List<Event> events) {
    final grouped = <int, List<Event>>{};

    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);

    for (final f in events) {
      final start = DateTime(f.startDate.year, f.startDate.month, f.startDate.day);
      final end = DateTime(f.endDate.year, f.endDate.month, f.endDate.day);

      final rangeStart = start.isBefore(monthStart) ? monthStart : start;
      final rangeEnd = end.isAfter(monthEnd) ? monthEnd : end;

      if (rangeEnd.isBefore(rangeStart)) continue;

      for (var d = rangeStart;
          !d.isAfter(rangeEnd);
          d = d.add(const Duration(days: 1))) {
        if (d.month != month.month || d.year != month.year) continue;
        grouped.putIfAbsent(d.day, () => []).add(f);
      }
    }

    return grouped;
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
                          const Text("Ort & Umkreis",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          if (_selectedCities.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setSheetState(() => _selectedCities.clear());
                              },
                              child: const Text("Orte zurücksetzen"),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Umkreis um deinen Standort: ${_maxDistance.round()} km",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Slider(
                        value: _maxDistance,
                        min: 0,
                        max: 500,
                        divisions: 50,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setSheetState(() {
                            _maxDistance = value;
                          });
                        },
                      ),
                      // ✅ ANGEPASST: konsistente Formulierung mit Home Screen,
                      // ergänzt um den kalenderspezifischen Kontext.
                      Text(
                        "Gilt nur für Events, bei denen ein genauer Standort "
                        "hinterlegt ist, innerhalb des angezeigten Monats.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          onPressed: () => Navigator.pop(context),
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
    ).then((_) => _onFiltersChanged());
  }

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
                        // ✅ NEU: Farbpunkt pro Kategorie, konsistent zum
                        // Home Screen.
                        avatar: CircleAvatar(
                          radius: 6,
                          backgroundColor: category.color,
                        ),
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Anwenden"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) => _onFiltersChanged());
  }

  String _categoryChipLabel() {
    if (_selectedCategories.isEmpty) return "Kategorie";
    if (_selectedCategories.length <= 2) {
      return _selectedCategories.map((c) => c.label).join(", ");
    }
    return "${_selectedCategories.length} Kategorien";
  }

  // ✅ NEU: Farbpunkt im Trigger-Chip bei genau einer gewählten Kategorie,
  // konsistent zum Home Screen.
  Widget _categoryChipAvatar(Color secondaryTextColor) {
    if (_selectedCategories.length == 1) {
      return CircleAvatar(
        radius: 6,
        backgroundColor: _selectedCategories.first.color,
      );
    }

    return Icon(
      Icons.category_outlined,
      size: 18,
      color: _selectedCategories.isNotEmpty
          ? AppColors.primary
          : secondaryTextColor,
    );
  }

  //--------------------------------------------------
  // ✅ NEU: Legende für die farbcodierten Kalender-Punkte
  // (löst UX-Audit-Punkt "Farbcodierte Kalender-Punkte ohne Legende",
  // WCAG 1.4.1 – Farbe wird hier zusätzlich mit Text gekoppelt).
  //--------------------------------------------------
  Widget _buildLegend(bool isDark) {
    final textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    Widget legendItem(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ],
      );
    }

    return Semantics(
      label: "Legende: Gold steht für Favoriten, Türkis für andere Events",
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Row(
          children: [
            legendItem(AppColors.warning, "Favorit"),
            const SizedBox(width: 16),
            legendItem(AppColors.secondary, "Event"),
          ],
        ),
      ),
    );
  }

  //--------------------------------------------------
  List<Widget> _buildCalendar(
      DateTime month, Map<int, List<Event>> eventsByDay, bool isDark) {
    final firstDay = DateTime(month.year, month.month, 1);
    final offset = (firstDay.weekday + 6) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final List<Widget> days = [];

    for (int i = 0; i < offset; i++) {
      days.add(const SizedBox());
    }

    for (int i = 0; i < daysInMonth; i++) {
      final dayNumber = i + 1;
      final dayEvents = eventsByDay[dayNumber] ?? const <Event>[];
      final day = DateTime(month.year, month.month, dayNumber);

      days.add(
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (context) {
                if (dayEvents.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text("Keine Events an diesem Tag")),
                  );
                }
                return SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    children: dayEvents.map((f) {
                      return ListTile(
                        leading: const Icon(Icons.event_outlined,
                            color: AppColors.primary),
                        title: Text(f.name),
                        subtitle: Text(f.address),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => EventDetailScreen(event: f)),
                          );
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            color: _isToday(day)
                ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : AppColors.primary.withValues(alpha: 0.08))
                : (isDark ? Colors.grey.shade900 : Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$dayNumber",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _isToday(day) ? FontWeight.bold : FontWeight.normal,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: dayEvents.isEmpty
                        ? const SizedBox()
                        : Row(
                            children: [
                              Row(
                                children: dayEvents.take(3).map((f) {
                                  final isFav = FavoriteService.isFavorite(f.id);
                                  return Container(
                                    margin: const EdgeInsets.only(right: 2, top: 2),
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isFav
                                          ? AppColors.warning
                                          : AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (dayEvents.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Text(
                                    "+${dayEvents.length - 3}",
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: isDark ? Colors.grey[400] : Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    while (days.length < 42) {
      days.add(const SizedBox());
    }

    return days;
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    // ✅ ANGEPASST: Vergleich gegen neuen Default statt hart gegen 500.
    final hasActiveLocationFilter =
        _selectedCities.isNotEmpty || _maxDistance != _defaultMaxDistance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kalender"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            // ✅ ANGEPASST: ShaderMask-Fade am rechten Rand, konsistent zum
            // Home Screen (löst dasselbe UX-Problem: Chips wirken ohne
            // Hinweis abgeschnitten).
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.90, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: hasActiveLocationFilter,
                        showCheckmark: false,
                        avatar: Icon(Icons.location_on_outlined,
                            size: 18,
                            color: hasActiveLocationFilter
                                ? AppColors.primary
                                : secondaryTextColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: hasActiveLocationFilter
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
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: _selectedCategories.isNotEmpty,
                        showCheckmark: false,
                        avatar: _categoryChipAvatar(secondaryTextColor),
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
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: FilterChip(
                        selected: _onlyFavorites,
                        showCheckmark: false,
                        avatar: Icon(Icons.star_rounded,
                            size: 18,
                            color: _onlyFavorites ? AppColors.warning : secondaryTextColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: _onlyFavorites
                                ? AppColors.warning
                                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          ),
                        ),
                        selectedColor: AppColors.warning.withValues(alpha: 0.12),
                        label: const Text("Favoriten"),
                        onSelected: (value) {
                          setState(() => _onlyFavorites = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ✅ NEU: Legende für die farbcodierten Punkte
          _buildLegend(isDark),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const PageScrollPhysics(),
              itemBuilder: (context, index) {
                final month =
                    DateTime(_baseMonth.year, _baseMonth.month + (index - 1000));

                return FutureBuilder<List<Event>>(
                  future: _loadMonth(month),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final monthEvents = snapshot.data ?? [];

                    final eventsByDay = _groupEventsByDay(month, monthEvents);
                    final cells = _buildCalendar(month, eventsByDay, isDark);

                    return Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                    size: 18),
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                              ),
                              Text(
                                "${_monthName(month.month)} ${month.year}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 18),
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: List.generate(7, (i) {
                              final labels = [
                                "Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"
                              ];
                              return Expanded(child: Center(child: Text(labels[i])));
                            }),
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cells.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1.6,
                            ),
                            itemBuilder: (context, i) {
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 0.5,
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: cells[i],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}