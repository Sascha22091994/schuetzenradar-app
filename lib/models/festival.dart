import 'package:cloud_firestore/cloud_firestore.dart';

class Festival {
  final String id;
  final String name;
  final String address;
  final DateTime startDate;
  final DateTime endDate;
  final bool isHighlight;

  final String music;
  final Map<String, String> musicDays;

  final String flyerUrl;
  final List<String> images;

  //--------------------------------------------------
  // ✅ LOCATION
  //--------------------------------------------------
  final double latitude;
  final double longitude;

  final String outfitHint;
  final String highlights;
  final String website;
  final String description;


  Festival({
    required this.id,
    required this.name,
    required this.address,
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

  //--------------------------------------------------
  // ✅ FROM MAP (FIXED)
  //--------------------------------------------------
  factory Festival.fromMap(Map<String, dynamic> data) {
    return Festival(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      isHighlight: data['isHighlight'] ?? false,



      //--------------------------------------------------
      // ✅ DATE FIX (WICHTIG!)
      //--------------------------------------------------
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


      //--------------------------------------------------
      // ✅ ROBUSTER LAT/LNG FIX
      //--------------------------------------------------
      latitude: _toDouble(data['latitude']),
      longitude: _toDouble(data['longitude']),

      outfitHint: data['outfitHint'] ?? '',
      highlights: data['highlights'] ?? '',
      website: data['website'] ?? '',
    );
  }

  //--------------------------------------------------
  // ✅ DATE HELPER (TIMESTAMP + STRING + FALLBACK)
  //--------------------------------------------------
  static DateTime _toDate(dynamic value) {
    if (value == null) return DateTime.now();

    // ✅ Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }

    // ✅ schon DateTime
    if (value is DateTime) {
      return value;
    }

    // ✅ String (alte Daten)
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }

  //--------------------------------------------------
  // ✅ HELPER: STRING / DOUBLE FIX
  //--------------------------------------------------
  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
}