import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import 'contextual_help_button.dart';

class EstimatedDurationCard extends StatelessWidget {
  static const _durationStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  const EstimatedDurationCard({super.key, required this.duration});

  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final durationLabel = duration == null
        ? 'Non estimable'
        : formatDuration(duration!);
    final helpButton = const ContextualHelpButton(
      title: "À propos de l'estimation",
      tooltip: 'Informations sur la durée estimée',
      content: Text(
        "Cette estimation correspond à la durée programmée de "
        "la séance. Les pauses intermédiaires sont incluses. La dernière "
        "pause d'un groupe est incluse uniquement lorsqu'un autre groupe "
        "suit ; la dernière pause de la séance n'est pas exécutée. "
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
                        const Expanded(child: Text('Temps total estimé')),
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
                  children: [const Text('Temps total estimé'), helpButton],
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
    final minimumLabelWidth = textWidth('estimé', defaultStyle);
    final durationWidth = textWidth(
      durationLabel,
      defaultStyle.merge(_durationStyle),
    );
    final requiredWidth =
        minimumLabelWidth + helpButtonWidth + minimumSpacing + durationWidth;
    return requiredWidth <= availableWidth;
  }
}
