class Todo {
  final int id;
  final String userId;
  final String title;
  final String? description;
  final DateTime? endDate;
  final bool isCompleted;

  Todo({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.endDate,
    required this.isCompleted,
  });

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      title: map['title'] ?? '',
      description: map['description'] as String?,
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'].toString()) : null,
      isCompleted: map['is_completed'] as bool? ?? false,
    );
  }
}
