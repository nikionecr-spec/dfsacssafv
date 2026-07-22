import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/id.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/note.dart';
import 'providers/notes_providers.dart';
import 'widgets/markdown_editing_controller.dart';

enum EditorMode { edit, split, preview }

class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, this.noteId});

  final String? noteId;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  final TextEditingController _title = TextEditingController();
  final MarkdownEditingController _body = MarkdownEditingController();
  final UndoHistoryController _undo = UndoHistoryController();
  final FocusNode _bodyFocus = FocusNode();

  EditorMode _mode = EditorMode.edit;
  bool _loading = true;
  bool _deleted = false;
  bool _pinned = false;
  int? _color;
  DateTime? _dateLink;
  String? _folderId;
  List<String> _tags = <String>[];

  late DateTime _createdAt;
  String? _existingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.noteId != null) {
      final Note? note =
          await ref.read(notesRepositoryProvider).getNote(widget.noteId!);
      if (note != null) {
        _existingId = note.id;
        _title.text = note.title;
        _body.text = note.body;
        _pinned = note.pinned;
        _color = note.color;
        _dateLink = note.dateLink;
        _folderId = note.folderId;
        _tags = List<String>.of(note.tags);
        _createdAt = note.createdAt;
      } else {
        _createdAt = DateTime.now();
      }
    } else {
      _createdAt = DateTime.now();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _undo.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_deleted) return;
    final String title = _title.text.trim();
    final String body = _body.text;
    if (title.isEmpty && body.trim().isEmpty) return; // nothing to persist
    final Note note = Note(
      id: _existingId ?? newId(),
      title: title,
      body: body,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      folderId: _folderId,
      pinned: _pinned,
      color: _color,
      dateLink: _dateLink,
      tags: _tags,
    );
    _existingId = note.id;
    await ref.read(notesControllerProvider).save(note);
  }

  // --- Markdown formatting helpers ------------------------------------------

  void _wrap(String left, String right) {
    Haptics.selection();
    final TextEditingValue value = _body.value;
    final TextSelection sel = value.selection;
    final String text = value.text;
    if (!sel.isValid) {
      _body.text = '$text$left$right';
      return;
    }
    final String selected = sel.textInside(text);
    final String next = sel.textBefore(text) + left + selected + right + sel.textAfter(text);
    final int base = sel.start + left.length;
    _body.value = TextEditingValue(
      text: next,
      selection: TextSelection(baseOffset: base, extentOffset: base + selected.length),
    );
  }

  void _prefixLine(String prefix) {
    Haptics.selection();
    final TextEditingValue value = _body.value;
    final String text = value.text;
    final int pos = value.selection.isValid ? value.selection.start : text.length;
    int lineStart = pos;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    final String next = text.substring(0, lineStart) + prefix + text.substring(lineStart);
    _body.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: pos + prefix.length),
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateLink ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dateLink = picked);
  }

  Future<void> _editTags() async {
    final List<String>? result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TagEditorSheet(initial: _tags),
    );
    if (result != null) setState(() => _tags = result);
  }

  Future<void> _pickColor() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return GlassCard(
          blur: true,
          radius: AppRadii.xl,
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            alignment: WrapAlignment.center,
            children: <Widget>[
              _ColorDot(
                color: null,
                selected: _color == null,
                onTap: () {
                  setState(() => _color = null);
                  Navigator.pop(context);
                },
              ),
              for (final Color c in AppColors.palette)
                _ColorDot(
                  color: c,
                  selected: _color == c.toARGB32(),
                  onTap: () {
                    setState(() => _color = c.toARGB32());
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppSettings settings = ref.watch(settingsControllerProvider);
    final double scale = settings.editorTextScale;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? _) => _save(),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(_existingId == null ? 'New note' : 'Edit note'),
          actions: <Widget>[
            ValueListenableBuilder<UndoHistoryValue>(
              valueListenable: _undo,
              builder: (_, UndoHistoryValue v, __) => Row(
                children: <Widget>[
                  IconButton(
                    tooltip: 'Undo',
                    onPressed: v.canUndo ? _undo.undo : null,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  IconButton(
                    tooltip: 'Redo',
                    onPressed: v.canRedo ? _undo.redo : null,
                    icon: const Icon(Icons.redo_rounded),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'View mode',
              onPressed: () {
                Haptics.selection();
                setState(() {
                  _mode = EditorMode
                      .values[(_mode.index + 1) % EditorMode.values.length];
                });
              },
              icon: Icon(switch (_mode) {
                EditorMode.edit => Icons.edit_note_rounded,
                EditorMode.split => Icons.vertical_split_rounded,
                EditorMode.preview => Icons.visibility_rounded,
              }),
            ),
            _overflowMenu(),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                    child: TextField(
                      controller: _title,
                      style: theme.textTheme.headlineSmall,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  _metadataBar(theme),
                  const Divider(height: 1),
                  Expanded(child: _editorArea(theme, scale)),
                  if (_mode != EditorMode.preview) _toolbar(theme),
                ],
              ),
      ),
    );
  }

  Widget _editorArea(ThemeData theme, double scale) {
    final Widget editor = _EditorField(
      controller: _body,
      undo: _undo,
      focusNode: _bodyFocus,
      textScale: scale,
    );
    final Widget preview = _Preview(data: _body, textScale: scale);

    switch (_mode) {
      case EditorMode.edit:
        return editor;
      case EditorMode.preview:
        return preview;
      case EditorMode.split:
        return Column(
          children: <Widget>[
            Expanded(child: editor),
            const Divider(height: 1),
            Expanded(child: preview),
          ],
        );
    }
  }

  Widget _metadataBar(ThemeData theme) {
    final CalendarSystem system = ref
        .watch(settingsControllerProvider.select((AppSettings s) => s.calendarSystem));
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: <Widget>[
          ActionChip(
            avatar: const Icon(Icons.local_offer_outlined, size: 16),
            label: Text(_tags.isEmpty ? 'Tags' : _tags.map((String t) => '#$t').join(' ')),
            onPressed: _editTags,
          ),
          const SizedBox(width: AppSpacing.sm),
          ActionChip(
            avatar: const Icon(Icons.event_outlined, size: 16),
            label: Text(_dateLink == null
                ? 'Link date'
                : DateX.format(_dateLink!, system)),
            onPressed: _pickDate,
          ),
          if (_dateLink != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 16),
              onPressed: () => setState(() => _dateLink = null),
            ),
          const SizedBox(width: AppSpacing.sm),
          ActionChip(
            avatar: Icon(Icons.circle,
                size: 14, color: _color == null ? null : Color(_color!)),
            label: const Text('Color'),
            onPressed: _pickColor,
          ),
        ],
      ),
    );
  }

  Widget _toolbar(ThemeData theme) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          children: <Widget>[
            _ToolButton(icon: Icons.title_rounded, onTap: () => _prefixLine('# ')),
            _ToolButton(icon: Icons.format_bold_rounded, onTap: () => _wrap('**', '**')),
            _ToolButton(icon: Icons.format_italic_rounded, onTap: () => _wrap('_', '_')),
            _ToolButton(icon: Icons.code_rounded, onTap: () => _wrap('`', '`')),
            _ToolButton(icon: Icons.data_object_rounded, onTap: () => _wrap('\n```\n', '\n```\n')),
            _ToolButton(icon: Icons.format_list_bulleted_rounded, onTap: () => _prefixLine('- ')),
            _ToolButton(icon: Icons.checklist_rounded, onTap: () => _prefixLine('- [ ] ')),
            _ToolButton(icon: Icons.format_quote_rounded, onTap: () => _prefixLine('> ')),
            _ToolButton(icon: Icons.link_rounded, onTap: () => _wrap('[', '](url)')),
            _ToolButton(icon: Icons.image_outlined, onTap: () => _wrap('![', '](image_url)')),
            const VerticalDivider(width: 8, indent: 12, endIndent: 12),
            _ToolButton(
              icon: Icons.text_decrease_rounded,
              onTap: () => ref
                  .read(settingsControllerProvider.notifier)
                  .setEditorTextScale(ref.read(settingsControllerProvider).editorTextScale - 0.1),
            ),
            _ToolButton(
              icon: Icons.text_increase_rounded,
              onTap: () => ref
                  .read(settingsControllerProvider.notifier)
                  .setEditorTextScale(ref.read(settingsControllerProvider).editorTextScale + 0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overflowMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (String value) async {
        switch (value) {
          case 'pin':
            setState(() => _pinned = !_pinned);
          case 'delete':
            await _confirmDelete();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'pin',
          child: Row(children: <Widget>[
            Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
            const SizedBox(width: AppSpacing.md),
            Text(_pinned ? 'Unpin' : 'Pin'),
          ]),
        ),
        if (_existingId != null)
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(children: <Widget>[
              Icon(Icons.delete_outline_rounded),
              SizedBox(width: AppSpacing.md),
              Text('Delete'),
            ]),
          ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && _existingId != null) {
      _deleted = true;
      await ref.read(notesControllerProvider).delete(_existingId!);
      if (mounted) Navigator.of(context).pop();
    }
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.undo,
    required this.focusNode,
    required this.textScale,
  });

  final MarkdownEditingController controller;
  final UndoHistoryController undo;
  final FocusNode focusNode;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      undoController: undo,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * textScale,
        height: 1.5,
      ),
      decoration: const InputDecoration(
        hintText: 'Start writing in **markdown**…',
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.data, required this.textScale});

  final MarkdownEditingController data;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: data,
      builder: (BuildContext context, TextEditingValue value, _) {
        if (value.text.trim().isEmpty) {
          return Center(
            child: Text('Nothing to preview yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          );
        }
        return Markdown(
          data: value.text,
          padding: const EdgeInsets.all(AppSpacing.lg),
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            textScaler: TextScaler.linear(textScale),
            code: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            codeblockDecoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            blockquoteDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
        );
      },
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.selected, required this.onTap});
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color ?? scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: color == null
            ? Icon(Icons.block_rounded, color: scheme.onSurfaceVariant)
            : null,
      ),
    );
  }
}

class _TagEditorSheet extends StatefulWidget {
  const _TagEditorSheet({required this.initial});
  final List<String> initial;

  @override
  State<_TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends State<_TagEditorSheet> {
  late List<String> _tags = List<String>.of(widget.initial);
  final TextEditingController _controller = TextEditingController();

  void _add() {
    final String value = _controller.text.trim().replaceAll('#', '');
    if (value.isEmpty) return;
    if (!_tags.contains(value)) setState(() => _tags.add(value));
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
      ),
      child: GlassCard(
        blur: true,
        radius: AppRadii.xl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Tags', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                for (final String tag in _tags)
                  InputChip(
                    label: Text('#$tag'),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(hintText: 'Add a tag…'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  onPressed: _add,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _tags),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
