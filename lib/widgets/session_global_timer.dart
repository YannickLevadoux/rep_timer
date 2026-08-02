import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Affiche le libellé et la durée du chronomètre global de la séance.
class SessionGlobalTimer extends StatelessWidget {
  const SessionGlobalTimer({
    super.key,
    required this.width,
    required this.elapsed,
    required this.scale,
  });

  final double width;
  final Duration elapsed;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final color = theme.colorScheme.outline;

    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total',
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: (textTheme.labelSmall?.fontSize ?? 11) * scale,
              ),
            ),
            Text(
              formatDuration(elapsed),
              key: const Key('global-timer'),
              style: textTheme.titleMedium?.copyWith(
                color: color,
                fontSize: (textTheme.titleMedium?.fontSize ?? 16) * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
