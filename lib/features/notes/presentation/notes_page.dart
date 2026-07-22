import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/note.dart';
import 'note_editor_page.dart';
import 'providers/notes_providers.dart';
import 'widgets/note_card.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final TextEditingController _search = TextEditingController();
  final Debouncer _debouncer = Debouncer();

  @override
  void dispose() {
    _search.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _openEditor(Note? note) {
    Haptics.light();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => NoteEditorPage(noteId: note?.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CalendarSystem system = ref.watch(
        settingsControllerProvider.select((AppSettings s) => s.calendarSystem));
    final AsyncValue<List<Note>> notes = ref.watch(notesListProvider);
    final String? activeTag = ref.watch(notesTagFilterProvider);

    return AuraScaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(null),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New note'),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Text('Notes', style: theme.textTheme.headlineMedium),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (String value) => _debouncer.run(() {
                  ref.read(notesQueryProvider.notifier).state = value;
                }),
                decoration: InputDecoration(
                  hintText: 'Search notes…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            ref.read(notesQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _TagFilterBar(active: activeTag),
            Expanded(
              child: notes.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (Object e, _) => Center(child: Text('Error: $e')),
                data: (List<Note> items) {
                  if (items.isEmpty) {
                    return EmptyState(
                      icon: Icons.sticky_note_2_outlined,
                      title: 'No notes yet',
                      message:
                          'Capture ideas in markdown, tag them, and link them to your calendar.',
                      action: FilledButton.icon(
                        onPressed: () => _openEditor(null),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create your first note'),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 120),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (BuildContext context, int i) {
                      final Note note = items[i];
                      return NoteCard(
                        note: note,
                        system: system,
                        onTap: () => _openEditor(note),
                        onTogglePin: () {
                          Haptics.selection();
                          ref.read(notesControllerProvider).togglePin(note);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagFilterBar extends ConsumerWidget {
  const _TagFilterBar({required this.active});

  final String? active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TagCount>> tags = ref.watch(allTagsProvider);
    return tags.maybeWhen(
      data: (List<TagCount> items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: <Widget>[
              for (final TagCount t in items)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text('#${t.tag} · ${t.count}'),
                    selected: active == t.tag,
                    onSelected: (bool selected) {
                      Haptics.selection();
                      ref.read(notesTagFilterProvider.notifier).state =
                          selected ? t.tag : null;
                    },
                  ),
                ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
