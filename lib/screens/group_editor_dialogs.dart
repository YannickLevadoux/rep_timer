import 'package:flutter/material.dart';

import '../controllers/group_editor_controller.dart';
import '../models/group_type.dart';
import '../models/training_item.dart';
import '../services/app_settings_storage.dart';
import '../validation/business_validation.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/exercise_dialog.dart';
import '../widgets/dialogs/rest_dialog.dart';
import '../widgets/dialogs/repetition_sequence_dialog.dart';

class GroupEditorDialogs {
  GroupEditorDialogs(this.controller);

  final GroupEditorController controller;
  final AppSettingsStorage _settings = AppSettingsStorage();

  int get _repetitionFallback =>
      controller.group.repetitionSequence.firstOrNull ??
      BusinessLimits.minimumCount;

  Future<void> addExercise(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final prefill = await _settings.loadPrefillExerciseName();
    if (!context.mounted) return;
    final result = await showExerciseDialog(
      context,
      defaultName: prefill ? controller.name : '',
      repetitionsDefinedByGroup:
          controller.group.type == GroupType.variableRepetitions,
      repetitionFallback: _repetitionFallback,
    );
    if (result != null) controller.addItem(result);
  }

  Future<void> addRest(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final duration = await showRestDialog(context);
    if (duration == null) return;
    controller.addItem(
      TrainingItem(type: ItemType.rest, name: 'Pause', duration: duration),
    );
  }

  Future<void> editItem(BuildContext context, int index) async {
    FocusScope.of(context).unfocus();
    final item = controller.group.items[index];
    if (item.type == ItemType.rest) {
      final duration = await showRestDialog(
        context,
        initial: item.duration ?? Duration.zero,
      );
      if (duration != null) controller.updateRest(index, duration);
      return;
    }
    final result = await showExerciseDialog(
      context,
      initial: item,
      repetitionsDefinedByGroup:
          controller.group.type == GroupType.variableRepetitions,
      repetitionFallback: _repetitionFallback,
    );
    if (result != null) controller.updateExercise(index, result);
  }

  Future<void> editTimedExercise(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final result = await showExerciseDialog(
      context,
      initial: controller.group.items.first,
      timedOnly: true,
    );
    if (result != null) controller.updateTimedExercise(result);
  }

  Future<void> changeType(BuildContext context, GroupType target) async {
    FocusScope.of(context).unfocus();
    if (controller.requiresReplacementConfirmation(target)) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Changer de type de groupe ?',
        content: _replacementMessage(target),
        confirmLabel: 'Continuer',
        isDestructive: false,
      );
      if (!confirmed || !context.mounted) return;
    }
    controller.switchType(target);
  }

  Future<void> editRepetitionSequence(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final result = await showRepetitionSequenceDialog(
      context,
      initialValues: controller.group.repetitionSequence,
      fallbackValue: _repetitionFallback,
    );
    if (result != null) controller.setRepetitionSequence(result);
  }

  Future<void> deleteItem(BuildContext context, int index) async {
    final item = controller.group.items[index];
    final confirmed = await showConfirmDialog(
      context,
      title: item.type == ItemType.rest
          ? 'Supprimer la pause ?'
          : "Supprimer l'exercice ?",
      content: 'Supprimer "${item.name}" du groupe ?',
      confirmLabel: 'Supprimer',
    );
    if (confirmed && context.mounted) controller.removeItem(index);
  }

  String _replacementMessage(GroupType target) => switch (target) {
    GroupType.tabata =>
      'Les éléments affichés seront remplacés par Effort 20 s et Pause 10 s.',
    GroupType.amrap =>
      'Les éléments affichés seront remplacés par AMRAP, Effort et 02:00.',
    GroupType.emom =>
      'Les éléments affichés seront remplacés par EMOM, Effort et 10 minutes.',
    _ => 'Les éléments affichés seront remplacés par le brouillon sélectionné.',
  };
}
