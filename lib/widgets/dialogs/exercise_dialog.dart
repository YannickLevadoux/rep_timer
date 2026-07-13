import 'package:flutter/material.dart';

import '../../models/training_item.dart';
import '../../utils/exercise_icons.dart';
import '../duration_minutes_seconds_picker.dart';
import '../exercise_icon_picker.dart';

/// Mode de saisie d'un exercice dans ce dialogue. Purement local à l'UI :
/// converti en (repetitions/duration/isFreeDuration) sur TrainingItem au
/// moment de la validation.
enum _ExerciseMode { repetitions, duration, freeDuration }

_ExerciseMode _modeOf(TrainingItem item) {
  if (item.isFreeDuration) return _ExerciseMode.freeDuration;
  if (item.duration != null) return _ExerciseMode.duration;
  return _ExerciseMode.repetitions;
}

/// Dialogue unique pour créer ou modifier un exercice.
///
/// - Mode création : laisser [initial] à `null`. [defaultName] préremplit
///   le nom (typiquement le nom du groupe parent) ; le titre affiche
///   "Nouvel exercice" et le bouton de validation "Ajouter".
/// - Mode édition : passer l'exercice existant dans [initial]. Le
///   dialogue s'ouvre pré-rempli, titre "Modifier l'exercice", bouton
///   "Valider".
///
/// Retourne le [TrainingItem] construit/mis à jour, ou `null` si annulé.
/// Ne modifie jamais [initial] directement : c'est à l'appelant de
/// reporter les champs du résultat sur l'exercice existant si besoin.
Future<TrainingItem?> showExerciseDialog(
  BuildContext context, {
  TrainingItem? initial,
  String defaultName = '',
}) {
  final isEditing = initial != null;

  final nameController = TextEditingController(
    text: initial?.name ?? defaultName,
  );
  _ExerciseMode mode = initial != null
      ? _modeOf(initial)
      : _ExerciseMode.repetitions;
  final valueController = TextEditingController(
    text: initial?.repetitions?.toString() ?? '',
  );
  Duration selectedDuration = initial?.duration ?? defaultExerciseDuration;
  final commentController = TextEditingController(text: initial?.comment ?? '');
  String selectedIconName = initial?.iconName ?? defaultExerciseIconName;

  return showDialog<TrainingItem>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? "Modifier l'exercice" : "Nouvel exercice"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: () async {
                        final chosen = await showExerciseIconPicker(
                          context,
                          currentIconName: selectedIconName,
                        );
                        if (chosen != null) {
                          setDialogState(() => selectedIconName = chosen);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                        child: Icon(
                          iconForExercise(selectedIconName),
                          size: 32,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Toucher pour changer l'icône",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Nom"),
                  ),

                  const SizedBox(height: 16),

                  DropdownButton<_ExerciseMode>(
                    value: mode,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: _ExerciseMode.repetitions,
                        child: Text("Répétitions"),
                      ),
                      DropdownMenuItem(
                        value: _ExerciseMode.duration,
                        child: Text("Temps"),
                      ),
                      DropdownMenuItem(
                        value: _ExerciseMode.freeDuration,
                        child: Text("Durée libre"),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => mode = value!);
                    },
                  ),

                  const SizedBox(height: 16),

                  if (mode == _ExerciseMode.duration)
                    DurationMinutesSecondsPicker(
                      value: selectedDuration,
                      onChanged: (d) =>
                          setDialogState(() => selectedDuration = d),
                    )
                  else if (mode == _ExerciseMode.repetitions)
                    TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Nombre de répétitions",
                      ),
                    )
                  else
                    // Durée libre : ni durée ni répétitions à saisir, le
                    // temps sera mesuré pendant l'exécution de la séance.
                    Text(
                      "Aucun temps ni nombre de répétitions à définir : "
                      "un chronomètre démarrera pendant la séance et "
                      "vous déciderez vous-même de la fin de l'exercice.",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Commentaire (optionnel)",
                      hintText: "Poids, intensité...",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              FilledButton(
                onPressed: () {
                  final comment = commentController.text.trim();

                  Navigator.pop(
                    context,
                    TrainingItem(
                      type: ItemType.exercise,
                      name: nameController.text,
                      repetitions: mode == _ExerciseMode.repetitions
                          ? int.tryParse(valueController.text)
                          : null,
                      duration: mode == _ExerciseMode.duration
                          ? selectedDuration
                          : null,
                      isFreeDuration: mode == _ExerciseMode.freeDuration,
                      comment: comment.isEmpty ? null : comment,
                      iconName: selectedIconName,
                    ),
                  );
                },
                child: Text(isEditing ? "Valider" : "Ajouter"),
              ),
            ],
          );
        },
      );
    },
  );
}
