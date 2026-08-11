import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import 'contextual_help_button.dart';
import 'duration_minutes_seconds_picker.dart';

/// Section visuelle associant un titre au sélecteur de durée Quick Tabata.
class QuickTabataDurationSection extends StatelessWidget {
  final String title;
  final Duration value;
  final ValueChanged<Duration> onChanged;

  const QuickTabataDurationSection({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        IntrinsicWidth(
          child: DurationMinutesSecondsPicker(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Résumé visuel de la durée estimée et de son aide contextuelle.
class QuickTabataEstimatedDurationCard extends StatelessWidget {
  static const _durationStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  final Duration? duration;

  const QuickTabataEstimatedDurationCard({super.key, required this.duration});

  @override
  Widget build(BuildContext context) {
    final durationLabel = duration == null
        ? "Non estimable"
        : formatDuration(duration!);
    final helpButton = const ContextualHelpButton(
      title: "À propos de l'estimation",
      tooltip: "Informations sur la durée estimée",
      content: Text(
        "Cette estimation correspond à la durée programmée de "
        "la séance. Les pauses intermédiaires sont comptabilisées, "
        "mais la dernière pause de la séance n'est pas exécutée. "
        "Les pauses manuelles et la navigation pendant la séance "
        "ne sont pas incluses.",
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final durationText = Text(durationLabel, style: _durationStyle);
            if (_fitsInline(context, constraints.maxWidth, durationLabel)) {
              return Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Expanded(child: Text("Temps total estimé")),
                        helpButton,
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  durationText,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [const Text("Temps total estimé"), helpButton],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: durationText),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _fitsInline(
    BuildContext context,
    double availableWidth,
    String durationLabel,
  ) {
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final defaultStyle = DefaultTextStyle.of(context).style;

    double textWidth(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      return painter.width;
    }

    const helpButtonWidth = 48.0;
    const minimumSpacing = 12.0;
    final minimumLabelWidth = textWidth("estimé", defaultStyle);
    final durationWidth = textWidth(
      durationLabel,
      defaultStyle.merge(_durationStyle),
    );
    final requiredWidth =
        minimumLabelWidth + helpButtonWidth + minimumSpacing + durationWidth;
    return requiredWidth <= availableWidth;
  }
}
