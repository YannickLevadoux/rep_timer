import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import '../services/app_settings_storage.dart';
import '../services/session_notification_permission_service.dart';
import '../services/session_start_permission_gate.dart';
import '../utils/exercise_icons.dart';
import 'training_session.dart';

/// Écran affiché quand l'utilisateur clique sur "Commencer" depuis
/// l'accueil : informations principales de la séance, puis un bouton
/// pour lancer réellement l'exécution.
class TrainingSummaryScreen extends StatefulWidget {
  final Training training;
  final SessionNotificationPermissionService? permissionService;
  final SessionPermissionPromptStorage? settingsStorage;

  const TrainingSummaryScreen({
    super.key,
    required this.training,
    this.permissionService,
    this.settingsStorage,
  });

  @override
  State<TrainingSummaryScreen> createState() => _TrainingSummaryScreenState();
}

class _TrainingSummaryScreenState extends State<TrainingSummaryScreen> {
  bool _starting = false;

  int _roundsOf(ExerciseGroup group) => group.rounds < 1 ? 1 : group.rounds;

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);

    await SessionStartPermissionGate(
      permissionService: widget.permissionService,
      settingsStorage: widget.settingsStorage,
    ).prepare(context, widget.training);

    if (!mounted) return;
    setState(() => _starting = false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingSessionScreen(training: widget.training),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final training = widget.training;
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
      appBar: AppBar(title: Text(training.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              key: const Key('training-summary-statistics'),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _StatisticsBadges(
                groupCount: training.groups.length,
                exerciseCount: exerciseCount,
                restCount: restCount,
              ),
            ),
            const SizedBox(height: 20),
            Text("Prêt ?", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Expanded(
              child: training.groups.isEmpty
                  ? const Center(
                      child: Text("Cette séance ne contient aucun groupe."),
                    )
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
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
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
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
              label: Text(_starting ? "Préparation…" : "Commencer"),
              onPressed: canStart && !_starting ? _start : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsBadges extends StatelessWidget {
  final int groupCount;
  final int exerciseCount;
  final int restCount;

  const _StatisticsBadges({
    required this.groupCount,
    required this.exerciseCount,
    required this.restCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatisticBadge(
            key: const Key('summary-groups-badge'),
            icon: Icons.layers,
            label: "Groupes",
            value: groupCount,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatisticBadge(
            key: const Key('summary-exercises-badge'),
            icon: Icons.fitness_center,
            label: "Exercices",
            value: exerciseCount,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatisticBadge(
            key: const Key('summary-rests-badge'),
            icon: Icons.timer,
            label: "Pauses",
            value: restCount,
          ),
        ),
      ],
    );
  }
}

class _StatisticBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _StatisticBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final description = "$label : $value";

    return Semantics(
      container: true,
      label: description,
      excludeSemantics: true,
      child: Tooltip(
        message: description,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 5),
                  Text(
                    "$value",
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
