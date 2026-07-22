import 'package:flutter/foundation.dart';

@immutable
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.description,
    this.allDay = false,
    this.color,
    this.noteId,
    this.taskId,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? description;
  final bool allDay;
  final int? color;
  final String? noteId;
  final String? taskId;

  CalendarEvent copyWith({
    String? title,
    DateTime? start,
    DateTime? end,
    String? description,
    bool clearDescription = false,
    bool? allDay,
    int? color,
    bool clearColor = false,
    String? noteId,
    bool clearNote = false,
    String? taskId,
    bool clearTask = false,
  }) {
    return CalendarEvent(
      id: id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      description: clearDescription ? null : (description ?? this.description),
      allDay: allDay ?? this.allDay,
      color: clearColor ? null : (color ?? this.color),
      noteId: clearNote ? null : (noteId ?? this.noteId),
      taskId: clearTask ? null : (taskId ?? this.taskId),
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'title': title,
        'description': description,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
        'all_day': allDay ? 1 : 0,
        'color': color,
        'note_id': noteId,
        'task_id': taskId,
      };

  factory CalendarEvent.fromMap(Map<String, Object?> m) => CalendarEvent(
        id: m['id']! as String,
        title: m['title']! as String,
        description: m['description'] as String?,
        start: DateTime.fromMillisecondsSinceEpoch(m['start']! as int),
        end: DateTime.fromMillisecondsSinceEpoch(m['end']! as int),
        allDay: (m['all_day']! as int) == 1,
        color: m['color'] as int?,
        noteId: m['note_id'] as String?,
        taskId: m['task_id'] as String?,
      );
}
