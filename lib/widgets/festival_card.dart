import 'package:flutter/material.dart';
import '../models/festival.dart';
import '../services/favorite_service.dart';
import '../screens/festival_detail_screen.dart';
import 'countdown_widget.dart';

class FestivalCard extends StatefulWidget {
  final Festival festival;

  const FestivalCard({
    super.key,
    required this.festival,
  });

  @override
  State<FestivalCard> createState() => _FestivalCardState();
}

class _FestivalCardState extends State<FestivalCard> {

  @override
  Widget build(BuildContext context) {

    final isFavorite =
        FavoriteService.isFavorite(widget.festival.id);

    final theme = Theme.of(context);

    //--------------------------------------------------
    // ✅ DATUM OHNE UHRZEIT
    //--------------------------------------------------
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final start = DateTime(
      widget.festival.startDate.year,
      widget.festival.startDate.month,
      widget.festival.startDate.day,
    );

    final end = DateTime(
      widget.festival.endDate.year,
      widget.festival.endDate.month,
      widget.festival.endDate.day,
    );

    //--------------------------------------------------
    // ✅ STATES
    //--------------------------------------------------
    final isPast = end.isBefore(today);

    final isToday =
        !start.isAfter(today) &&
        !end.isBefore(today);

    //--------------------------------------------------
    return Stack(
      children: [

        //--------------------------------------------------
        // CARD
        //--------------------------------------------------
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

          //--------------------------------------------------
          // ✅ PAST FARBE (LIGHT + DARK)
          //--------------------------------------------------
          color: isPast
              ? theme.brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300
              : null,

          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FestivalDetailScreen(festival: widget.festival),
                ),
              );
            },

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Row(
                children: [

                  //--------------------------------------------------
                  // INFOS
                  //--------------------------------------------------
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        //--------------------------------------------------
                        // NAME
                        //--------------------------------------------------
                        Text(
                          widget.festival.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isPast
                                ? theme.brightness == Brightness.dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700
                                : theme.colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 6),

                        //--------------------------------------------------
                        // ADRESSE
                        //--------------------------------------------------
                        Text(
                          widget.festival.address,
                          style: TextStyle(
                            color: isPast
                                ? theme.brightness == Brightness.dark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade600
                                : theme.colorScheme.onSurface,
                          ),
                        ),

                        const SizedBox(height: 6),

                        //--------------------------------------------------
                        // DATUM
                        //--------------------------------------------------
                        Text(
                          '${widget.festival.startDate.day}.${widget.festival.startDate.month}'
                          ' - ${widget.festival.endDate.day}.${widget.festival.endDate.month}',
                          style: TextStyle(
                            color: isPast
                                ? theme.brightness == Brightness.dark
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade600
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  //--------------------------------------------------
                  // ACTIONS
                  //--------------------------------------------------
                  Column(
                    children: [

                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: isFavorite
                              ? const Color(0xFFFBC02D)
                              : Colors.grey,
                        ),
                        onPressed: () async {
                          await FavoriteService.toggleFavorite(
                              widget.festival.id);
                          setState(() {});
                        },
                      ),

                      //--------------------------------------------------
                      // COUNTDOWN
                      //--------------------------------------------------
                      if (!isPast)
                        CountdownWidget(
                          startDate: widget.festival.startDate,
                          endDate: widget.festival.endDate,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        //--------------------------------------------------
        // ✅ HEUTE BADGE
        //--------------------------------------------------
        if (isToday)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "HEUTE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}