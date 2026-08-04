import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import '../services/app_settings_storage.dart';
import '../services/session_notification_permission_service.dart';
import '../services/session_start_permission_gate.dart';
import '../widgets/training_summary_groups_list.dart';
import '../widgets/training_summary_statistics.dart';
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
              child: TrainingSummaryStatistics(
                groupCount: training.groups.length,
                exerciseCount: exerciseCount,
                restCount: restCount,
              ),
            ),
            const SizedBox(height: 20),
            Text("Prêt ?", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Expanded(
              child: TrainingSummaryGroupsList(
                groups: training.groups,
                roundsOf: _roundsOf,
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
