import 'package:cloud_firestore/cloud_firestore.dart';
import 'device_id_service.dart';

class EventRating {
  final String deviceId;
  final int stars;
  final String comment;
  final DateTime createdAt;

  EventRating({
    required this.deviceId,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });

  factory EventRating.fromMap(Map<String, dynamic> data, String id) {
    final ts = data['createdAt'];
    return EventRating(
      deviceId: id,
      stars: data['stars'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

class RatingService {
  static CollectionReference<Map<String, dynamic>> _ratingsRef(String eventId) {
    return FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('ratings');
  }

  //--------------------------------------------------
  static Future<void> submitRating({
    required String eventId,
    required int stars,
    required String comment,
  }) async {
    final deviceId = await DeviceIdService.getDeviceId();

    await _ratingsRef(eventId).doc(deviceId).set({
      'stars': stars,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  //--------------------------------------------------
  static Future<List<EventRating>> fetchRatings(String eventId) async {
    final snapshot = await _ratingsRef(eventId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => EventRating.fromMap(doc.data(), doc.id))
        .toList();
  }

  //--------------------------------------------------
  static Future<int?> fetchMyRating(String eventId) async {
    final deviceId = await DeviceIdService.getDeviceId();
    final doc = await _ratingsRef(eventId).doc(deviceId).get();

    if (!doc.exists) return null;
    return doc.data()?['stars'] as int?;
  }
}