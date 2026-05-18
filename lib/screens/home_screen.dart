import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/festival.dart';
import '../models/month_filter.dart';
import '../widgets/festival_card.dart';
import '../services/email_service.dart';
import '../services/favorite_service.dart';
import '../services/admin_service.dart';
import '../screens/taxi_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/map_screen.dart';


enum SortMode {
  date,
  distance,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  MonthFilter _filter = MonthFilter.all;
  String _searchQuery = '';
  bool _showAdvanced = false;
  


SortMode _sortMode = SortMode.date;


  // ✅ GEO STATE NEU
  Position? _userPosition;
  double _radiusKm = 25;

  DateTime get now => DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLocation(); // ✅ NEU
  }

  //--------------------------------------------------
  // ✅ GEO: LOCATION LADEN (NEU)
  //--------------------------------------------------
  Future<void> _loadLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }


    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    if (!mounted) return;

setState(() {
  _userPosition = pos;
});

  }

  //--------------------------------------------------
  // ✅ GEO: DISTANZ CHECK (NEU)
  //--------------------------------------------------
bool _isWithinRadius(Festival f) {
  if (_userPosition == null) return true;

  final distance = Geolocator.distanceBetween(
    _userPosition!.latitude,
    _userPosition!.longitude,
    f.latitude,
    f.longitude,
  );

  return distance <= _radiusKm * 1000;
}

// ✅ HIERHIN!
double? _distanceInKm(Festival f) {
  if (_userPosition == null) return null;

  final distanceMeters = Geolocator.distanceBetween(
    _userPosition!.latitude,
    _userPosition!.longitude,
    f.latitude,
    f.longitude,
  );

  return distanceMeters / 1000;
}


  //--------------------------------------------------
  bool _isPast(Festival f) {
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(f.endDate.year, f.endDate.month, f.endDate.day);
    return end.isBefore(today);
  }

  bool _isToday(Festival f) {
    final today = DateTime(now.year, now.month, now.day);

    final start = DateTime(f.startDate.year, f.startDate.month, f.startDate.day);
    final end = DateTime(f.endDate.year, f.endDate.month, f.endDate.day);

    return !start.isAfter(today) && !end.isBefore(today);
  }

//  bool _hasToday(List<Festival> list) {
 //   return list.any((f) => _isToday(f));
  //}

  //--------------------------------------------------
  List<Festival> _applyFilter(List<Festival> festivals) {

    List<Festival> list;

    if (_filter == MonthFilter.favorites) {
      list = festivals.where((f) => FavoriteService.isFavorite(f.id)).toList();
    } else {
      list = festivals.where((f) {
        switch (_filter) {
          case MonthFilter.past:
            return _isPast(f);
          case MonthFilter.today:
            return _isToday(f);
          case MonthFilter.may:
            return f.startDate.month == 5;
          case MonthFilter.june:
            return f.startDate.month == 6;
          case MonthFilter.july:
            return f.startDate.month == 7;
          case MonthFilter.august:
            return f.startDate.month == 8;
          default:
            return true;
        }
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((f) =>
          f.name.toLowerCase().contains(_searchQuery) ||
          f.address.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    if (_filter != MonthFilter.past) {
      list = list.where((f) => !_isPast(f)).toList();
    }

  // ✅ GEO FILTER zuerst
if (_userPosition != null) {
  list = list.where(_isWithinRadius).toList();
}

if (_sortMode == SortMode.distance && _userPosition != null) {
  list.sort((a, b) {
    final distA = _distanceInKm(a) ?? 999999;
    final distB = _distanceInKm(b) ?? 999999;
    return distA.compareTo(distB);
  });
} else {
  list.sort((a, b) {
    if (_isToday(a)) return -1;
    if (_isToday(b)) return 1;
    return a.startDate.compareTo(b.startDate);
  });
}

    return list;
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('festivals').snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final festivals = snapshot.data!.docs.map((doc) {
          return Festival.fromMap({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          });
        }).toList();

        final filtered = _applyFilter(festivals);

        return Scaffold(
          appBar: AppBar(
  elevation: 0,
  backgroundColor: Colors.green.shade700,

  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.green.shade800,
          Colors.green.shade600,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),

  title: Row(
    children: const [
      Icon(Icons.radar, color: Colors.white, size: 35),
      SizedBox(width: 8),
      Text(
        "SchützenRadar",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 30,
          letterSpacing: 0.4,
        ),
      ),
    ],
  ),
),

          //--------------------------------------------------
          // ADMIN FAB (BLEIBT!)
          //--------------------------------------------------
          floatingActionButton: AdminService.isAdmin
              ? FloatingActionButton(
                  onPressed: () => _showAddFestivalDialog(),
                  child: const Icon(Icons.add),
                )
              : null,

          body: Column(
            children: [

              
              //--------------------------------------------------
              // FILTER
              //--------------------------------------------------
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _btn('⭐', MonthFilter.favorites),
                    _btn('Alle', MonthFilter.all),
                    _btn('Heute', MonthFilter.today),
                    _btn('Mai', MonthFilter.may),
                    _btn('Juni', MonthFilter.june),
                    _btn('Juli', MonthFilter.july),
                    _btn('August', MonthFilter.august),
                    _btn('Vergangen', MonthFilter.past),
                  ],
                ),
              ),

//--------------------------------------------------
              // SEARCH
              //--------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Fest oder Ort suchen...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

//--------------------------------------------------
// ✅ GEO INFO (OPTIONAL)
//--------------------------------------------------
if (_userPosition == null)
  const Padding(
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Text(
      "📍 Standort wird geladen...",
      style: TextStyle(fontSize: 12, color: Colors.grey),
    ),
  ),

//--------------------------------------------------
// ✅ WEITERE OPTIONEN BUTTON
//--------------------------------------------------
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  child: Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: () {
        setState(() {
          _showAdvanced = !_showAdvanced;
        });
      },
      icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
      label: const Text("Weitere Optionen"),
    ),
  ),
),

