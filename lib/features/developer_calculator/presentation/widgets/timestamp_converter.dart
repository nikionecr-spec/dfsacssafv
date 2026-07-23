import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/date_x.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/dev_tools.dart';

class TimestampConverter extends StatefulWidget {
  const TimestampConverter({super.key});

  @override
  State<TimestampConverter> createState() => _TimestampConverterState();
}

class _TimestampConverterState extends State<TimestampConverter> {
  final TextEditingController _controller = TextEditingController();
  bool _millis = false;
  DateTime? _result;

  void _recompute() {
    setState(() {
      _result = _millis
          ? DevTools.fromEpochMillis(_controller.text)
          : DevTools.fromEpochSeconds(_controller.text);
    });
  }

  void _now() {
    final DateTime now = DateTime.now();
    _controller.text = _millis
        ? '${now.millisecondsSinceEpoch}'
        : '${now.millisecondsSinceEpoch ~/ 1000}';
    _recompute();
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
        SegmentedButton<bool>(
          segments: const <ButtonSegment<bool>>[
            ButtonSegment<bool>(value: false, label: Text('Seconds')),
            ButtonSegment<bool>(value: true, label: Text('Millis')),
          ],
          selected: <bool>{_millis},
          onSelectionChanged: (Set<bool> value) {
            setState(() => _millis = value.first);
            _recompute();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => _recompute(),
          decoration: InputDecoration(
            hintText: 'Epoch timestamp',
            suffixIcon: TextButton(onPressed: _now, child: const Text('Now')),
          ),
          style: const TextStyle(
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _row(theme, 'Local',
                  _result == null ? '—' : _format(_result!.toLocal())),
              const SizedBox(height: AppSpacing.sm),
              _row(theme, 'UTC',
                  _result == null ? '—' : _format(_result!.toUtc())),
              const SizedBox(height: AppSpacing.sm),
              _row(theme, 'Jalali',
                  _result == null ? '—' : DateX.formatJalali(_result!.toLocal())),
              const SizedBox(height: AppSpacing.sm),
              _row(theme, 'Weekday',
                  _result == null ? '—' : _weekday(_result!.toLocal())),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(ThemeData theme, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(label,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyLarge),
          ),
        ],
      );

  String _format(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  String _weekday(DateTime d) => const <String>[
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
      ][d.weekday - 1];
}
