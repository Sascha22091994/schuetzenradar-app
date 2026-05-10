import 'package:flutter/material.dart';
import '../services/badge_service.dart';

class BadgeChip extends StatelessWidget {
  final SchuetzenBadge badge;

  const BadgeChip({
    super.key,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        badge.icon,
        color: badge.color,
      ),
      label: Text(
        badge.title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: badge.color.withValues(alpha: 0.15),
      side: BorderSide(color: badge.color),
    );
  }
}