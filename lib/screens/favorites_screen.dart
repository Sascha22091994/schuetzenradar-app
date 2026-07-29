import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/event_query_service.dart';
import '../services/favorite_service.dart';
import '../widgets/event_card.dart';
import '../theme/app_colors.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Event> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      final ids = FavoriteService.allFavorites;
      final events = await EventQueryService.fetchByIds(ids);

      events.sort((a, b) => a.startDate.compareTo(b.startDate));

      if (!mounted) return;

      setState(() {
        _favorites = events;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fehler beim Laden der Favoriten: $e");

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Favoriten konnten nicht geladen werden: $e"),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final secondaryTextColor =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favoriten"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFavorites,
              child: _favorites.isEmpty
                  ? ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 80),
                              Icon(
                                Icons.favorite_border_rounded,
                                size: 70,
                                color: secondaryTextColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Noch keine Favoriten",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Markiere Veranstaltungen mit dem Stern, "
                                "damit sie hier erscheinen.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final event = _favorites[index];

                        return EventCard(
                          event: event,
                          onFavoriteChanged: () {
                            _loadFavorites();
                          },
                        );
                      },
                    ),
            ),
    );
  }
}