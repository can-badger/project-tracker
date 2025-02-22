// lib/models/task.dart
class Task {
  final int id;
  final int projectId;
  final String title;
  final String? assignedTo;
  final DateTime? deadline;
  final String? priority;
  final String? activeStatus;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.assignedTo,
    this.deadline,
    this.priority,
    this.activeStatus,
    this.description,
    required this.isCompleted,
    required this.createdAt,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      projectId: map['project_id'],
      title: map['title'],
      assignedTo: map['assigned_to'],
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      priority: map['priority'],
      activeStatus: map['active_status'],
      description: map['description'],
      isCompleted: map['is_completed'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
