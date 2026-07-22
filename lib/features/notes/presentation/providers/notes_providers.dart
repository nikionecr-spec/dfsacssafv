import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/notes_repository.dart';
import '../../domain/note.dart';

final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => NotesRepository(ref.watch(databaseProvider)),
);

/// Active search query on the notes list.
final notesQueryProvider = StateProvider<String>((ref) => '');

/// Active tag filter (null == all).
final notesTagFilterProvider = StateProvider<String?>((ref) => null);

/// Active folder filter (null == all).
final notesFolderFilterProvider = StateProvider<String?>((ref) => null);

/// The filtered notes list. Recomputes whenever a filter changes.
final notesListProvider = FutureProvider.autoDispose<List<Note>>((ref) async {
  final String query = ref.watch(notesQueryProvider);
  final String? tag = ref.watch(notesTagFilterProvider);
  final String? folder = ref.watch(notesFolderFilterProvider);
  return ref.watch(notesRepositoryProvider).getNotes(
        query: query,
        tag: tag,
        folderId: folder,
      );
});

/// The five most recently updated notes, for the dashboard.
final recentNotesProvider = FutureProvider.autoDispose<List<Note>>(
  (ref) => ref.watch(notesRepositoryProvider).getNotes(limit: 5),
);

final allTagsProvider = FutureProvider.autoDispose<List<TagCount>>(
  (ref) => ref.watch(notesRepositoryProvider).allTags(),
);

final foldersProvider = FutureProvider.autoDispose<List<Folder>>(
  (ref) => ref.watch(notesRepositoryProvider).folders(),
);

/// Notes linked to a specific calendar day (used by the calendar feature).
final notesForDayProvider =
    FutureProvider.autoDispose.family<List<Note>, DateTime>(
  (ref, DateTime day) =>
      ref.watch(notesRepositoryProvider).getNotes(dateLink: day),
);

/// Imperative write API. Call these, then the affected list providers are
/// invalidated so the UI reloads from the source of truth.
class NotesController {
  NotesController(this.ref);
  final Ref ref;

  NotesRepository get _repo => ref.read(notesRepositoryProvider);

  Future<void> save(Note note) async {
    await _repo.upsertNote(note);
    _invalidate();
  }

  Future<void> togglePin(Note note) async {
    await _repo.setPinned(note.id, !note.pinned);
    _invalidate();
  }

  Future<void> delete(String id) async {
    await _repo.deleteNote(id);
    _invalidate();
  }

  Future<void> addFolder(Folder folder) async {
    await _repo.upsertFolder(folder);
    ref.invalidate(foldersProvider);
  }

  Future<void> deleteFolder(String id) async {
    await _repo.deleteFolder(id);
    ref.invalidate(foldersProvider);
    _invalidate();
  }

  void _invalidate() {
    ref.invalidate(notesListProvider);
    ref.invalidate(recentNotesProvider);
    ref.invalidate(allTagsProvider);
  }
}

final notesControllerProvider =
    Provider<NotesController>((ref) => NotesController(ref));
