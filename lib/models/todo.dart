enum TodoStatus { pending, inProgress, done }

extension TodoStatusExtension on TodoStatus {
  String get label {
    switch (this) {
      case TodoStatus.pending:
        return 'Pending';
      case TodoStatus.inProgress:
        return 'In Progress';
      case TodoStatus.done:
        return 'Done';
    }
  }

  String get value {
    switch (this) {
      case TodoStatus.pending:
        return 'pending';
      case TodoStatus.inProgress:
        return 'in_progress';
      case TodoStatus.done:
        return 'done';
    }
  }

  static TodoStatus fromValue(String value) {
    switch (value) {
      case 'in_progress':
        return TodoStatus.inProgress;
      case 'done':
        return TodoStatus.done;
      default:
        return TodoStatus.pending;
    }
  }
}

class Todo {
  final int? id; // nullable — null until inserted into DB
  String title;
  String description;
  TodoStatus status;
  final DateTime createdAt;

  Todo({
    this.id,
    required this.title,
    required this.description,
    required this.status,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    TodoStatus? status,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      status: TodoStatusExtension.fromValue(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
