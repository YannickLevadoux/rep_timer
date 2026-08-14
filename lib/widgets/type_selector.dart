import 'package:flutter/material.dart';

import '../models/group_type.dart';

/// Sélecteur compact partagé par les trois parcours d'édition.
class TypeSelector extends StatelessWidget {
  final GroupType value;
  final ValueChanged<GroupType> onChanged;

  const TypeSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Type du groupe',
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<GroupType>(
              value: value,
              isExpanded: true,
              isDense: true,
              items: GroupType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.shortLabel),
                    ),
                  )
                  .toList(),
              onChanged: (type) {
                if (type != null) onChanged(type);
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.description,
          key: const Key('group-type-description'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
