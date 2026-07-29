import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../theme/app_colors.dart';

//--------------------------------------------------
// ✅ Gemeinsames Wetter-Detail-Sheet, genutzt von Home, Karte und
// Wochenendplaner – zeigt die komplette verfügbare Vorhersage
// (statt nur einem einzelnen Tag) auf Antippen des Wetter-Chips.
//--------------------------------------------------
void showWeatherForecastSheet(
  BuildContext context,
  List<DailyWeather> forecast,
) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final secondaryTextColor =
          isDark ? Colors.grey.shade400 : Colors.grey.shade600;
      final primaryTextColor =
          isDark ? Colors.white : const Color(0xFF0F172A);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_cloudy_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    "Wettervorhersage",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Quelle: Open-Meteo · für deinen aktuellen Standort",
                style: TextStyle(fontSize: 12, color: secondaryTextColor),
              ),
              const SizedBox(height: 16),

              if (forecast.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "Keine Wetterdaten verfügbar.",
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  ),
                )
              else
                ...forecast.map(
                  (day) => _buildDayRow(day, isDark, secondaryTextColor, primaryTextColor),
                ),
            ],
          ),
        ),
      );
    },
  );
}

//--------------------------------------------------
Widget _buildDayRow(
  DailyWeather day,
  bool isDark,
  Color secondaryTextColor,
  Color primaryTextColor,
) {
  final isRainy = WeatherService.isRainy(day.weatherCode);
  final accentColor = isRainy ? AppColors.secondary : AppColors.warning;
  final isToday = _isSameDay(day.date, DateTime.now());

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            isToday ? "Heute" : _weekdayShort(day.date),
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: primaryTextColor,
            ),
          ),
        ),
        Icon(WeatherService.iconForCode(day.weatherCode), size: 20, color: accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            WeatherService.labelForCode(day.weatherCode),
            style: TextStyle(color: secondaryTextColor, fontSize: 13),
          ),
        ),
        Row(
          children: [
            Icon(Icons.water_drop_outlined, size: 14, color: AppColors.secondary),
            const SizedBox(width: 2),
            Text(
              "${day.precipitationProbability}%",
              style: const TextStyle(color: AppColors.secondary, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Text(
          "${day.minTemp.round()}° / ${day.maxTemp.round()}°",
          style: TextStyle(fontWeight: FontWeight.w600, color: primaryTextColor),
        ),
      ],
    ),
  );
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekdayShort(DateTime date) {
  const names = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];
  return names[date.weekday - 1];
}