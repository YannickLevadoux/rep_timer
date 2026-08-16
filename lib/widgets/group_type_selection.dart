import 'package:flutter/material.dart';

import '../models/group_type.dart';
import 'group_types_help_button.dart';
import 'type_selector.dart';

class GroupTypeSelection extends StatelessWidget {
  const GroupTypeSelection({
    super.key,
    required this.value,
    required this.onChanged,
    this.showInitialMessage = false,
  });

  final GroupType? value;
  final ValueChanged<GroupType> onChanged;
  final bool showInitialMessage;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showInitialMessage) ...[
        const Text(
          'Sélectionnez un type de groupe pour commencer.',
          key: Key('group-type-empty-message'),
        ),
        const SizedBox(height: 12),
      ],
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TypeSelector(value: value, onChanged: onChanged),
          ),
          const SizedBox(width: 4),
          const GroupTypesHelpButton(),
        ],
      ),
    ],
  );
}
