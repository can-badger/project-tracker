// lib/models/project.dart
class Project {
  final int id;
  final String title;
  final String? description;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