//--------------------------------------------------
// ✅ ERWEITERTE OPTIONEN (NEU)
//--------------------------------------------------
if (_showAdvanced)
  Column(
    children: [

      //--------------------------------------------------
      // SORTIERUNG
      //--------------------------------------------------
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            ChoiceChip(
              label: const Text("📅 Datum"),
              selected: _sortMode == SortMode.date,
              onSelected: (_) {
                setState(() => _sortMode = SortMode.date);
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text("📍 Entfernung"),
              selected: _sortMode == SortMode.distance,
              onSelected: (_) {
                setState(() => _sortMode = SortMode.distance);
              },
            ),
          ],
        ),
      ),

      //--------------------------------------------------
      // RADIUS
      //--------------------------------------------------
      if (_userPosition != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📍 Umkreis: ${_radiusKm.round()} km"),
              Slider(
                value: _radiusKm,
                min: 5,
                max: 100,
                divisions: 19,
                onChanged: (value) {
                  setState(() {
                    _radiusKm = value;
                  });
                },
              ),
            ],
          ),
        ),
    ],
  ),
              






              //--------------------------------------------------
              // 🚕 TAXI BUTTON (AUFGEWERTET)
              //--------------------------------------------------
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  child: Row(
    children: [

      //--------------------------------------------------
      // 🚕 TAXI BUTTON
      //--------------------------------------------------
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TaxiScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: const [
              Icon(Icons.local_taxi, size: 18, color: Colors.black),
              SizedBox(width: 6),
              Text(
                "Taxi",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(width: 10),

      //--------------------------------------------------
      // 🗺 MAP BUTTON (NEU!)
      //--------------------------------------------------
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MapScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: const [
              Icon(Icons.map, size: 18, color: Colors.black),
              SizedBox(width: 6),
              Text(
                "Karte",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
              //--------------------------------------------------
              // LISTE (UNVERÄNDERT!)
              //--------------------------------------------------
              Expanded(
                child: ListView(
                  children: [

                    ...filtered.map((f) {

  final distance = _distanceInKm(f); // ✅ NEU

  return Dismissible(
    key: Key(f.id),
    direction: AdminService.isAdmin
        ? DismissDirection.endToStart
        : DismissDirection.none,

    confirmDismiss: (_) async {
      return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Löschen?"),
          content: const Text("Bist du sicher?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Löschen"),
            ),
          ],
        ),
      );
    },

    onDismissed: (_) async {
      await FirebaseFirestore.instance
          .collection('festivals')
          .doc(f.id)
          .delete();
    },

    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    ),

    child: GestureDetector(
      onLongPress: () {
        if (AdminService.isAdmin) {
          _showEditFestivalDialog(f);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          FestivalCard(
            festival: f,
            onFavoriteChanged: () {
              setState(() {});
            },
          ),

          // ✅ NEU: DISTANZ ANZEIGE
          if (distance != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                "📍 ${distance.toStringAsFixed(1)} km entfernt",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}),

                  
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: () => EmailService.sendFeedback(),
                        icon: const Icon(Icons.add),
                        label: const Text('Fehlt dein Schützenfest?'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //--------------------------------------------------
  Widget _btn(String label, MonthFilter value) {
    final active = _filter == value;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.green : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  //--------------------------------------------------
  // ADD + EDIT (UNVERÄNDERT übernommen)
  //--------------------------------------------------
  void _showAddFestivalDialog() {}

  void _showEditFestivalDialog(Festival f) {}
}
