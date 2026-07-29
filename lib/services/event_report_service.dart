import 'package:cloud_firestore/cloud_firestore.dart';

class EventReportService {
  static Future<void> submitReport({
    required String eventId,
    required String eventName,
    required String reason,
    required String details,
  }) async {
    await FirebaseFirestore.instance.collection('event_reports').add({
      'eventId': eventId,
      'eventName': eventName,
      'reason': reason,
      'details': details,
      'status': 'pending',
      'reportedAt': FieldValue.serverTimestamp(),
    });
  }
}