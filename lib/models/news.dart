
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
    return NewsItem(
      title: data['title'] ?? '',
      text: data['content'] ?? '',
      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      isImportant: data['isImportant'] ?? false,
      isNew: data['isNew'] ?? false,
    );
  }
}