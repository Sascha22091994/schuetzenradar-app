import 'package:flutter/material.dart';
import '../models/festival.dart';
import '../services/favorite_service.dart';
import '../screens/festival_detail_screen.dart';

class FestivalCard extends StatelessWidget {
  final Festival festival;

  // ✅ NEU
  final VoidCallback onFavoriteChanged;

  const FestivalCard({
    super.key,
    required this.festival,
    required this.onFavoriteChanged, // ✅ NEU
  });

  //--------------------------------------------------
  DateTime get now => DateTime.now();

  bool _isToday() {
    final today = DateTime(now.year, now.month, now.day);

    final start = DateTime(
        festival.startDate.year,
        festival.startDate.month,
        festival.startDate.day);

    final end = DateTime(
        festival.endDate.year,
        festival.endDate.month,
        festival.endDate.day);

    return !start.isAfter(today) && !end.isBefore(today);
  }

  bool _isFuture() {
    final today = DateTime(now.year, now.month, now.day);
    return festival.startDate.isAfter(today);
  }

  bool _isLive() {
    return _isToday();
  }

  //--------------------------------------------------
  String _formatDate() {
    return "${festival.startDate.day}.${festival.startDate.month}.${festival.startDate.year}";
  }

  //--------------------------------------------------
  String _getCountdown() {
    final diff = festival.startDate.difference(now);

    if (diff.inDays > 1) {
      return "in ${diff.inDays} Tagen";
    } else if (diff.inDays == 1) {
      return "morgen 🎉";
    } else if (diff.inHours > 0) {
      return "in ${diff.inHours}h";
    } else if (diff.inMinutes > 0) {
      return "in ${diff.inMinutes} Min";
    } else {
      return "gleich";
    }
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    final isToday = _isToday();
    final isLive = _isLive();
    final isFuture = _isFuture();
    final isFav = FavoriteService.isFavorite(festival.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FestivalDetailScreen(festival: festival),
            ),
          );
        },

        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isLive
                ? (isDark ? Colors.green.shade800 : Colors.green.shade50)
                : (isDark ? Colors.grey.shade900 : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLive ? Colors.green : Colors.grey.shade300,
              width: isLive ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [

                  Text(
                    _formatDate(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),

                  const SizedBox(width: 10),

                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "LIVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "HEUTE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const Spacer(),

                  //--------------------------------------------------
                  // ✅ FIXED FAVORITE BUTTON
                  //--------------------------------------------------
                  GestureDetector(
                    onTap: () async {
                      await FavoriteService.toggleFavorite(festival.id);
                      onFavoriteChanged(); // ✅ DAS WAR DER FEHLER
                    },
                    child: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav ? Colors.amber : Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                festival.name,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              if (isLive)
                const Text(
                  "🔥 Läuft gerade",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (isFuture)
                Text(
                  "Start ${_getCountdown()}",
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              const SizedBox(height: 4),

              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      festival.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white70
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}