import 'package:flutter/material.dart';

class CountdownWidget extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;

  const CountdownWidget({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    if (now.isAfter(startDate) &&
        now.isBefore(endDate.add(const Duration(days: 1)))) {
      return _chip('Jetzt', Colors.green);
    }

    final days = startDate.difference(now).inDays;

    if (days == 1) {
      return _chip('Morgen', Colors.orange);
    }

    return _chip('Noch $days', Colors.grey);
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}