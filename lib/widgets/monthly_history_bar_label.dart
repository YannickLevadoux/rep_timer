import 'package:flutter/material.dart';

class MonthlyHistoryBarLabel extends StatelessWidget {
  const MonthlyHistoryBarLabel({
    super.key,
    required this.textKey,
    required this.text,
  });

  final Key textKey;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface.withAlpha(230),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text(
              text,
              key: textKey,
              textAlign: TextAlign.center,
              style: monthlyHistoryBarLabelStyle(context),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle monthlyHistoryBarLabelStyle(BuildContext context) =>
    Theme.of(context).textTheme.labelSmall!.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.bold,
      height: 1,
    );

double monthlyHistoryBarLabelHeight(BuildContext context, String text) {
  return _monthlyHistoryBarLabelSize(context, text).height + 2;
}

double monthlyHistoryBarLabelWidth(BuildContext context, String text) {
  return _monthlyHistoryBarLabelSize(context, text).width + 8;
}

Size _monthlyHistoryBarLabelSize(BuildContext context, String text) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: monthlyHistoryBarLabelStyle(context)),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  return painter.size;
}
