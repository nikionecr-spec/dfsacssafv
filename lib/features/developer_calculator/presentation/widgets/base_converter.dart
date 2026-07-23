import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/dev_tools.dart';

class BaseConverter extends StatefulWidget {
  const BaseConverter({super.key});

  @override
  State<BaseConverter> createState() => _BaseConverterState();
}

class _BaseConverterState extends State<BaseConverter> {
  final TextEditingController _controller = TextEditingController();
  int _radix = 10;
  int? _value;

  static const Map<String, int> _bases = <String, int>{
    'BIN': 2,
    'OCT': 8,
    'DEC': 10,
    'HEX': 16,
  };

  void _recompute() {
    setState(() => _value = DevTools.parse(_controller.text, _radix));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        SegmentedButton<int>(
          segments: <ButtonSegment<int>>[
            for (final MapEntry<String, int> e in _bases.entries)
              ButtonSegment<int>(value: e.value, label: Text(e.key)),
          ],
          selected: <int>{_radix},
          onSelectionChanged: (Set<int> value) {
            Haptics.selection();
            setState(() => _radix = value.first);
            _recompute();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _controller,
          autofocus: true,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]),
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => _recompute(),
          decoration: InputDecoration(
            hintText: 'Enter a ${_bases.keys.firstWhere((String k) => _bases[k] == _radix)} value',
            errorText: _controller.text.isNotEmpty && _value == null
                ? 'Invalid for selected base'
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ResultRow(
          label: 'Binary',
          value: _value == null
              ? '—'
              : DevTools.groupBinary(DevTools.toBase(_value!, 2)),
        ),
        _ResultRow(
          label: 'Octal',
          value: _value == null ? '—' : DevTools.toBase(_value!, 8),
        ),
        _ResultRow(
          label: 'Decimal',
          value: _value == null ? '—' : '$_value',
        ),
        _ResultRow(
          label: 'Hexadecimal',
          value: _value == null ? '—' : '0x${DevTools.toBase(_value!, 16)}',
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 96,
              child: Text(label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]),
                textAlign: TextAlign.right,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: value == '—'
                  ? null
                  : () {
                      Haptics.selection();
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied')),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
