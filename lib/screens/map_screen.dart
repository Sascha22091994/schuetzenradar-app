import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/festival.dart';
import '../widgets/festival_card.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/festival_detail_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../services/favorite_service.dart';

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

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initMap() async {
    await _getUserLocation();
    await _loadMarkers();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permission permanently denied");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _userPosition = position;
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  bool _isToday(Festival f) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final start = DateTime(f.startDate.year, f.startDate.month, f.startDate.day);
    final end = DateTime(f.endDate.year, f.endDate.month, f.endDate.day);

    return !start.isAfter(today) && !end.isBefore(today);
  }

  bool _isInSelectedRange(Festival f) {
    if (_selectedStartDate == null && _selectedEndDate == null) {
      return true;
    }

    final start = DateTime(f.startDate.year, f.startDate.month, f.startDate.day);
    final end = DateTime(f.endDate.year, f.endDate.month, f.endDate.day);

    final filterStart = _selectedStartDate ?? DateTime(2000);
    final filterEnd = _selectedEndDate ?? DateTime(2100);

    return !(end.isBefore(filterStart) || start.isAfter(filterEnd));
  }

  Future<void> _loadMarkers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('festivals').get();

      final markers = snapshot.docs.map((doc) {
        final f = Festival.fromMap({
          ...doc.data(),
          'id': doc.id,
        });

        if (_onlyToday) {
          if (!_isToday(f)) return null;
        } else {
          if (!_isInSelectedRange(f)) return null;
        }

        final isToday = _isToday(f);
        final isFavorite = FavoriteService.isFavorite(f.id);

        double hue;
        String label = "";

        if (isFavorite) {
          hue = BitmapDescriptor.hueYellow;
          label = "⭐ ";
        } else if (isToday) {
          hue = BitmapDescriptor.hueRed;
          label = "🔥 ";
        } else {
          hue = BitmapDescriptor.hueGreen;
        }

        return Marker(
          markerId: MarkerId(f.id),
          position: LatLng(f.latitude, f.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () {
            // Kamera auf Festival-Position zentrieren (nicht User-Position)
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(f.latitude, f.longitude),
                  zoom: 12,
                ),
              ),
            );

            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$label${f.name}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FestivalCard(
                        festival: f,
                        onFavoriteChanged: () {
                          setState(() {});
                          _loadMarkers();
                        },
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text("Schließen"),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FestivalDetailScreen(festival: f),
                                ),
                              );
                            },
                            icon: const Icon(Icons.info),
                            label: const Text("Details"),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              
final url = Uri.parse(
  "https://www.google.com/maps/dir/?api=1&destination=${f.latitude},${f.longitude}",
);


                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text("Navigation konnte nicht geöffnet werden"),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.navigation),
                            label: const Text("Navigieren"),
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
      }).whereType<Marker>().toSet();

      if (!mounted) return;

      setState(() {
        _markers = markers;
        _isLoading = false;
      });

      _animateCameraToInitialPosition();
    } catch (e) {
      debugPrint("Marker load error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fehler beim Laden der Events"),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _animateCameraToInitialPosition() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _mapController == null) return;

      if (_userPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                _userPosition!.latitude,
                _userPosition!.longitude,
              ),
              zoom: 10,
            ),
          ),
        );
      } else if (_markers.isNotEmpty) {
        final first = _markers.first.position;
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: first,
              zoom: 10,
            ),
          ),
        );
      }
    });
  }

  Set<Circle> _buildCircles() {
    if (_userPosition == null) return {};

    return {
      Circle(
        circleId: const CircleId("radius"),
        center: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        radius: 10000,
        fillColor: Colors.green.withValues(alpha: 0.15),
        strokeColor: Colors.green,
        strokeWidth: 2,
      ),
    };
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
          onMapCreated: (controller) {
            _mapController = controller;
            _animateCameraToInitialPosition();
          },
          initialCameraPosition: const CameraPosition(
            target: LatLng(52.0, 8.6),
            zoom: 6,
          ),
          markers: _markers,
          //circles: _buildCircles(),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _markers.isEmpty
                  ? "Keine Events gefunden"
                  : "${_markers.length} Events",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  String _buildAppBarTitle() {
    if (_onlyToday) {
      return "📅 Heute";
    }
    if (_selectedStartDate == null) {
      return "Karte (Datum wählen)";
    }
    return "📅 ${_selectedStartDate!.day}.${_selectedStartDate!.month}. - ${_selectedEndDate!.day}.${_selectedEndDate!.month}.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_buildAppBarTitle()),
        backgroundColor: Colors.green,
        actions: [
          // Heute-Filter
          IconButton(
            tooltip: "Heute anzeigen",
            icon: Icon(
              Icons.today,
              color: _onlyToday ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() {
                _onlyToday = !_onlyToday;
                _selectedStartDate = null;
                _selectedEndDate = null;
                _isLoading = true;
              });

              _loadMarkers();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _onlyToday
                        ? "📅 Es werden nur heutige Events angezeigt"
                        : "📅 Filter entfernt",
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          // Kalender
          IconButton(
            tooltip: "Zeitraum auswählen",
            icon: const Icon(Icons.date_range),
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
                _isLoading = true;
              });

              _loadMarkers();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "📅 Zeitraum: ${start.day}.${start.month}. - ${_selectedEndDate!.day}.${_selectedEndDate!.month}.",
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),

          // Reset
          IconButton(
            tooltip: "Filter zurücksetzen",
            icon: const Icon(Icons.restart_alt),
            onPressed: () {
              setState(() {
                _selectedStartDate = null;
                _selectedEndDate = null;
                _onlyToday = false;
                _isLoading = true;
              });

              _loadMarkers();


final isDark = Theme.of(context).brightness == Brightness.dark;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    backgroundColor: isDark
        ? Colors.grey.shade900
        : Colors.grey.shade800,

    behavior: SnackBarBehavior.floating, // ✅ wirkt moderner

    content: const Text("Filter zurückgesetzt"),
    duration: const Duration(seconds: 2),
  ),
);

            },
          ),
        ],
      ),
      body: SafeArea(
        child: _buildMapContent(),
      ),
    );
  }
}
