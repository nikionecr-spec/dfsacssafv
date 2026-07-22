import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/dev_tools.dart';

class BitwiseCalculator extends StatefulWidget {
  const BitwiseCalculator({super.key});

  @override
  State<BitwiseCalculator> createState() => _BitwiseCalculatorState();
}

enum _Op { and, or, xor, shl, shr }

class _BitwiseCalculatorState extends State<BitwiseCalculator> {
  final TextEditingController _a = TextEditingController(text: '12');
  final TextEditingController _b = TextEditingController(text: '10');
  _Op _op = _Op.and;

  int get _av => DevTools.parse(_a.text, 10) ?? 0;
  int get _bv => DevTools.parse(_b.text, 10) ?? 0;

  int get _result => switch (_op) {
        _Op.and => DevTools.and(_av, _bv),
        _Op.or => DevTools.or(_av, _bv),
        _Op.xor => DevTools.xor(_av, _bv),
        _Op.shl => DevTools.shiftLeft(_av, _bv),
        _Op.shr => DevTools.shiftRight(_av, _bv),
      };

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _operand('A', _a)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _operand('B', _b)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          children: <Widget>[
            for (final ({_Op op, String label}) entry in const <({_Op op, String label})>[
              (op: _Op.and, label: 'AND'),
              (op: _Op.or, label: 'OR'),
              (op: _Op.xor, label: 'XOR'),
              (op: _Op.shl, label: '<< SHL'),
              (op: _Op.shr, label: '>> SHR'),
            ])
              ChoiceChip(
                label: Text(entry.label),
                selected: _op == entry.op,
                onSelected: (_) {
                  Haptics.selection();
                  setState(() => _op = entry.op);
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('NOT A = ${DevTools.not(_av)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.sm),
              Text('Result', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Text('$_result',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: theme.colorScheme.primary)),
              const Divider(height: AppSpacing.xl),
              _line(theme, 'Binary', DevTools.groupBinary(DevTools.toBase(_result, 2))),
              _line(theme, 'Hex', '0x${DevTools.toBase(_result, 16)}'),
              _line(theme, 'Octal', DevTools.toBase(_result, 8)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _operand(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label),
      style: const TextStyle(
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()]),
    );
  }

  Widget _line(ThemeData theme, String label, String value) {
    return Padding(
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
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()])),
          ),
        ],
      ),
    );
  }
}
