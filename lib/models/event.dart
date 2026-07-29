import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final String address;
  final String city;
  final DateTime startDate;
  final DateTime endDate;
  final bool isHighlight;
  final String category;
  final String source;

  final String subcategory;
  final String ticketmasterGenre;
  final String ticketmasterSegment;

  final String music;
  final Map<String, String> musicDays;

  final String flyerUrl;
  final List<String> images;

  final double latitude;
  final double longitude;

  final String outfitHint;
  final String highlights;
  final String website;
  final String description;

  Event({
    required this.id,
    required this.name,
    required this.category,
    required this.source,
    required this.subcategory,
    required this.ticketmasterGenre,
    required this.ticketmasterSegment,
    required this.address,
    this.city = '',
    required this.startDate,
    required this.endDate,
    required this.music,
    this.musicDays = const {},
    required this.flyerUrl,
    required this.latitude,
    required this.longitude,
    required this.outfitHint,
    required this.highlights,
    required this.website,
    required this.images,
    required this.description,
    this.isHighlight = false,
  });

  factory Event.fromMap(Map<String, dynamic> data) {
    return Event(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'festival',
      source: data['source'] ?? '',
      subcategory: data['subcategory'] ?? '',
      ticketmasterGenre: data['ticketmasterGenre'] ?? '',
      ticketmasterSegment: data['ticketmasterSegment'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      isHighlight: data['isHighlight'] ?? false,

      startDate: _toDate(data['startDate']),
      endDate: _toDate(data['endDate']),

      music: data['music'] ?? '',

      musicDays: (data['musicDays'] is Map)
          ? (data['musicDays'] as Map).map(
              (key, value) =>
                  MapEntry(key.toString(), value.toString()),
            )
          : {},

      flyerUrl: data['flyerUrl'] ?? '',

      images: data['images'] != null
          ? List<String>.from(data['images'])
          : (data['flyerUrl'] != null && data['flyerUrl'] != ''
              ? [data['flyerUrl']]
              : []),
      description: data['description'] ?? '',

      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),

      outfitHint: data['outfitHint'] ?? '',
      highlights: data['highlights'] ?? '',
      website: data['website'] ?? '',
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}