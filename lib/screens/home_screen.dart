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
String _getActiveFiltersText() {
  List<String> active = [];

  if (_filter != MonthFilter.all) {
    final label = _getFilterLabel();
    if (label.isNotEmpty) {
      active.add(label);
    }
  }

  if (_showAdvanced && _userPosition != null) {
    active.add("Umkreis ${_radiusKm.round()} km");
  }

  if (_sortMode == SortMode.distance && _userPosition != null) {
    active.add("Sortiert nach Nähe");
  }

  if (_searchQuery.isNotEmpty) {
    active.add("Suche: \"$_searchQuery\"");
  }

  return active.join(" • ");
}

String _getFilterLabel() {
  switch (_filter) {
    case MonthFilter.today:
      return "Heute";

    case MonthFilter.may:
      return "Mai";

    case MonthFilter.june:
      return "Juni";

    case MonthFilter.july:
      return "Juli";

    case MonthFilter.august:
      return "August";

    case MonthFilter.past:
      return "Vergangen";

    case MonthFilter.favorites:
      return "Favoriten";

    case MonthFilter.weekend:
      return "Wochenende"; // ✅ neu hinzugefügt

    case MonthFilter.all:
      return ""; // bewusst leer (kein Filter aktiv)
  }
}
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



try {
  final pos = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.medium,
  );

  setState(() {
    _userPosition = pos;
  });
} catch (e) {
  debugPrint("Location error: $e");
}
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
  List<Festival> list = List.from(festivals);

  //--------------------------------------------------
  // ✅ 1. FILTER (MONATE / FAVORITEN)
  //--------------------------------------------------
switch (_filter) {
  case MonthFilter.all:
    break;

  case MonthFilter.favorites:
    list = list.where(
      (f) => FavoriteService.isFavorite(f.id),
    ).toList();
    break;

  case MonthFilter.past:
    list = list.where(_isPast).toList();
    break;

  case MonthFilter.today:
    list = list.where(_isToday).toList();
    break;

  case MonthFilter.may:
    list = list.where((f) => f.startDate.month == 5).toList();
    break;

  case MonthFilter.june:
    list = list.where((f) => f.startDate.month == 6).toList();
    break;

  case MonthFilter.july:
    list = list.where((f) => f.startDate.month == 7).toList();
    break;

  case MonthFilter.august:
    list = list.where((f) => f.startDate.month == 8).toList();
    break;

  case MonthFilter.weekend:
    list = list; 
    break;
}

  //--------------------------------------------------
  // ✅ 2. SUCHE
  //--------------------------------------------------
  if (_searchQuery.isNotEmpty) {
    list = list.where((f) =>


f.name.toLowerCase().contains(_searchQuery) ||
f.address.toLowerCase().contains(_searchQuery)


    ).toList();
  }

  //--------------------------------------------------
  // ✅ 3. RADIUS NUR WENN ERWEITERT AKTIV
  //--------------------------------------------------
  if (_showAdvanced && _userPosition != null) {
    list = list.where(_isWithinRadius).toList();
  }

//------------------------------------------
// ✅ SORTIERUNG (FINAL FIXED)
//------------------------------------------

final today = DateTime(now.year, now.month, now.day);

list.sort((a, b) {
  //------------------------------------------
  // 🔥 1. HEUTE / LIVE GANZ OBEN
  //------------------------------------------
  final aIsToday = _isToday(a);
  final bIsToday = _isToday(b);

  if (aIsToday && !bIsToday) return -1;
  if (bIsToday && !aIsToday) return 1;

  //------------------------------------------
  // 📍 2. DISTANCE MODE
  //------------------------------------------
  if (_sortMode == SortMode.distance && _userPosition != null) {
    final distA = _distanceInKm(a) ?? 999999;
    final distB = _distanceInKm(b) ?? 999999;
    return distA.compareTo(distB);
  }

  //------------------------------------------
  // 📅 3. DATUM
  //------------------------------------------
  final aStart = DateTime(
      a.startDate.year, a.startDate.month, a.startDate.day);
  final bStart = DateTime(
      b.startDate.year, b.startDate.month, b.startDate.day);

  final aDiff = aStart.difference(today).inDays;
  final bDiff = bStart.difference(today).inDays;

  final aScore = aDiff < 0 ? 99999 : aDiff;
  final bScore = bDiff < 0 ? 99999 : bDiff;

  return aScore.compareTo(bScore);
});

// ✅ GANZ WICHTIG!
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
if (_getActiveFiltersText().isNotEmpty)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: GestureDetector(
      onTap: () {
        setState(() {
          _filter = MonthFilter.all;
          _searchQuery = '';
          _showAdvanced = false;
          _sortMode = SortMode.date;
          _radiusKm = 25;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 16, color: Colors.green),
            const SizedBox(width: 6),

            Expanded(
              child: Text(
                _getActiveFiltersText(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 8),

            const Text(
              "Zurücksetzen",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
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
  child: Align(
    alignment: Alignment.centerLeft,
    child: InkWell(
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
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.local_taxi, size: 18, color: Colors.black),
            SizedBox(width: 6),
            Text(
              "Taxi finden",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    ),
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
      onTap: () {
  setState(() {
    _filter = value;

    //------------------------------------------
    // ✅ RESET LOGIK (NEU!)
    //------------------------------------------
    _sortMode = SortMode.date;

    if (!_showAdvanced) {
      _radiusKm = 25; // optional
    }
  });
},
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
