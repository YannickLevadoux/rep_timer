import 'package:flutter/material.dart';

import '../utils/exercise_icons.dart';

/// Ouvre la galerie des icônes prédéfinies. Retourne le nom de l'icône
/// choisie, ou `null` si l'utilisateur a annulé (aucun changement).
Future<String?> showExerciseIconPicker(
  BuildContext context, {
  required String currentIconName,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Choisir une icône"),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: availableExerciseIcons.entries.map((entry) {
              final isSelected = entry.key == currentIconName;

              return InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () => Navigator.pop(context, entry.key),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Icon(
                    entry.value,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
        ],
      );
    },
  );
}
