
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsItem {
  final String title;
  final String text;
  final DateTime date;
  final bool isImportant;
  final bool isNew;

  NewsItem({
    required this.title,
    required this.text,
    required this.date,
    this.isImportant = false,
    this.isNew = false,
  });

  factory NewsItem.fromMap(Map<String, dynamic> data) {

    //--------------------------------------------------
    // ✅ DATE SAFE PARSING (MEGA WICHTIG)
    //--------------------------------------------------
    final rawDate = data['date'];

    DateTime parsedDate;

    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    //--------------------------------------------------
    // ✅ RETURN OBJECT
    //--------------------------------------------------
    return NewsItem(
      title: data['title'] ?? '',
      text: data['text'] ?? data['content'] ?? '',
      date: parsedDate,
      isImportant: data['isImportant'] ?? false,
      isNew: data['isNew'] ?? false,
    );
  }
}
