class Location {
  final String id;
  final String name;
  final String instagram;
  final String website;
  final bool hasAdler;

  Location({
    required this.id,
    required this.name,
    required this.instagram,
    required this.website,
    required this.hasAdler,
  });

  factory Location.fromMap(String id, Map<String, dynamic> data) {
    return Location(
      id: id,
      name: data['name'] ?? '',
      instagram: data['instagram'] ?? '',
      website: data['website'] ?? '',
      hasAdler: data['hasAdler'] ?? false,
    );
  }
}