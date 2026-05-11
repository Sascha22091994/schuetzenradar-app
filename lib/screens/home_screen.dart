import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/festival.dart';
import '../models/month_filter.dart';
import '../widgets/festival_card.dart';
import '../services/email_service.dart';
import '../services/favorite_service.dart';
import '../services/admin_service.dart';
import '../screens/taxi_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  MonthFilter _filter = MonthFilter.all;
  String _searchQuery = '';

  DateTime get now => DateTime.now();

  //--------------------------------------------------
  // HELPER
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

  //--------------------------------------------------
  // FILTER
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

    list.sort((a, b) {
      if (_isToday(a)) return -1;
      if (_isToday(b)) return 1;
      return a.startDate.compareTo(b.startDate);
    });

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
          appBar: AppBar(title: const Text('SchützenRadar')),

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
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    _btn('Heute', MonthFilter.today),
                    _btn('Alle', MonthFilter.all),
                    _btn('Mai', MonthFilter.may),
                    _btn('Juni', MonthFilter.june),
                    _btn('Juli', MonthFilter.july),
                    _btn('August', MonthFilter.august),
                    _btn('Vergangen', MonthFilter.past),
                    _btn('⭐', MonthFilter.favorites),
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
                  decoration: const InputDecoration(
                    hintText: 'Fest oder Ort suchen...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),


//--------------------------------------------------
// ✅ TAXI BUTTON (NEU)
 //--------------------------------------------------
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  child: Align(
    alignment: Alignment.centerLeft,
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TaxiScreen(),
          ),
        );
      },
      icon: const Icon(Icons.local_taxi),
      label: const Text("Taxis im Kreis"),
    ),
  ),
),
              //--------------------------------------------------
              // LISTE
              //--------------------------------------------------
              Expanded(
                child: ListView(
                  children: [

                    ...filtered.map((f) {
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
                          child: FestivalCard(festival: f),
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
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.black)),
      ),
    );
  }

  //--------------------------------------------------
  // ✅ ADD (MIT DATUM!)
  //--------------------------------------------------
  void _showAddFestivalDialog() {

    final name = TextEditingController();
    final address = TextEditingController();

    DateTime? start;
    DateTime? end;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Neues Schützenfest"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
                TextField(controller: address, decoration: const InputDecoration(labelText: "Ort")),

                ListTile(
                  title: Text(start == null
                      ? "Startdatum wählen"
                      : "${start!.day}.${start!.month}.${start!.year}"),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setStateDialog(() => start = picked);
                  },
                ),

                ListTile(
                  title: Text(end == null
                      ? "Enddatum wählen"
                      : "${end!.day}.${end!.month}.${end!.year}"),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: start ?? DateTime.now(),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setStateDialog(() => end = picked);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {

                  await FirebaseFirestore.instance
                      .collection('festivals')
                      .add({
                    "name": name.text,
                    "address": address.text,
                    "startDate": Timestamp.fromDate(start ?? DateTime.now()),
                    "endDate": Timestamp.fromDate(end ?? DateTime.now()),
                  });

                  Navigator.pop(context);
                },
                child: const Text("Speichern"),
              ),
            ],
          );
        },
      ),
    );
  }

  //--------------------------------------------------
  // ✅ EDIT (MIT DATUM!)
  //--------------------------------------------------
  void _showEditFestivalDialog(Festival f) {

    final name = TextEditingController(text: f.name);
    final address = TextEditingController(text: f.address);

    DateTime start = f.startDate;
    DateTime end = f.endDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Bearbeiten"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                TextField(controller: name),
                TextField(controller: address),

                ListTile(
                  title: Text("Start: ${start.day}.${start.month}.${start.year}"),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: start,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setStateDialog(() => start = picked);
                  },
                ),

                ListTile(
                  title: Text("Ende: ${end.day}.${end.month}.${end.year}"),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: end,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setStateDialog(() => end = picked);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {

                  await FirebaseFirestore.instance
                      .collection('festivals')
                      .doc(f.id)
                      .update({
                    "name": name.text,
                    "address": address.text,
                    "startDate": Timestamp.fromDate(start),
                    "endDate": Timestamp.fromDate(end),
                  });

                  Navigator.pop(context);
                },
                child: const Text("Speichern"),
              ),
            ],
          );
        },
      ),
    );
  }
}
