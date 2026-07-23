import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/haptics.dart';
import '../../domain/dev_tools.dart';

class AsciiTable extends StatelessWidget {
  const AsciiTable({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<int> codes = DevTools.asciiCodes;
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        childAspectRatio: 1.4,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: codes.length,
      itemBuilder: (BuildContext context, int i) {
        final int code = codes[i];
        return InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () {
            Haptics.selection();
            Clipboard.setData(ClipboardData(text: '$code'));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied $code')),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  DevTools.asciiGlyph(code),
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]),
                ),
                const SizedBox(height: 2),
                Text('$code · 0x${DevTools.toBase(code, 16)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        );
      },
    );
  }
}
