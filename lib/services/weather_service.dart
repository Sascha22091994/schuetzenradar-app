import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DailyWeather {
  final DateTime date;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;
  final int precipitationProbability;

  DailyWeather({
    required this.date,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitationProbability,
  });
}

class WeatherService {
  //--------------------------------------------------
  static Future<List<DailyWeather>> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_probability_max'
      '&timezone=auto',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Wetterdaten konnten nicht geladen werden (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>;

    final dates = List<String>.from(daily['time']);
    final codes = List<int>.from(daily['weathercode']);
    final maxTemps = List<num>.from(daily['temperature_2m_max']);
    final minTemps = List<num>.from(daily['temperature_2m_min']);
    final precipProbs =
        List<num>.from(daily['precipitation_probability_max']);

    return List.generate(dates.length, (i) {
      return DailyWeather(
        date: DateTime.parse(dates[i]),
        weatherCode: codes[i],
        maxTemp: maxTemps[i].toDouble(),
        minTemp: minTemps[i].toDouble(),
        precipitationProbability: precipProbs[i].toInt(),
      );
    });
  }

  //--------------------------------------------------
  // ✅ WMO-Wettercodes -> Icon/Label (offizieller Open-Meteo-Standard)
  //--------------------------------------------------
  static IconData iconForCode(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.wb_cloudy_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.grain_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.water_drop_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.wb_cloudy_rounded;
  }

  static String labelForCode(int code) {
    if (code == 0) return "Sonnig";
    if (code <= 3) return "Bewölkt";
    if (code == 45 || code == 48) return "Neblig";
    if (code >= 51 && code <= 67) return "Regen";
    if (code >= 71 && code <= 77) return "Schnee";
    if (code >= 80 && code <= 82) return "Schauer";
    if (code >= 95) return "Gewitter";
    return "Bewölkt";
  }

  static bool isRainy(int code) {
    return (code >= 51 && code <= 67) ||
        (code >= 80 && code <= 82) ||
        code >= 95;
  }

  //--------------------------------------------------
  static DailyWeather? findForDate(List<DailyWeather> forecast, DateTime day) {
    for (final entry in forecast) {
      if (entry.date.year == day.year &&
          entry.date.month == day.month &&
          entry.date.day == day.day) {
        return entry;
      }
    }
    return null;
  }
}