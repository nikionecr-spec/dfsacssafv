import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/dev_tools.dart';

class ByteConverter extends StatefulWidget {
  const ByteConverter({super.key});

  @override
  State<ByteConverter> createState() => _ByteConverterState();
}

class _ByteConverterState extends State<ByteConverter> {
  final TextEditingController _controller = TextEditingController(text: '1');
  int _unitIndex = 2; // MB

  int get _bytes {
    final double v = double.tryParse(_controller.text.trim()) ?? 0;
    return DevTools.toBytes(v, _unitIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int bytes = _bytes;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Value'),
                style: const TextStyle(
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()]),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            DropdownButton<int>(
              value: _unitIndex,
              onChanged: (int? value) {
                if (value == null) return;
                Haptics.selection();
                setState(() => _unitIndex = value);
              },
              items: <DropdownMenuItem<int>>[
                for (int i = 0; i < DevTools.byteUnits.length; i++)
                  DropdownMenuItem<int>(
                      value: i, child: Text(DevTools.byteUnits[i])),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('= ${DevTools.humanBytes(bytes)}',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: theme.colorScheme.primary)),
              const Divider(height: AppSpacing.xl),
              _row(theme, 'Bytes', '$bytes'),
              _row(theme, 'Bits', '${bytes * 8}'),
              _row(theme, 'KB', (bytes / 1024).toStringAsFixed(3)),
              _row(theme, 'MB', (bytes / (1024 * 1024)).toStringAsFixed(4)),
              _row(theme, 'GB',
                  (bytes / (1024 * 1024 * 1024)).toStringAsFixed(6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(ThemeData theme, String label, String value) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 64,
              child: Text(label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontFeatures: <FontFeature>[
                        FontFeature.tabularFigures()
                      ])),
            ),
          ],
        ),
      );
}
