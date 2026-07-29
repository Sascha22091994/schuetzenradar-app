import 'package:flutter/material.dart';

enum EventCategory {
  schuetzenfest,
  konzert,
  festival,
  stadtfest,
  markt,
  food,
  sport,
  familie,
  theaterComedy,
  sonstiges,
  fuehrung,
  workshop,
  // ✅ NEU (Tier 1): die zwei größten Cluster aus dem "sonstiges"-Berg
  kunst,
  natur,
  // ✅ NEU: eigener Kino-Chip + Community-Treffs
  kino,
  treffen,
}

extension EventCategoryExtension on EventCategory {
  String get label {
    switch (this) {
      case EventCategory.schuetzenfest:
        return "Schützenfest";
      case EventCategory.konzert:
        return "Konzert";
      case EventCategory.festival:
        return "Festival";
      case EventCategory.stadtfest:
        return "Stadtfest";
      case EventCategory.markt:
        return "Markt";
      case EventCategory.food:
        return "Food";
      case EventCategory.sport:
        return "Sport";
      case EventCategory.familie:
        return "Familie";
      // ✅ ANGEPASST: von "Theater / Comedy" auf "Kultur & Bühne" erweitert,
      // damit Tanz-/Bühnenprogramme (die vorher fälschlich als "Festival"
      // landeten) hier sinnvoll unterkommen, ohne den Firestore-Wert zu
      // ändern (bleibt "theater_comedy" für Bestandsdaten).
      case EventCategory.theaterComedy:
        return "Kultur & Bühne";
      // ✅ NEU
      case EventCategory.sonstiges:
        return "Sonstiges";
      case EventCategory.fuehrung:
        return "Führung";
      case EventCategory.workshop:
        return "Workshop & Vortrag";
      // ✅ NEU
      case EventCategory.kunst:
        return "Kunst & Ausstellung";
      case EventCategory.natur:
        return "Natur & Wandern";
      case EventCategory.kino:
        return "Kino";
      case EventCategory.treffen:
        return "Treffen & Gruppen";
    }
  }

  String get emoji {
    switch (this) {
      case EventCategory.schuetzenfest:
        return "🎯";
      case EventCategory.konzert:
        return "🎵";
      case EventCategory.festival:
        return "🎪";
      case EventCategory.stadtfest:
        return "🏰";
      case EventCategory.markt:
        return "🛍️";
      case EventCategory.food:
        return "🍔";
      case EventCategory.sport:
        return "⚽";
      case EventCategory.familie:
        return "👨‍👩‍👧";
      case EventCategory.theaterComedy:
        return "🎭";
      case EventCategory.sonstiges:
        return "📌";
      case EventCategory.fuehrung:
        return "🧭";
      case EventCategory.workshop:
        return "🧑‍🏫";
      // ✅ NEU
      case EventCategory.kunst:
        return "🎨";
      case EventCategory.natur:
        return "🥾";
      case EventCategory.kino:
        return "🎬";
      case EventCategory.treffen:
        return "👥";
    }
  }

  Color get color {
    switch (this) {
      case EventCategory.schuetzenfest:
        return Colors.green;
      case EventCategory.konzert:
        return Colors.blue;
      case EventCategory.festival:
        return Colors.purple;
      case EventCategory.stadtfest:
        return Colors.orange;
      case EventCategory.markt:
        return Colors.amber;
      case EventCategory.food:
        return Colors.red;
      case EventCategory.sport:
        return Colors.teal;
      case EventCategory.familie:
        return Colors.pink;
      case EventCategory.theaterComedy:
        return Colors.indigo;
      case EventCategory.sonstiges:
        return Colors.blueGrey;
      case EventCategory.fuehrung:
        return Colors.brown;
      case EventCategory.workshop:
        return Colors.cyan;
      // ✅ NEU
      case EventCategory.kunst:
        return Colors.deepPurple;
      case EventCategory.natur:
        return Colors.lightGreen.shade800;
      case EventCategory.kino:
        return Colors.deepOrange;
      case EventCategory.treffen:
        return Colors.lightBlue;
    }
  }

  IconData get icon {
    switch (this) {
      case EventCategory.schuetzenfest:
        return Icons.track_changes_rounded;
      case EventCategory.konzert:
        return Icons.music_note_rounded;
      case EventCategory.festival:
        return Icons.celebration_rounded;
      case EventCategory.stadtfest:
        return Icons.location_city_rounded;
      case EventCategory.markt:
        return Icons.storefront_rounded;
      case EventCategory.food:
        return Icons.restaurant_rounded;
      case EventCategory.sport:
        return Icons.sports_soccer_rounded;
      case EventCategory.familie:
        return Icons.family_restroom_rounded;
      case EventCategory.theaterComedy:
        return Icons.theater_comedy_rounded;
      case EventCategory.sonstiges:
        return Icons.event_rounded;
      case EventCategory.fuehrung:
        return Icons.explore_rounded;
      case EventCategory.workshop:
        return Icons.school_rounded;
      // ✅ NEU
      case EventCategory.kunst:
        return Icons.palette_rounded;
      case EventCategory.natur:
        return Icons.hiking_rounded;
      case EventCategory.kino:
        return Icons.movie_rounded;
      case EventCategory.treffen:
        return Icons.groups_rounded;
    }
  }

  // ✅ Tier 4: Optionaler Hinweistext. Nur "sonstiges" trägt einen –
  // damit im UI ehrlich kommuniziert wird, dass hier Events landen, die
  // sich aus den Quelldaten (Titel/Kategorie) nicht sicher zuordnen ließen.
  // In event_detail_screen.dart / der Filterleiste anzeigen, wenn nicht null.
  String? get hint {
    if (this == EventCategory.sonstiges) {
      return "Diese Veranstaltung ließ sich anhand der vorliegenden "
          "Quelldaten keiner festen Kategorie zuordnen.";
    }
    return null;
  }

  // ✅ Muss exakt dem Firestore-Wert aus normalizeCategory() entsprechen
  String get firestoreValue {
    if (this == EventCategory.theaterComedy) return "theater_comedy";
    return name;
  }

  static EventCategory? fromString(String value) {
    if (value == "theater_comedy") return EventCategory.theaterComedy;

    try {
      return EventCategory.values.firstWhere(
        (e) => e.name == value,
      );
    } catch (_) {
      return null;
    }
  }
}