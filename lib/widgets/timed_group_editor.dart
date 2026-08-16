import 'package:flutter/material.dart';

import '../controllers/group_editor_controller.dart';
import '../models/group_type.dart';
import '../services/group_duration_estimator.dart';
import '../validation/business_validation.dart';
import 'quick_tabata_sections.dart';
import 'rounds_editor.dart';
import 'timed_inline_duration_row.dart';
import 'timed_item_section.dart';

class TimedGroupEditor extends StatelessWidget {
  const TimedGroupEditor({
    super.key,
    required this.controller,
    required this.quick,
    required this.hasFollowingGroup,
    required this.onEditEffort,
  });

  final GroupEditorController controller;
  final bool quick;
  final bool hasFollowingGroup;
  final VoidCallback onEditEffort;

  @override
  Widget build(BuildContext context) {
    final group = controller.group;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (group.type == GroupType.tabata) ..._tabata(context),
        if (group.type == GroupType.amrap) ..._amrap(context),
        if (group.type == GroupType.emom) ..._emom(context),
        QuickTabataEstimatedDurationCard(
          duration: estimateGroupDuration(
            group,
            hasFollowingGroup: hasFollowingGroup,
          ),
        ),
      ],
    );
  }

  List<Widget> _tabata(BuildContext context) => [
    RoundsEditor(
      rounds: controller.group.rounds,
      label: 'Nombre de cycles',
      onChanged: controller.setRounds,
    ),
    TimedExerciseDurationRow(
      key: const Key('tabata-effort-row'),
      item: controller.group.items.first,
      onEdit: onEditEffort,
      onChanged: controller.setEffortDuration,
    ),
    const Divider(),
    TimedRestDurationRow(
      key: const Key('tabata-rest-row'),
      title: 'Pause',
      value: controller.group.items[1].duration!,
      onChanged: controller.setRequiredRestDuration,
    ),
    if (!quick) ...[
      const Divider(),
      _OptionalRest(
        title: 'Dernière pause',
        addLabel: 'Personnaliser la dernière pause',
        value: controller.group.finalRestDuration,
        onEnabled: controller.setFinalRestEnabled,
        onChanged: controller.setFinalRestDuration,
        inline: true,
      ),
    ],
  ];

  List<Widget> _amrap(BuildContext context) => [
    TimedExerciseDurationRow(
      key: const Key('amrap-effort-row'),
      item: controller.group.items.first,
      onEdit: onEditEffort,
      onChanged: controller.setEffortDuration,
      minimum: BusinessLimits.minimumAmrapDuration,
      maximum: BusinessLimits.maximumAmrapDuration,
    ),
    const Text('Enregistrez chaque tour terminé pendant le temps imparti.'),
    const Divider(),
    if (!quick)
      _OptionalRest(
        title: 'Récupération',
        addLabel: "Ajouter une récupération après l'AMRAP",
        value: controller.group.postGroupRestDuration,
        onEnabled: controller.setPostGroupRestEnabled,
        onChanged: controller.setPostGroupRestDuration,
        inline: true,
        inlineKey: const Key('amrap-recovery-row'),
      ),
  ];

  List<Widget> _emom(BuildContext context) => [
    RoundsEditor(
      rounds: controller.group.rounds,
      label: 'Nombre de minutes',
      maximum: BusinessLimits.maximumEmomMinutes,
      onChanged: controller.setRounds,
    ),
    const Text(
      "L'exercice redémarre automatiquement au début de chaque minute.",
    ),
    TimedExerciseSection(
      item: controller.group.items.first,
      onEdit: onEditEffort,
    ),
    const Divider(),
    if (!quick)
      _OptionalRest(
        title: 'Récupération',
        addLabel: "Ajouter une récupération après l'EMOM",
        value: controller.group.postGroupRestDuration,
        onEnabled: controller.setPostGroupRestEnabled,
        onChanged: controller.setPostGroupRestDuration,
      ),
  ];
}

class _OptionalRest extends StatelessWidget {
  const _OptionalRest({
    required this.title,
    required this.addLabel,
    required this.value,
    required this.onEnabled,
    required this.onChanged,
    this.inline = false,
    this.inlineKey,
  });

  final String title;
  final String addLabel;
  final Duration? value;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<Duration> onChanged;
  final bool inline;
  final Key? inlineKey;

  @override
  Widget build(BuildContext context) => value == null
      ? OutlinedButton.icon(
          onPressed: () => onEnabled(true),
          icon: const Icon(Icons.add),
          label: Text(addLabel),
        )
      : inline
      ? TimedRestDurationRow(
          key: inlineKey ?? const Key('tabata-final-rest-row'),
          title: title,
          value: value!,
          onChanged: onChanged,
          onDelete: () => onEnabled(false),
        )
      : TimedDurationSection(
          title: title,
          value: value!,
          onChanged: onChanged,
          onDelete: () => onEnabled(false),
        );
}
