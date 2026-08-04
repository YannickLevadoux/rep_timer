import 'package:flutter/material.dart';

/// Badge de présentation générique pour une statistique textuelle.
///
/// Le calcul et le formatage de la valeur restent à la charge de l'appelant.
class StatisticBadge extends StatelessWidget {
  const StatisticBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.description,
    this.foregroundColor,
    this.secondaryTextColor,
    this.borderColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String description;
  final Color? foregroundColor;
  final Color? secondaryTextColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedForegroundColor = foregroundColor;
    final resolvedSecondaryTextColor =
        secondaryTextColor ?? colorScheme.outline;
    final resolvedBorderColor = borderColor ?? colorScheme.outlineVariant;

    return Semantics(
      container: true,
      label: description,
      excludeSemantics: true,
      child: Tooltip(
        message: description,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: resolvedBorderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20, color: resolvedForegroundColor),
                      const SizedBox(width: 5),
                      Text(
                        value,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: resolvedForegroundColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: resolvedSecondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
