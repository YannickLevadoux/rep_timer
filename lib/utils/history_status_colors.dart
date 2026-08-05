import 'package:flutter/material.dart';

Color completedHistoryColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? Colors.green.shade300
    : Colors.green.shade700;

Color incompleteHistoryColor(BuildContext context) =>
    Theme.of(context).colorScheme.tertiary;
