import 'package:flutter/material.dart';

import '../controllers/group_editor_controller.dart';
import '../models/group_type.dart';
import '../services/group_duration_estimator.dart';
import '../validation/business_validation.dart';
import 'compact_duration_tile.dart';
import 'estimated_duration_card.dart';
import 'rounds_editor.dart';
import 'tabata_effort_section.dart';
import 'timed_exercise_minutes_row.dart';
import 'timed_inline_duration_row.dart';
import 'timed_item_section.dart';

class TimedGroupEditor extends StatelessWidget {
  const TimedGroupEditor({
    super.key,
    required this.controller,
    required this.quick,
    required this.hasFollowingGroup,
    required this.onEditEffort,
    required this.onTabataCyclesChanged,
    required this.onEditTabataExercises,
    required this.onEditTabataRest,
    required this.onEditTabataFinalRest,
  });

  final GroupEditorController controller;
  final bool quick;
  final bool hasFollowingGroup;
  final VoidCallback onEditEffort;
  final ValueChanged<int> onTabataCyclesChanged;
  final VoidCallback onEditTabataExercises;
  final VoidCallback onEditTabataRest;
  final VoidCallback onEditTabataFinalRest;

  @override
  Widget build(BuildContext context) {
    final group = controller.group;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (group.type == GroupType.tabata) ..._tabata(context),
        if (group.type == GroupType.amrap) ..._amrap(context),
        if (group.type == GroupType.emom) ..._emom(context),
        EstimatedDurationCard(
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
      key: const Key('tabata-rounds-editor'),
      rounds: controller.tabataRounds,
      label: 'Nombre de tours',
      maximum: BusinessLimits.maximumTabataRounds,
      onChanged: controller.setTabataRounds,
    ),
    RoundsEditor(
      key: const Key('tabata-cycles-editor'),
      rounds: controller.tabataCycleCount,
      label: 'Nombre de cycles par tour',
      maximum: BusinessLimits.maximumCount,
      onChanged: onTabataCyclesChanged,
    ),
    TabataEffortSection(
      value: controller.group.tabataConfig!.effortDuration!,
      onChanged: controller.setEffortDuration,
      onEditExercises: onEditTabataExercises,
    ),
    CompactDurationTile(
      key: const Key('tabata-rest-row'),
      title: 'Pause entre les cycles',
      value: controller.group.items[1].duration!,
      onEdit: onEditTabataRest,
    ),
    const Divider(),
    if (controller.group.finalRestDuration == null)
      OutlinedButton.icon(
        key: const Key('add-tabata-final-rest'),
        onPressed: onEditTabataFinalRest,
        icon: const Icon(Icons.add),
        label: const Text('Personnaliser la dernière pause'),
      )
    else
      CompactDurationTile(
        key: const Key('tabata-final-rest-row'),
        title: 'Pause de fin de tour',
        value: controller.group.finalRestDuration!,
        onEdit: onEditTabataFinalRest,
        onDelete: controller.canDeleteTabataFinalRest
            ? () => controller.setFinalRestEnabled(false)
            : null,
      ),
  ];

  List<Widget> _amrap(BuildContext context) => [
    TimedExerciseDurationRow(
      key: const Key('amrap-effort-row'),
      item: controller.group.items.first,
      onEdit: onEditEffort,
      onChanged: controller.setEffortDuration,
      minimum: BusinessLimits.minimumAmrapDuration,
      maximum: BusinessLimits.maximumAmrapDuration,
      constrainPickerToBounds: true,
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
    TimedExerciseMinutesRow(
      key: const Key('emom-effort-row'),
      item: controller.group.items.first,
      minutes: controller.group.rounds,
      minimum: BusinessLimits.minimumCount,
      maximum: BusinessLimits.maximumEmomMinutes,
      onEdit: onEditEffort,
      onChanged: controller.setRounds,
    ),
    const Text(
      "L'exercice redémarre automatiquement au début de chaque minute.",
    ),
    const Divider(),
    if (!quick)
      _OptionalRest(
        title: 'Récupération',
        addLabel: "Ajouter une récupération après l'EMOM",
        value: controller.group.postGroupRestDuration,
        onEnabled: controller.setPostGroupRestEnabled,
        onChanged: controller.setPostGroupRestDuration,
        inline: true,
        inlineKey: const Key('emom-recovery-row'),
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
