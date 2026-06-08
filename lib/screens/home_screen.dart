import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/festival.dart';
import '../models/month_filter.dart';
import '../widgets/festival_card.dart';
import '../services/favorite_service.dart';
import '../screens/taxi_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/map_screen.dart';
import 'submit_festival_screen.dart';
import 'calendar_screen.dart';


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

  


SortMode _sortMode = SortMode.date;


  // ✅ GEO STATE NEU
  Position? _userPosition;
  double _radiusKm = 25;

 
DateTime get today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}


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
    final today = this.today;
    final end = DateTime(f.endDate.year, f.endDate.month, f.endDate.day);
    return end.isBefore(today);
  }

  bool _isToday(Festival f) {
    final today = this.today;

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

if (_sortMode == SortMode.distance && _userPosition != null){

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

  if (snapshot.connectionState == ConnectionState.waiting) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

if (snapshot.hasError) {
  return const Center(
    child: Text("Fehler beim Laden.\nBitte Verbindung prüfen."),
  );
}

if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  return const Center(
    child: Text("Keine Daten verfügbar"),
  );
}

if (snapshot.hasError) {
  return const Center(
    child: Text("Fehler beim Laden.\nBitte Verbindung prüfen."),
  );
}

if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  return const Center(
    child: Text("Keine Daten verfügbar"),
  );
}

        final festivals = snapshot.data!.docs.map((doc) {
          return Festival.fromMap({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          });
        }).toList();

        final filtered = _applyFilter(festivals);

final activeFestivals =
    filtered.where((f) => !_isPast(f)).toList();


final pastFestivals =
    festivals
        .where((f) => _isPast(f))
        .where((f) => _userPosition == null || _isWithinRadius(f))
        .toList();


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

// FEST MELDEN BUTTON
// FEST MELDEN BUTTON
floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubmitFestivalScreen(),
      ),
    );
  },
  icon: const Icon(Icons.add),
  label: const Text("Fest hinzufügen"),
),
          //--------------------------------------------------
          // ADMIN FAB (BLEIBT!)
          //--------------------------------------------------
     

// NUR DER BODY TEIL IST GEÄNDERT – Rest bleibt gleich

body: Column(
  children: [

    //--------------------------------------------------
    // 🔍 SEARCH + FILTER DROPDOWN
    //--------------------------------------------------
    Padding(
  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
  child: TextField(
    onChanged: (value) =>
        setState(() => _searchQuery = value.toLowerCase()),
    decoration: InputDecoration(
      hintText: 'Fest oder Ort suchen...',
      prefixIcon: const Icon(Icons.search),

      suffixIcon: PopupMenuButton<String>(
        icon: const Icon(Icons.tune),

        onSelected: (value) {
          setState(() {
            // ✅ SORTIERUNG
            if (value == "date") _sortMode = SortMode.date;
            if (value == "distance") _sortMode = SortMode.distance;

            // ✅ RADIUS
            if (value == "radius10") _radiusKm = 10;
            if (value == "radius25") _radiusKm = 25;
            if (value == "radius50") _radiusKm = 50;
            if (value == "radius100") _radiusKm = 100;
            if (value == "radius200") _radiusKm = 200;
            if (value == "radius500") _radiusKm = 500;

            // ✅ UX BOOST
            if (value.startsWith("radius")) {
              _sortMode = SortMode.distance;
            }
          });
        },

        itemBuilder: (context) => [

          const PopupMenuItem(
            enabled: false,
            child: Text("Sortierung"),
          ),
          CheckedPopupMenuItem(
            value: "date",
            checked: _sortMode == SortMode.date,
            child: const Text("Datum"),
          ),
          CheckedPopupMenuItem(
            value: "distance",
            checked: _sortMode == SortMode.distance,
            child: const Text("Entfernung"),
          ),

          const PopupMenuDivider(),

          const PopupMenuItem(
            enabled: false,
            child: Text("Umkreis"),
          ),
          CheckedPopupMenuItem(
            value: "radius10",
            checked: _radiusKm == 10,
            child: const Text("10 km"),
          ),
          CheckedPopupMenuItem(
            value: "radius25",
            checked: _radiusKm == 25,
            child: const Text("25 km"),
          ),
          CheckedPopupMenuItem(
            value: "radius50",
            checked: _radiusKm == 50,
            child: const Text("50 km"),
          ),
          CheckedPopupMenuItem(
            value: "radius100",
            checked: _radiusKm == 100,
            child: const Text("100 km"),
          ),
          CheckedPopupMenuItem(
            value: "radius200",
            checked: _radiusKm == 200,
            child: const Text("200 km"),
          ),
          CheckedPopupMenuItem(
            value: "radius500",
            checked: _radiusKm == 500,
            child: const Text("500 km (Deutschlandweit)"),
          ),
        ],
      ),

      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  ),
),

    //--------------------------------------------------
    // ✅ MONATSFILTER (BLEIBT)
    //--------------------------------------------------
    SizedBox(
      height: 42,
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

          
        ],
      ),
      
    ),
    

    const SizedBox(height: 8),

//--------------------------------------------------
// 🚕 ACTION BUTTONS (SCHLANK & CLEAN)
//--------------------------------------------------
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  child: Row(
    children: [

      //--------------------------------------------------
      // 🚕 TAXI
      //--------------------------------------------------
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TaxiScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.yellow.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_taxi, size: 18, color: Colors.black87),
                SizedBox(width: 6),
                Text(
                  "Taxi",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      const SizedBox(width: 8),

      //--------------------------------------------------
      // 🗺 KARTE
      //--------------------------------------------------
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MapScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 18, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  "Karte",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      const SizedBox(width: 8),

      //--------------------------------------------------
      // 📅 KALENDER
      //--------------------------------------------------
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CalendarScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month, size: 18, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  "Kalender",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
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

    //--------------------------------------------------
    // ✅ LISTE
    //--------------------------------------------------
    Expanded(
      child: ListView(
        children: [

          
          //--------------------------------------------------
          // TRENNER
          //--------------------------------------------------
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade300,
                  Colors.green.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),

//--------------------------------------------------
// AKTUELLE FESTE
//--------------------------------------------------
...activeFestivals.map((f) {
  final distance = _distanceInKm(f);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      
FestivalCard(
  key: ValueKey("${f.id}_${FavoriteService.isFavorite(f.id)}"),
  festival: f,
  onFavoriteChanged: () {
    setState(() {});
  },
),

      if (distance != null)
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            "📍 ${distance.toStringAsFixed(1)} km entfernt",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
    ],
  );
}).toList(),

//--------------------------------------------------
// VERGANGENE FESTE
//--------------------------------------------------
if (pastFestivals.isNotEmpty) ...[

  const Padding(
    padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
    child: Text(
      "Vergangene Feste",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  ...pastFestivals.take(5).map((f) {
    return FestivalCard(
  festival: f,
  onFavoriteChanged: () {
    setState(() {});
  },

    );
  }).toList(),

  //--------------------------------------------------
  // BUTTON → ALLE VERGANGENEN
  //--------------------------------------------------
  Center(
    child: TextButton(
      onPressed: () {
        setState(() {
          _filter = MonthFilter.past;
        });
      },
      child: const Text("Alle vergangenen anzeigen"),
    ),
  ),
],



        ],
      ),
    ),
  ],
),


); // ✅ Scaffold
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


 //void _showEditFestivalDialog(Festival f) {}
}
