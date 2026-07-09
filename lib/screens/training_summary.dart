import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import 'training_session.dart';

/// Écran affiché quand l'utilisateur clique sur "Commencer" depuis
/// l'accueil : informations principales de la séance, puis un bouton
/// pour lancer réellement l'exécution.
class TrainingSummaryScreen extends StatelessWidget {
  final Training training;

  const TrainingSummaryScreen({super.key, required this.training});

  int _roundsOf(ExerciseGroup group) => group.rounds < 1 ? 1 : group.rounds;

  @override
  Widget build(BuildContext context) {
    final totalItems = training.groups.fold<int>(
      0,
      (sum, group) => sum + group.items.length * _roundsOf(group),
    );

    final exerciseCount = training.groups.fold<int>(
      0,
      (sum, group) =>
          sum +
          group.items.where((i) => i.type == ItemType.exercise).length *
              _roundsOf(group),
    );

    final restCount = totalItems - exerciseCount;
    final canStart = training.groups.isNotEmpty && totalItems > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(training.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      training.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.layers,
                      label: "Groupes",
                      value: "${training.groups.length}",
                    ),
                    _InfoRow(
                      icon: Icons.fitness_center,
                      label: "Exercices",
                      value: "$exerciseCount",
                    ),
                    _InfoRow(
                      icon: Icons.timer,
                      label: "Pauses",
                      value: "$restCount",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: training.groups.isEmpty
                  ? const Center(child: Text("Cette séance ne contient aucun groupe."))
                  : ListView.builder(
                      itemCount: training.groups.length,
                      itemBuilder: (context, index) {
                        final group = training.groups[index];
                        final exercises = group.items
                            .where((item) => item.type == ItemType.exercise)
                            .toList();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        group.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      "× ${_roundsOf(group)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (exercises.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    "Aucun exercice",
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ] else
                                  ...exercises.map(
                                    (exercise) => Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            iconForExercise(exercise.iconName),
                                            size: 18,
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              exercise.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text("Commencer"),
              onPressed: canStart
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TrainingSessionScreen(training: training),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}