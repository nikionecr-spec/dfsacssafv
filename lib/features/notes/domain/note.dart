import 'package:flutter/foundation.dart';

/// A user folder that groups notes.
@immutable
class Folder {
  const Folder({required this.id, required this.name, required this.createdAt});

  final String id;
  final String name;
  final DateTime createdAt;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Folder.fromMap(Map<String, Object?> m) => Folder(
        id: m['id']! as String,
        name: m['name']! as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
      );
}

/// A markdown note.
@immutable
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.pinned = false,
    this.color,
    this.dateLink,
    this.tags = const <String>[],
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? folderId;
  final bool pinned;
  final int? color;
  final DateTime? dateLink;
  final List<String> tags;

  /// A short plain-text-ish preview built from the body (first non-empty line
  /// after the title, with markdown noise trimmed).
  String get preview {
    for (final String line in body.split('\n')) {
      final String t = line
          .replaceAll(RegExp(r'[#>*_`\-\[\]!]'), '')
          .trim();
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  Note copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
    String? folderId,
    bool clearFolder = false,
    bool? pinned,
    int? color,
    bool clearColor = false,
    DateTime? dateLink,
    bool clearDateLink = false,
    List<String>? tags,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      pinned: pinned ?? this.pinned,
      color: clearColor ? null : (color ?? this.color),
      dateLink: clearDateLink ? null : (dateLink ?? this.dateLink),
      tags: tags ?? this.tags,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'title': title,
        'body': body,
        'folder_id': folderId,
        'pinned': pinned ? 1 : 0,
        'color': color,
        'date_link': dateLink?.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Note.fromMap(Map<String, Object?> m, {List<String> tags = const <String>[]}) {
    return Note(
      id: m['id']! as String,
      title: m['title']! as String,
      body: m['body']! as String,
      folderId: m['folder_id'] as String?,
      pinned: (m['pinned']! as int) == 1,
      color: m['color'] as int?,
      dateLink: m['date_link'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(m['date_link']! as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at']! as int),
      tags: tags,
    );
  }
}

/// A tag together with how many notes use it.
@immutable
class TagCount {
  const TagCount(this.tag, this.count);
  final String tag;
  final int count;
}
