import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/festival.dart';
import '../models/month_filter.dart';
import '../widgets/festival_card.dart';
import '../services/favorite_service.dart';
import '../services/admin_service.dart';
import '../screens/taxi_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/map_screen.dart';
import 'submit_festival_screen.dart';



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
     

          body: Column(
            children: [


    //--------------------------------------------------
    // 🔍 SEARCH (BLEIBT OBEN)
    //--------------------------------------------------
    Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: TextField(
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Fest oder Ort suchen...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ),

    //--------------------------------------------------
    // ✅ FILTER (KOMPAKT)
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

    const SizedBox(height: 6),



//--------------------------------------------------
// ✅ HEADER: FILTER + ACTION BUTTONS (FINAL)
//--------------------------------------------------
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [

      //--------------------------------------------------
      // 🔽 FILTER (UNVERÄNDERT DROPDOWN)
      //--------------------------------------------------
      Expanded(
        flex: 2,
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            title: const Text(
              "Suchfilter",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [

              //--------------------------------------
              // SORTIERUNG
              //--------------------------------------
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text("📅 Datum"),
                    selected: _sortMode == SortMode.date,
                    onSelected: (_) {
                      setState(() => _sortMode = SortMode.date);
                    },
                  ),
                  ChoiceChip(
                    label: const Text("📍 Entfernung"),
                    selected: _sortMode == SortMode.distance,
                    onSelected: (_) {
                      setState(() => _sortMode = SortMode.distance);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              //--------------------------------------
              // RADIUS
              //--------------------------------------
              if (_userPosition != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Umkreis: ${_radiusKm.round()} km"),
                    Slider(
                      value: _radiusKm,
                      min: 5,
                      max: 100,
                      divisions: 19,
                      onChanged: (value) {
                        setState(() => _radiusKm = value);
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),

      const SizedBox(width: 8),

      //--------------------------------------------------
      // 🚕 TAXI BUTTON
      //--------------------------------------------------
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TaxiScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_taxi,
                    color: Colors.amber, size: 22),
                SizedBox(height: 4),
                Text(
                  "Taxi",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),

      const SizedBox(width: 6),

      //--------------------------------------------------
      // 🗺 KARTE BUTTON
      //--------------------------------------------------
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MapScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map,
                    color: Colors.blue, size: 22),
                SizedBox(height: 4),
                Text(
                  "Karte",
                  style: TextStyle(fontWeight: FontWeight.w600),
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
    // ✅ HIER IST DER GAMECHANGER
    //--------------------------------------------------
    Expanded(
      child: ListView(
        children: [

          //--------------------------------------------------
          // ✅ FEST MELDEN (JETZT ÜBER LISTE!)
          //--------------------------------------------------
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubmitFestivalScreen(),
                  ),
                );
              },
              child: const Center(
                child: Text(
                  "🎉 Fehlt ein Fest? Dann klicke hier🎉",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

//--------------------------------------------------
// ✅ DICKER TRENNER
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
          // FESTIVAL LISTE
          //--------------------------------------------------
      ...filtered.map((f) {

  final distance = _distanceInKm(f);

  return Dismissible(
    key: Key(f.id),

    //--------------------------------------------------
    // ✅ NUR ADMIN DARF LÖSCHEN
    //--------------------------------------------------
    direction: AdminService.isAdmin
        ? DismissDirection.endToStart
        : DismissDirection.none,

    //--------------------------------------------------
    // ✅ BESTÄTIGUNG
    //--------------------------------------------------
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

    //--------------------------------------------------
    // ✅ LÖSCHEN
    //--------------------------------------------------
    onDismissed: (_) async {
      await FirebaseFirestore.instance
          .collection('festivals')
          .doc(f.id)
          .delete();
    },

    //--------------------------------------------------
    // ✅ SWIPE UI
    //--------------------------------------------------
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete, color: Colors.white),
    ),

    //--------------------------------------------------
    // ✅ CONTENT
    //--------------------------------------------------
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

}).toList(),

        ],
      ), // ✅ ListView

    ), // ✅ Expanded

  ], // ✅ Column children
), // ✅ Column

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


 void _showEditFestivalDialog(Festival f) {}
}
