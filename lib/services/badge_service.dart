import 'package:flutter/material.dart';
import 'favorite_service.dart';

class SchuetzenBadge {
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  SchuetzenBadge({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });
}

class BadgeService {
  static List<SchuetzenBadge> getBadges() {
    final count = FavoriteService.favoriteCount;
    final badges = <SchuetzenBadge>[];

    if (count >= 1) {
      badges.add(
        SchuetzenBadge(
          title: 'Neuschütze',
          description: '1 Schützenfest besucht',
          color: const Color(0xFFCD7F32), // Bronze
          icon: Icons.emoji_events,
        ),
      );
    }

    if (count >= 3) {
      badges.add(
        SchuetzenBadge(
          title: 'Stammgast',
          description: '3 Schützenfeste besucht',
          color: const Color(0xFFC0C0C0), // Silber
          icon: Icons.military_tech,
        ),
      );
    }

    if (count >= 5) {
      badges.add(
        SchuetzenBadge(
          title: 'Alt‑Schütze',
          description: '5+ Schützenfeste besucht',
          color: const Color(0xFFFBC02D), // Gold
          icon: Icons.workspace_premium,
        ),
      );
    }

    return badges;
  }
}