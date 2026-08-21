import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/exercise_icons.dart';
import '../validation/business_validation.dart';
import 'duration_minutes_seconds_picker.dart';
import 'exercise_form_controller.dart';
import 'exercise_icon_picker.dart';

/// Champs visuels du formulaire d'exercice.
class ExerciseForm extends StatelessWidget {
  const ExerciseForm({super.key, required this.controller});

  final ExerciseFormController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconSelector(controller: controller),
            const SizedBox(height: 16),
            TextField(
              controller: controller.nameController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: BusinessLimits.maximumNameCharacters,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              decoration: InputDecoration(
                labelText: 'Nom',
                errorText: controller.nameError,
              ),
            ),
            const SizedBox(height: 16),
            if (!controller.timedOnly) ...[
              DropdownButton<ExerciseInputMode>(
                value: controller.mode,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: ExerciseInputMode.repetitions,
                    child: Text('Répétitions'),
                  ),
                  DropdownMenuItem(
                    value: ExerciseInputMode.duration,
                    child: Text('Temps'),
                  ),
                  DropdownMenuItem(
                    value: ExerciseInputMode.freeDuration,
                    child: Text('Durée libre'),
                  ),
                ],
                onChanged: (value) => controller.setMode(value!),
              ),
              const SizedBox(height: 16),
              _ModeInput(controller: controller),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: controller.commentController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 2,
              maxLength: BusinessLimits.maximumCommentCharacters,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              decoration: InputDecoration(
                labelText: 'Commentaire (optionnel)',
                hintText: 'Poids, intensité...',
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                errorText: controller.commentError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconSelector extends StatelessWidget {
  const _IconSelector({required this.controller});

  final ExerciseFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () async {
            final chosen = await showExerciseIconPicker(
              context,
              currentIconName: controller.iconName,
            );
            if (chosen != null) controller.setIconName(chosen);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Icon(
              iconForExercise(controller.iconName),
              size: 32,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Toucher pour changer l'icône",
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ModeInput extends StatelessWidget {
  const _ModeInput({required this.controller});

  final ExerciseFormController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.mode) {
      ExerciseInputMode.duration => DurationMinutesSecondsPicker(
        value: controller.duration,
        onChanged: controller.setDuration,
      ),
      ExerciseInputMode.repetitions =>
        controller.repetitionsDefinedByGroup
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Nombre défini par la suite du groupe'),
              )
            : TextField(
                controller: controller.repetitionsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nombre de répétitions',
                  errorText: controller.repetitionsError,
                ),
              ),
      ExerciseInputMode.freeDuration => Text(
        "Aucun temps ni nombre de répétitions à définir : un chronomètre "
        "démarrera pendant la séance et vous déciderez vous-même de la fin "
        "de l'exercice.",
        style: Theme.of(context).textTheme.bodySmall,
      ),
    };
  }
}
