import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/event.dart';
import '../models/event_category.dart';
import '../services/event_query_service.dart';
import '../services/user_preferences_service.dart';
import '../services/weather_service.dart';
import '../widgets/event_card.dart';
import '../widgets/weather_forecast_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'event_detail_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../services/favorite_service.dart';
import '../theme/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  Position? _userPosition;
  bool _onlyToday = false;
  bool _isLoading = true;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  final Set<String> _selectedCities = {};
  final Set<EventCategory> _selectedCategories = {};
  double _maxDistance = 500;
  List<String> _availableCities = [];

  List<Event> _loadedEvents = [];

  DailyWeather? _todayWeather;
  List<DailyWeather> _forecast = [];
  bool _isLoadingWeather = false;

  @override
  void initState() {
    super.initState();
    _initMap();
    EventQueryService.fetchAvailableCities().then((cities) {
      if (mounted) setState(() => _availableCities = cities);
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initMap() async {
    await _loadDefaultFilters();

    final locationFuture = _getUserLocation();
    await _loadEventsAndMarkers();
    await locationFuture;

    if (mounted) {
      _buildMarkersFromLoaded();
      _animateCameraToInitialPosition();
    }
  }

  Future<void> _loadDefaultFilters() async {
    final defaultCities = await UserPreferencesService.getDefaultCities();
    final defaultCategoryValues =
        await UserPreferencesService.getDefaultCategoryValues();

    final defaultCategories = defaultCategoryValues
        .map((v) => EventCategoryExtension.fromString(v))
        .whereType<EventCategory>()
        .toSet();

    _selectedCities.addAll(defaultCities);
    _selectedCategories.addAll(defaultCategories);
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _userPosition = position;
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  //--------------------------------------------------
  // ✅ ANGEPASST: komplette Vorhersage behalten statt nur "heute"
  //--------------------------------------------------
  Future<void> _loadTodayWeatherIfNeeded() async {
    if (!_onlyToday || _userPosition == null) {
      if (mounted) setState(() => _todayWeather = null);
      return;
    }

    setState(() => _isLoadingWeather = true);

    try {
      final forecast = await WeatherService.fetchForecast(
        latitude: _userPosition!.latitude,
        longitude: _userPosition!.longitude,
      );

      final today = WeatherService.findForDate(forecast, DateTime.now());

      if (mounted) {
        setState(() {
          _forecast = forecast;
          _todayWeather = today;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      debugPrint("Wetter konnte nicht geladen werden: $e");
      if (mounted) {
        setState(() {
          _todayWeather = null;
          _isLoadingWeather = false;
        });
      }
    }
  }

  bool _isToday(Event f) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(f.startDate.year, f.startDate.month, f.startDate.day);
    final end = DateTime(f.endDate.year, f.endDate.month, f.endDate.day);
    return !start.isAfter(today) && !end.isBefore(today);
  }

  //--------------------------------------------------
  Future<void> _loadEventsAndMarkers() async {
    setState(() => _isLoading = true);

    final stopwatch = Stopwatch()..start();

    try {
      DateTime start;
      DateTime end;

      if (_onlyToday) {
        final now = DateTime.now();
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (_selectedStartDate != null) {
        start = _selectedStartDate!;
        end = _selectedEndDate ?? _selectedStartDate!;
      } else {
        start = DateTime.now();
        end = DateTime.now().add(const Duration(days: 30));
      }

      final categoryValues =
          _selectedCategories.map((c) => c.firestoreValue).toSet();

      final events = await EventQueryService.fetchRange(
        start: start,
        end: end,
        categories: categoryValues,
        cities: _selectedCities,
      );

      debugPrint(
        "⏱️ Karte Query dauerte: ${stopwatch.elapsedMilliseconds}ms, ${events.length} Events",
      );

      _loadedEvents = events;
      _buildMarkersFromLoaded();

      if (mounted) {
        setState(() => _isLoading = false);
      }

      await _loadTodayWeatherIfNeeded();
    } catch (e) {
      debugPrint("Event load error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Events konnten nicht geladen werden"),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  //--------------------------------------------------
  void _buildMarkersFromLoaded() {
    final filtered = _loadedEvents.where((f) {
      final hasCoordinates = f.latitude != 0 || f.longitude != 0;
      if (!hasCoordinates) return false;

      if (_userPosition != null) {
        final distanceKm = Geolocator.distanceBetween(
              _userPosition!.latitude,
              _userPosition!.longitude,
              f.latitude,
              f.longitude,
            ) /
            1000;
        if (distanceKm > _maxDistance) return false;
      }

      return true;
    }).toList();

    final markers = filtered.map((f) {
      final isToday = _isToday(f);
      final isFavorite = FavoriteService.isFavorite(f.id);

      double hue;
      String label = "";

      if (isFavorite) {
        hue = BitmapDescriptor.hueYellow;
        label = "Favorit: ";
      } else if (isToday) {
        hue = BitmapDescriptor.hueRose;
        label = "Heute: ";
      } else {
        hue = BitmapDescriptor.hueViolet;
      }

      return Marker(
        markerId: MarkerId(f.id),
        position: LatLng(f.latitude, f.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        onTap: () {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: LatLng(f.latitude, f.longitude), zoom: 12),
            ),
          );

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$label${f.name}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    EventCard(
                      event: f,
                      onFavoriteChanged: () {
                        setState(() {});
                        _buildMarkersFromLoaded();
                      },
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text("Schließen"),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EventDetailScreen(event: f)),
                            );
                          },
                          icon: const Icon(Icons.info_outline_rounded),
                          label: const Text("Details"),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=${f.latitude},${f.longitude}',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.navigation_rounded),
                          label: const Text("Route"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }).toSet();

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  void _animateCameraToInitialPosition() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _mapController == null) return;

      if (_userPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(_userPosition!.latitude, _userPosition!.longitude),
              zoom: 10,
            ),
          ),
        );
      } else if (_markers.isNotEmpty) {
        final first = _markers.first.position;
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: first, zoom: 10)),
        );
      }
    });
  }

  //--------------------------------------------------
  void _showLocationFilterSheet() {
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
                      Text("Umkreis um deinen Standort: ${_maxDistance.round()} km",
                          style: TextStyle(color: Colors.grey.shade600)),
                      Slider(
                        value: _maxDistance,
                        min: 0,
                        max: 500,
                        divisions: 50,
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setSheetState(() => _maxDistance = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      Text("Orte",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
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
                            _loadEventsAndMarkers();
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
  void _showCategoryFilterSheet() {
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
                        _loadEventsAndMarkers();
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

  //--------------------------------------------------
  String _categoryChipLabel() {
    if (_selectedCategories.isEmpty) return "Kategorie";
    if (_selectedCategories.length <= 2) {
      return _selectedCategories.map((c) => c.label).join(", ");
    }
    return "${_selectedCategories.length} Kategorien";
  }

  Widget _buildMapContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Events werden geladen..."),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          compassEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            _animateCameraToInitialPosition();
          },
          initialCameraPosition: const CameraPosition(target: LatLng(52.0, 8.6), zoom: 6),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _markers.isEmpty ? "Keine Events gefunden" : "${_markers.length} Events",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),

                // ✅ ANGEPASST: Wetter-Bereich jetzt antippbar (öffnet die
                // Mehrtages-Vorhersage), Temperatur nutzt wetterabhängige
                // Akzentfarbe.
                if (_onlyToday && _todayWeather != null) ...[
                  const SizedBox(width: 8),
                  Container(width: 1, height: 14, color: Colors.white24),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => showWeatherForecastSheet(context, _forecast),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          WeatherService.iconForCode(_todayWeather!.weatherCode),
                          size: 14,
                          color: WeatherService.isRainy(_todayWeather!.weatherCode)
                              ? AppColors.secondary
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${_todayWeather!.maxTemp.round()}°",
                          style: TextStyle(
                            color: WeatherService.isRainy(_todayWeather!.weatherCode)
                                ? AppColors.secondary
                                : AppColors.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 12,
                          color: WeatherService.isRainy(_todayWeather!.weatherCode)
                              ? AppColors.secondary
                              : AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ] else if (_onlyToday && _isLoadingWeather) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Row(
            children: [
              _buildFilterPill(
                icon: Icons.location_on_outlined,
                label: _selectedCities.isEmpty
                    ? "Ort"
                    : _selectedCities.length == 1
                        ? _selectedCities.first
                        : "${_selectedCities.length} Orte",
                active: _selectedCities.isNotEmpty || _maxDistance < 500,
                onTap: _showLocationFilterSheet,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                icon: Icons.category_outlined,
                label: _categoryChipLabel(),
                active: _selectedCategories.isNotEmpty,
                onTap: _showCategoryFilterSheet,
              ),
            ],
          ),
        ),
      ],
    );
  }

  //--------------------------------------------------
  Widget _buildFilterPill({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active
          ? AppColors.primary
          : const Color(0xFF0F172A).withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 80),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //--------------------------------------------------
  Widget _buildLabeledAction({
    required IconData icon,
    required String label,
    required String tooltip,
    required bool active,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active ? AppColors.secondary : Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: active ? AppColors.secondary : Colors.white,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildAppBarTitle() {
    if (_onlyToday) return "Heute entdecken";
    if (_selectedStartDate == null) return "Event Karte";
    return "Zeitraum aktiv";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_buildAppBarTitle()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildLabeledAction(
            icon: Icons.today_rounded,
            label: "Heute",
            tooltip: "Heute anzeigen",
            active: _onlyToday,
            onPressed: () {
              setState(() {
                _onlyToday = !_onlyToday;
                _selectedStartDate = null;
                _selectedEndDate = null;
              });
              _loadEventsAndMarkers();
            },
          ),
          _buildLabeledAction(
            icon: Icons.date_range_rounded,
            label: "Zeitraum",
            tooltip: "Zeitraum auswählen",
            active: _selectedStartDate != null,
            onPressed: () async {
              final now = DateTime.now();

              final start = await showDatePicker(
                context: context,
                helpText: "Startdatum wählen",
                initialDate: now,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (start == null || !mounted) return;

              final end = await showDatePicker(
                context: context,
                helpText: "Enddatum wählen",
                initialDate: start,
                firstDate: start,
                lastDate: DateTime(2100),
              );
              if (!mounted) return;

              setState(() {
                _selectedStartDate = start;
                _selectedEndDate = end ?? start;
                _onlyToday = false;
              });

              _loadEventsAndMarkers();
            },
          ),
          IconButton(
            tooltip: "Filter zurücksetzen",
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () {
              setState(() {
                _selectedStartDate = null;
                _selectedEndDate = null;
                _onlyToday = false;
                _selectedCities.clear();
                _selectedCategories.clear();
                _maxDistance = 500;
              });
              _loadEventsAndMarkers();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(child: _buildMapContent()),
    );
  }
}