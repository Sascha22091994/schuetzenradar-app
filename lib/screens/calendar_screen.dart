import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/festival.dart';
import '../services/favorite_service.dart';
import '../screens/festival_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final PageController _pageController =
      PageController(initialPage: 1000);

  DateTime _baseMonth = DateTime.now();
  bool _onlyFavorites = false;

  //--------------------------------------------------
  String _monthName(int month) {
    const names = [
      "Januar","Februar","März","April","Mai","Juni",
      "Juli","August","September","Oktober","November","Dezember"
    ];
    return names[month - 1];
  }

  //--------------------------------------------------
  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  //--------------------------------------------------
  List<Festival> _filter(List<Festival> list) {
    if (_onlyFavorites) {
      return list
          .where((f) => FavoriteService.isFavorite(f.id))
          .toList();
    }
    return list;
  }

  //--------------------------------------------------
  List<Festival> _eventsOfDay(DateTime day, List<Festival> list) {
    return list.where((f) {
      final start = DateTime(
          f.startDate.year, f.startDate.month, f.startDate.day);
      final end = DateTime(
          f.endDate.year, f.endDate.month, f.endDate.day);

      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();
  }

  //--------------------------------------------------
  List<Widget> _buildCalendar(
      DateTime month,
      List<Festival> festivals,
      bool isDark) {

    final firstDay = DateTime(month.year, month.month, 1);
    final offset = (firstDay.weekday + 6) % 7;
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;

    final List<Widget> days = [];

    for (int i = 0; i < offset; i++) {
      days.add(const SizedBox());
    }

    for (int i = 0; i < daysInMonth; i++) {
      final day = DateTime(month.year, month.month, i + 1);
      final events = _eventsOfDay(day, festivals);

      days.add(
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (context) {
                final events =
                    _eventsOfDay(day, festivals);

                if (events.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child:
                          Text("Keine Events an diesem Tag"),
                    ),
                  );
                }

                return ListView(
                  children: events.map((f) {
                    return ListTile(
                      leading:
                          const Icon(Icons.festival),
                      title: Text(f.name),
                      subtitle: Text(f.address),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FestivalDetailScreen(
                              festival: f,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            );
          },

          child: Container(
            padding: const EdgeInsets.all(4),
            color: _isToday(day)
                ? (isDark
                    ? Colors.green.shade900
                    : Colors.green.shade50)
                : (isDark
                    ? Colors.grey.shade900
                    : Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                //--------------------------------------------------
                // TAG
                //--------------------------------------------------
                Text(
                  "${day.day}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _isToday(day)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color:
                        isDark ? Colors.white : Colors.black,
                  ),
                ),

                const SizedBox(height: 2),

                //--------------------------------------------------
                // EVENTS
                //--------------------------------------------------
                ...events.take(2).map((f) {
                  final isFav =
                      FavoriteService.isFavorite(f.id);

                  return Container(
                    margin:
                        const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: isFav
                          ? Colors.orange
                          : Colors.green,
                      borderRadius:
                          BorderRadius.circular(3),
                    ),
                    child: Text(
                      f.name,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }),

                if (events.length > 2)
                  Text(
                    "+${events.length - 2}",
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark
                          ? Colors.grey[400]
                          : Colors.grey,
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

    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kalender"),
        actions: [
          Row(
            children: [
              const Text("⭐"),
              Switch(
                value: _onlyFavorites,
                onChanged: (v) =>
                    setState(() => _onlyFavorites = v),
              ),
            ],
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('festivals')
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final festivals = snapshot.data!.docs.map((doc) {
            return Festival.fromMap({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            });
          }).toList();

          final filtered = _filter(festivals);

          return PageView.builder(
            controller: _pageController,

            itemBuilder: (context, index) {

              final month = DateTime(
                _baseMonth.year,
                _baseMonth.month + (index - 1000),
              );

              final cells =
                  _buildCalendar(month, filtered, isDark);

              return Column(
                children: [

                  //--------------------------------------------------
                  // MONAT
                  //--------------------------------------------------
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "${_monthName(month.month)} ${month.year}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),

                  //--------------------------------------------------
                  // WOCHENTAGE
                  //--------------------------------------------------
                  Container(
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    padding:
                        const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: List.generate(7, (i) {
                        final labels =
                            ["Mo","Di","Mi","Do","Fr","Sa","So"];
                        return Expanded(
                          child: Center(
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  //--------------------------------------------------
                  // GRID
                  //--------------------------------------------------
                  Expanded(
                    child: GridView.builder(
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: cells.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.9,
                      ),
                      itemBuilder: (context, i) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                              width: 0.5,
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
    );
  }
}