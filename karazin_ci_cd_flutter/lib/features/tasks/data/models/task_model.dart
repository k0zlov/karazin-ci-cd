class TaskModel({
  required final int id,
  required final String title,
  required final bool completed,
  required final DateTime createdAt,
  final String? description,
}) {
  factory fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      completed: json['completed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
