import 'package:flutter/material.dart';

import '../services/monthly_history_aggregation.dart';
import 'monthly_history_bar_label.dart';
import 'monthly_history_status_segments.dart';

class MonthlyHistoryCountValue extends StatelessWidget {
  const MonthlyHistoryCountValue({
    super.key,
    required this.index,
    required this.bucket,
  });

  final int index;
  final MonthlyHistoryWeekBucket bucket;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        final incompleteHeight =
            totalHeight * bucket.incompleteCount / bucket.totalCount;
        final completedHeight = totalHeight - incompleteHeight;
        final incompleteText = '${bucket.incompleteCount}';
        final completedText = '${bucket.completedCount}';
        final incompleteLabelHeight = monthlyHistoryBarLabelHeight(
          context,
          incompleteText,
        );
        final completedLabelHeight = monthlyHistoryBarLabelHeight(
          context,
          completedText,
        );
        final positions = _labelPositions(
          incompleteHeight: incompleteHeight,
          completedHeight: completedHeight,
          incompleteLabelHeight: incompleteLabelHeight,
          completedLabelHeight: completedLabelHeight,
          incompleteFits:
              incompleteHeight >= incompleteLabelHeight + 2 &&
              constraints.maxWidth >=
                  monthlyHistoryBarLabelWidth(context, incompleteText),
          completedFits:
              completedHeight >= completedLabelHeight + 2 &&
              constraints.maxWidth >=
                  monthlyHistoryBarLabelWidth(context, completedText),
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: MonthlyHistoryStatusSegments(index: index, bucket: bucket),
            ),
            if (bucket.incompleteCount > 0)
              _label(
                status: 'incomplete',
                text: incompleteText,
                top: positions.incompleteTop!,
                height: incompleteLabelHeight,
                outside: positions.incompleteOutside,
              ),
            if (bucket.completedCount > 0)
              _label(
                status: 'completed',
                text: completedText,
                top: positions.completedTop!,
                height: completedLabelHeight,
                outside: positions.completedOutside,
              ),
          ],
        );
      },
    );
  }

  Positioned _label({
    required String status,
    required String text,
    required double top,
    required double height,
    required bool outside,
  }) {
    return Positioned(
      key: Key(
        'monthly-$status-label-${outside ? 'outside' : 'inside'}-$index',
      ),
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: MonthlyHistoryBarLabel(
        textKey: Key('monthly-$status-label-$index'),
        text: text,
      ),
    );
  }
}

_LabelPositions _labelPositions({
  required double incompleteHeight,
  required double completedHeight,
  required double incompleteLabelHeight,
  required double completedLabelHeight,
  required bool incompleteFits,
  required bool completedFits,
}) {
  final hasIncomplete = incompleteHeight > 0;
  final hasCompleted = completedHeight > 0;
  double? incompleteTop;
  double? completedTop;
  var incompleteOutside = false;
  var completedOutside = false;

  if (hasIncomplete) {
    incompleteTop = (incompleteHeight - incompleteLabelHeight) / 2;
  }
  if (hasCompleted) {
    completedTop =
        incompleteHeight + (completedHeight - completedLabelHeight) / 2;
  }
  if (hasIncomplete && !incompleteFits) {
    incompleteOutside = true;
    incompleteTop = -incompleteLabelHeight - 2;
  }
  if (hasCompleted && !completedFits) {
    completedOutside = true;
    completedTop = -completedLabelHeight - 2;
  }
  if (hasIncomplete && hasCompleted && !incompleteFits && !completedFits) {
    incompleteTop = -incompleteLabelHeight - completedLabelHeight - 4;
  } else if (hasIncomplete &&
      hasCompleted &&
      !incompleteFits &&
      completedHeight >= incompleteLabelHeight + completedLabelHeight + 6) {
    incompleteTop = incompleteHeight + 2;
    completedTop =
        incompleteHeight + completedHeight - completedLabelHeight - 2;
  } else if (hasIncomplete &&
      hasCompleted &&
      !completedFits &&
      incompleteHeight >= incompleteLabelHeight + completedLabelHeight + 6) {
    incompleteTop = 2;
    completedTop = incompleteHeight - completedLabelHeight - 2;
  }
  return _LabelPositions(
    incompleteTop: incompleteTop,
    completedTop: completedTop,
    incompleteOutside: incompleteOutside,
    completedOutside: completedOutside,
  );
}

class _LabelPositions {
  const _LabelPositions({
    required this.incompleteTop,
    required this.completedTop,
    required this.incompleteOutside,
    required this.completedOutside,
  });

  final double? incompleteTop;
  final double? completedTop;
  final bool incompleteOutside;
  final bool completedOutside;
}
