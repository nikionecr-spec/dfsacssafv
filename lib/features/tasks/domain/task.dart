import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum Priority {
  low(0, 'Low', AppColors.priorityLow),
  medium(1, 'Medium', AppColors.priorityMedium),
  high(2, 'High', AppColors.priorityHigh);

  const Priority(this.level, this.label, this.color);
  final int level;
  final String label;
  final Color color;

  static Priority fromLevel(int level) =>
      Priority.values.firstWhere((Priority p) => p.level == level,
          orElse: () => Priority.medium);
}

enum TaskStatus {
  todo(0, 'To do'),
  inProgress(1, 'In progress'),
  done(2, 'Done');

  const TaskStatus(this.code, this.label);
  final int code;
  final String label;

  static TaskStatus fromCode(int code) =>
      TaskStatus.values.firstWhere((TaskStatus s) => s.code == code,
          orElse: () => TaskStatus.todo);
}

@immutable
class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.taskId,
    required this.text,
    this.done = false,
    this.position = 0,
  });

  final String id;
  final String taskId;
  final String text;
  final bool done;
  final int position;

  ChecklistItem copyWith({String? text, bool? done, int? position}) =>
      ChecklistItem(
        id: id,
        taskId: taskId,
        text: text ?? this.text,
        done: done ?? this.done,
        position: position ?? this.position,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'task_id': taskId,
        'text': text,
        'done': done ? 1 : 0,
        'position': position,
      };

  factory ChecklistItem.fromMap(Map<String, Object?> m) => ChecklistItem(
        id: m['id']! as String,
        taskId: m['task_id']! as String,
        text: m['text']! as String,
        done: (m['done']! as int) == 1,
        position: m['position']! as int,
      );
}

@immutable
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.priority = Priority.medium,
    this.status = TaskStatus.todo,
    this.deadline,
    this.items = const <ChecklistItem>[],
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final Priority priority;
  final TaskStatus status;
  final DateTime? deadline;
  final List<ChecklistItem> items;

  bool get isDone => status == TaskStatus.done;

  bool get isOverdue =>
      deadline != null && !isDone && deadline!.isBefore(DateTime.now());

  /// Fraction of checklist items completed (0..1). Returns null when there is
  /// no checklist.
  double? get checklistProgress {
    if (items.isEmpty) return null;
    final int done = items.where((ChecklistItem i) => i.done).length;
    return done / items.length;
  }

  Task copyWith({
    String? title,
    String? notes,
    bool clearNotes = false,
    Priority? priority,
    TaskStatus? status,
    DateTime? deadline,
    bool clearDeadline = false,
    DateTime? updatedAt,
    List<ChecklistItem>? items,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: clearNotes ? null : (notes ?? this.notes),
      priority: priority ?? this.priority,
      status: status ?? this.status,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      items: items ?? this.items,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'title': title,
        'notes': notes,
        'priority': priority.level,
        'status': status.code,
        'deadline': deadline?.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Task.fromMap(Map<String, Object?> m,
          {List<ChecklistItem> items = const <ChecklistItem>[]}) =>
      Task(
        id: m['id']! as String,
        title: m['title']! as String,
        notes: m['notes'] as String?,
        priority: Priority.fromLevel(m['priority']! as int),
        status: TaskStatus.fromCode(m['status']! as int),
        deadline: m['deadline'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['deadline']! as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at']! as int),
        items: items,
      );
}
