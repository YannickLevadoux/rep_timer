import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/group_type.dart';
import '../utils/group_summary.dart';
import '../utils/repetition_sequence_format.dart';

class GroupCardSubtitle extends StatelessWidget {
  const GroupCardSubtitle({
    super.key,
    required this.group,
    required this.hasFollowingGroup,
  });

  final ExerciseGroup group;
  final bool hasFollowingGroup;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    if (group.type == GroupType.tabata) {
      final summary = formatGroupSummary(
        group,
        hasFollowingGroup: hasFollowingGroup,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tabata', style: TextStyle(fontSize: 13, color: color)),
          Text(
            summary.replaceFirst('Tabata · ', ''),
            style: TextStyle(color: color),
          ),
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!group.type.isTimed)
          Text(group.type.label, style: TextStyle(fontSize: 13, color: color)),
        Text(
          group.type.isTimed
              ? formatGroupSummary(group, hasFollowingGroup: hasFollowingGroup)
              : group.type == GroupType.variableRepetitions
              ? formatRepetitionSequenceTourCount(group.repetitionSequence)
              : 'Répétitions : ${group.rounds}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color),
        ),
      ],
    );
  }
}
