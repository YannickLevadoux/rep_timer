import 'package:flutter/material.dart';

class TimedInlinePickerRow extends StatelessWidget {
  const TimedInlinePickerRow({
    super.key,
    required this.title,
    required this.picker,
    required this.basePickerWidth,
    this.leading,
    this.action,
  });

  static const double _minimumLeadingWidth = 80;

  final String title;
  final Widget picker;
  final double basePickerWidth;
  final Widget? leading;
  final Widget? action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final naturalPickerWidth =
          basePickerWidth + (textScale - 1).clamp(0, 2) * 24;
      final pickerWidth = (constraints.maxWidth - _minimumLeadingWidth).clamp(
        0.0,
        naturalPickerWidth,
      );
      return Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ?action,
              ],
            ),
          ),
          SizedBox(
            width: pickerWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: SizedBox(width: naturalPickerWidth, child: picker),
            ),
          ),
        ],
      );
    },
  );
}
