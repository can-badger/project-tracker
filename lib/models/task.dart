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
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int,
      projectId: map['project_id'] as int,
      title: map['title'] ?? '',
      assignedTo: map['assigned_to'] as String?,
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      priority: map['priority'] as String?,
      activeStatus: map['active_status'] as String?,
      description: map['description'] as String?,
      isCompleted: map['is_completed'] as bool? ?? false,
    );
  }
}
