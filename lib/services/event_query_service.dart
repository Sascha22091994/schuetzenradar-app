import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventPage {
  final List<Event> events;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  EventPage({
    required this.events,
    required this.lastDoc,
    required this.hasMore,
  });
}

class EventQueryService {
  static final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('events');

  //--------------------------------------------------
  // ✅ Paginierte Abfrage für Listenansichten (Home Screen)
  //--------------------------------------------------
  static Future<EventPage> fetchPage({
    required DateTime? fromDate,
    required DateTime? toDate,
    Set<String> categories = const {},
    Set<String> cities = const {},
    int limit = 25,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    bool descending = false,
  }) async {
    Query<Map<String, dynamic>> query = _collection;

    if (fromDate != null) {
      query = query.where(
        'startDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
      );
    }

    if (toDate != null) {
      query = query.where(
        'startDate',
        isLessThanOrEqualTo: Timestamp.fromDate(toDate),
      );
    }

    if (categories.isNotEmpty && categories.length <= 30) {
      query = query.where('category', whereIn: categories.toList());
    } else if (cities.isNotEmpty && cities.length <= 30) {
      query = query.where('city', whereIn: cities.toList());
    }

    query = query.orderBy('startDate', descending: descending);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    query = query.limit(limit);

    final snapshot = await query.get();

    var events = snapshot.docs.map((doc) {
      return Event.fromMap({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList();

    if (categories.isNotEmpty && cities.isNotEmpty) {
      events = events.where((e) => cities.contains(e.city)).toList();
    }

    return EventPage(
      events: events,
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length == limit,
    );
  }

  //--------------------------------------------------
  // ✅ Highlights separat, klein und günstig
  //--------------------------------------------------
  static Future<List<Event>> fetchHighlights({int limit = 5}) async {
    final now = DateTime.now();

    final snapshot = await _collection
        .where('isHighlight', isEqualTo: true)
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('startDate')
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return Event.fromMap({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList();
  }

  //--------------------------------------------------
  // ✅ Zeitraum-Abfrage für Kalender/Karte, MIT Obergrenze
  //--------------------------------------------------
  static Future<List<Event>> fetchRange({
    required DateTime start,
    required DateTime end,
    Set<String> categories = const {},
    Set<String> cities = const {},
    int limit = 400, // ✅ harte Obergrenze statt "alles im Zeitraum"
  }) async {
    Query<Map<String, dynamic>> query = _collection
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(end));

    if (categories.isNotEmpty && categories.length <= 30) {
      query = query.where('category', whereIn: categories.toList());
    } else if (cities.isNotEmpty && cities.length <= 30) {
      query = query.where('city', whereIn: cities.toList());
    }

    query = query.orderBy('startDate').limit(limit);

    final snapshot = await query.get();

    if (snapshot.docs.length == limit) {
      // ignore: avoid_print
      print(
        'EventQueryService.fetchRange: Limit von $limit erreicht – '
        'es könnten weitere Events im Zeitraum existieren, die nicht geladen wurden.',
      );
    }

    var events = snapshot.docs.map((doc) {
      return Event.fromMap({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList();

    if (categories.isNotEmpty && cities.isNotEmpty) {
      events = events.where((e) => cities.contains(e.city)).toList();
    }

    return events;
  }

  //--------------------------------------------------
  // ✅ Gezielter Abruf per ID-Liste (für Favoriten – kein Voll-Scan)
  //--------------------------------------------------
  static Future<List<Event>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final results = <Event>[];

    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(
        i,
        i + 30 > ids.length ? ids.length : i + 30,
      );

      final snapshot = await _collection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      results.addAll(snapshot.docs.map((doc) {
        return Event.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
      }));
    }

    return results;
  }

  //--------------------------------------------------
  // ✅ Alle verfügbaren Städte (für Filter-Sheet), separat & günstig
  //--------------------------------------------------
  static Future<List<String>> fetchAvailableCities() async {
    final now = DateTime.now();

    final snapshot = await _collection
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('startDate')
        .limit(500)
        .get();

    final cities = snapshot.docs
        .map((doc) => doc.data()['city'] as String?)
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return cities;
  }
}