import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/event.dart';
import '../models/event_category.dart';
import '../services/event_query_service.dart';
import '../services/user_preferences_service.dart';
import '../services/weather_service.dart';
import '../widgets/event_card.dart';
import '../widgets/weather_forecast_sheet.dart';
import '../theme/app_colors.dart';
import 'submit_event_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';

  final Set<EventCategory> selectedCategories = {};
  final Set<String> selectedCities = {};
  bool showPastEvents = false;

  static const double _defaultMaxDistance = 50;
  double maxDistance = _defaultMaxDistance;

  double? userLatitude;
  double? userLongitude;

  DailyWeather? _todayWeather;
  List<DailyWeather> _forecast = [];
  bool _weatherFailed = false;

  bool _isFabVisible = true;

  final ScrollController _scrollController = ScrollController();

  List<Event> _events = [];
  List<Event> _highlights = [];
  List<String> _availableCities = [];

  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadDefaultFiltersAndInitial();
    _loadLocationAndWeather();

    EventQueryService.fetchAvailableCities().then((cities) {
      if (mounted) setState(() => _availableCities = cities);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  //--------------------------------------------------
  Future<void> _loadDefaultFiltersAndInitial() async {
    final defaultCities = await UserPreferencesService.getDefaultCities();
    final defaultCategoryValues =
        await UserPreferencesService.getDefaultCategoryValues();

    selectedCities.addAll(defaultCities);

    for (final value in defaultCategoryValues) {
      final category = EventCategoryExtension.fromString(value);
      if (category != null) selectedCategories.add(category);
    }

    await _loadInitial();
  }

  //--------------------------------------------------
  // ✅ ANGEPASST: komplette Vorhersage behalten statt nur "heute"
  //--------------------------------------------------
  Future<void> _loadLocationAndWeather() async {
    try {
      final position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          userLatitude = position.latitude;
          userLongitude = position.longitude;
        });
      }

      final forecast = await WeatherService.fetchForecast(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final today = WeatherService.findForDate(forecast, DateTime.now());

      if (mounted) {
        setState(() {
          _forecast = forecast;
          _todayWeather = today;
        });
      }
    } catch (e) {
      debugPrint("Wetter/Standort konnte nicht geladen werden: $e");
      if (mounted) setState(() => _weatherFailed = true);
    }
  }

  //--------------------------------------------------
  void _onScroll() {
    final direction = _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.reverse && _isFabVisible) {
      setState(() => _isFabVisible = false);
    } else if (direction == ScrollDirection.forward && !_isFabVisible) {
      setState(() => _isFabVisible = true);
    }

    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  //--------------------------------------------------
  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _events = [];
      _lastDoc = null;
      _hasMore = true;
    });

    final stopwatch = Stopwatch()..start();

    final categoryValues =
        selectedCategories.map((c) => c.firestoreValue).toSet();

    final now = DateTime.now();

    final shouldLoadHighlights = selectedCategories.isEmpty &&
        selectedCities.isEmpty &&
        !showPastEvents;

    final results = await Future.wait([
      EventQueryService.fetchPage(
        fromDate: showPastEvents ? null : now,
        toDate: showPastEvents ? now : null,
        categories: categoryValues,
        cities: selectedCities,
        limit: 25,
        descending: showPastEvents,
      ),
      shouldLoadHighlights
          ? EventQueryService.fetchHighlights()
          : Future.value(<Event>[]),
    ]);

    debugPrint("⏱️ Home Query dauerte: ${stopwatch.elapsedMilliseconds}ms");

    final page = results[0] as EventPage;
    final highlights = results[1] as List<Event>;

    if (!mounted) return;

    setState(() {
      _events = page.events;
      _highlights = highlights;
      _lastDoc = page.lastDoc;
      _hasMore = page.hasMore;
      _isInitialLoading = false;
    });
  }

  //--------------------------------------------------
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final categoryValues =
        selectedCategories.map((c) => c.firestoreValue).toSet();

    final now = DateTime.now();

    final page = await EventQueryService.fetchPage(
      fromDate: showPastEvents ? null : now,
      toDate: showPastEvents ? now : null,
      categories: categoryValues,
      cities: selectedCities,
      limit: 25,
      startAfter: _lastDoc,
      descending: showPastEvents,
    );

    if (!mounted) return;

    setState(() {
      _events.addAll(page.events);
      _lastDoc = page.lastDoc;
      _hasMore = page.hasMore;
      _isLoadingMore = false;
    });
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
                          const Text(
                            "Ort & Umkreis",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (selectedCities.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  selectedCities.clear();
                                });
                              },
                              child: const Text("Orte zurücksetzen"),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Umkreis um deinen Standort: ${maxDistance.round()} km",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Slider(
                        value: maxDistance,
                        min: 0,
                        max: 500,
                        divisions: 50,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setSheetState(() {
                            maxDistance = value;
                          });
                        },
                      ),
                      Text(
                        "Gilt nur für Events, bei denen ein genauer Standort "
                        "hinterlegt ist.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Zeigt Events aus den ausgewählten Orten. "
                        "Ohne Auswahl werden alle Orte angezeigt.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
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
                          setSheetState(() {
                            citySearchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: filteredCities.isEmpty
                            ? Center(
                                child: Text(
                                  "Kein Ort gefunden",
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filteredCities.length,
                                itemBuilder: (context, index) {
                                  final city = filteredCities[index];
                                  final isSelected =
                                      selectedCities.contains(city);

                                  return CheckboxListTile(
                                    value: isSelected,
                                    activeColor: AppColors.primary,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(city),
                                    onChanged: (value) {
                                      setSheetState(() {
                                        if (value == true) {
                                          selectedCities.add(city);
                                        } else {
                                          selectedCities.remove(city);
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
    ).then((_) {
      setState(() {});
      _loadInitial();
    });
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
            final isDark = Theme.of(context).brightness == Brightness.dark;
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
                        "Kategorien",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selectedCategories.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              selectedCategories.clear();
                            });
                          },
                          child: const Text("Zurücksetzen"),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ✅ Scrollbar, damit bei vielen Kategorien nichts overflowt
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EventCategory.values.map((category) {
                      final selected = selectedCategories.contains(category);

                      return FilterChip(
                        selected: selected,
                        showCheckmark: false,
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
                        selectedColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        label: Text(category.label),
                        onSelected: (value) {
                          setSheetState(() {
                            if (value) {
                              selectedCategories.add(category);
                            } else {
                              selectedCategories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                      ),
                    ),
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
    ).then((_) => _loadInitial());
  }

  //--------------------------------------------------
  String _categoryChipLabel() {
    if (selectedCategories.isEmpty) return "Kategorie";
    if (selectedCategories.length <= 2) {
      return selectedCategories.map((c) => c.label).join(", ");
    }
    return "${selectedCategories.length} Kategorien";
  }

  Widget _categoryChipAvatar(Color secondaryTextColor) {
    if (selectedCategories.length == 1) {
      return CircleAvatar(
        radius: 6,
        backgroundColor: selectedCategories.first.color,
      );
    }

    return Icon(
      Icons.category_outlined,
      size: 18,
      color: selectedCategories.isNotEmpty
          ? AppColors.primary
          : secondaryTextColor,
    );
  }

  String _sectionTitle() {
    if (selectedCategories.isEmpty) return "Highlights";
    return selectedCategories.map((c) => c.label).join(", ");
  }

  //--------------------------------------------------
  // ✅ ANGEPASST: jetzt antippbar (öffnet die Mehrtages-Vorhersage), mit
  // kleinem Chevron als Hinweis auf weitere Infos.
  //--------------------------------------------------
  Widget? _buildHeaderWeatherChip(bool isDark) {
    if (_weatherFailed || _todayWeather == null) return null;

    final weather = _todayWeather!;
    final isRainy = WeatherService.isRainy(weather.weatherCode);

    final accentColor = isRainy ? AppColors.secondary : AppColors.warning;

    return GestureDetector(
      onTap: () => showWeatherForecastSheet(context, _forecast),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: isDark ? 0.22 : 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
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
              "${weather.maxTemp.round()}°",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
            Icon(Icons.expand_more_rounded, size: 14, color: accentColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final hasActiveLocationFilter =
        selectedCities.isNotEmpty || maxDistance != _defaultMaxDistance;

    final visibleEvents = _events.where((e) {
      final matchesSearch = searchQuery.isEmpty ||
          e.name.toLowerCase().contains(searchQuery) ||
          e.address.toLowerCase().contains(searchQuery);

      if (!matchesSearch) return false;

      final hasCoordinates = e.latitude != 0 || e.longitude != 0;

      if (userLatitude != null && userLongitude != null && hasCoordinates) {
        final distanceKm = Geolocator.distanceBetween(
              userLatitude!,
              userLongitude!,
              e.latitude,
              e.longitude,
            ) /
            1000;

        if (distanceKm > maxDistance) return false;
      }

      return true;
    }).toList();

    final weatherChip = _buildHeaderWeatherChip(isDark);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      floatingActionButton: IgnorePointer(
  ignoring: !_isFabVisible,
  child: AnimatedScale(
    scale: _isFabVisible ? 1.0 : 0.0,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeInOut,
    child: AnimatedOpacity(
      opacity: _isFabVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      // ✅ ANGEPASST: Extended FAB (Icon + Label) statt reinem Icon-Kreis –
      // deutlich auffälliger und besser erkennbar, sobald er sichtbar ist.
      // Das Verschwinden beim Scrollen nach unten bleibt unverändert, das
      // löst weiterhin das Überlappungsproblem mit Karteninhalten.
      child: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubmitEventScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Event einreichen",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ),
  ),
),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.radar_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "ErlebnisRadar",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (weatherChip != null) weatherChip,
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Veranstaltung oder Ort suchen",
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor:
                            isDark ? AppColors.cardDark : AppColors.cardLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => searchQuery = value.toLowerCase().trim());
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Tooltip(
                    message: "Kalender",
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CalendarScreen()),
                        );
                      },
                      child: Container(
                        height: 56,
                        width: 64,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Kalender",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ShaderMask(
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
                        avatar: Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: hasActiveLocationFilter
                              ? AppColors.primary
                              : secondaryTextColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: hasActiveLocationFilter
                                ? AppColors.primary
                                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          ),
                        ),
                        selectedColor: AppColors.primary.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                        label: Text(
                          selectedCities.isEmpty
                              ? "Ort"
                              : selectedCities.length == 1
                                  ? selectedCities.first
                                  : "${selectedCities.length} Orte",
                        ),
                        onSelected: (_) => _showLocationSheet(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: selectedCategories.isNotEmpty,
                        showCheckmark: false,
                        avatar: _categoryChipAvatar(secondaryTextColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selectedCategories.isNotEmpty
                                ? AppColors.primary
                                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          ),
                        ),
                        selectedColor: AppColors.primary.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                        label: Text(_categoryChipLabel()),
                        onSelected: (_) => _showCategorySheet(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: FilterChip(
                        selected: showPastEvents,
                        showCheckmark: true,
                        checkmarkColor: secondaryTextColor,
                        backgroundColor: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                        selectedColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                          ),
                        ),
                        label: Text(
                          "Vergangene",
                          style: TextStyle(color: secondaryTextColor, fontSize: 12),
                        ),
                        onSelected: (value) {
                          setState(() => showPastEvents = value);
                          _loadInitial();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isInitialLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadInitial,
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 100),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                            child: Text(
                              _sectionTitle(),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          // ✅ TIER 4: Hinweis-Banner, wenn nach "Sonstiges"
                          // gefiltert wird – diese Events konnten aus den
                          // Quelldaten keiner festen Kategorie zugeordnet werden.
                          if (selectedCategories
                              .contains(EventCategory.sonstiges))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.blueGrey.shade900
                                          .withValues(alpha: 0.4)
                                      : Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        size: 18, color: secondaryTextColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Diese Veranstaltungen ließen sich anhand "
                                        "der vorliegenden Quelldaten keiner festen "
                                        "Kategorie zuordnen.",
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.35,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (visibleEvents.isEmpty && _highlights.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(40),
                              child: Center(
                                child: Text(
                                  "Keine Veranstaltungen gefunden",
                                  style: TextStyle(color: secondaryTextColor),
                                ),
                              ),
                            ),
                          ..._highlights.map(
                            (event) => EventCard(
                              event: event,
                              onFavoriteChanged: () => setState(() {}),
                            ),
                          ),
                          ...visibleEvents.map(
                            (event) => EventCard(
                              event: event,
                              onFavoriteChanged: () => setState(() {}),
                            ),
                          ),
                          if (_isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}