import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/session_step.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import '../services/app_settings_storage.dart';
import '../services/session_notification_permission_service.dart';
import '../services/session_controller.dart';
import '../services/session_start_permission_gate.dart';
import '../widgets/quick_tabata_sections.dart';
import '../widgets/rounds_editor.dart';
import 'training_session.dart';

/// Écran de préparation d'une séance "Quick Tabata" : permet de lancer
/// rapidement un cycle travail/pause répété, sans passer par la création
/// d'une séance classique. La séance générée n'est jamais persistée dans
/// le stockage local — elle n'existe que le temps de son exécution.
class QuickTabataScreen extends StatefulWidget {
  final SessionNotificationPermissionService? permissionService;
  final SessionPermissionPromptStorage? settingsStorage;

  const QuickTabataScreen({
    super.key,
    this.permissionService,
    this.settingsStorage,
  });

  @override
  State<QuickTabataScreen> createState() => _QuickTabataScreenState();
}

class _QuickTabataScreenState extends State<QuickTabataScreen> {
  static const String _defaultName = "Quick Tabata";

  final TextEditingController _nameController = TextEditingController(
    text: _defaultName,
  );

  Duration _workDuration = const Duration(seconds: 20);
  Duration _pauseDuration = const Duration(seconds: 10);
  int _repetitions = 1;
  bool _starting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _setRepetitions(int repetitions) {
    if (repetitions < 1) return;
    setState(() => _repetitions = repetitions);
  }

  String get _trainingName => _nameController.text.trim().isEmpty
      ? _defaultName
      : _nameController.text.trim();

  Training _buildQuickTraining() {
    // Valeur saisie, ou "Quick Tabata" si le champ a été vidé — couvre
    // aussi bien "jamais modifié" que "modifié puis effacé", sans jamais
    // bloquer l'utilisateur avec un message d'erreur pour un flux qui se
    // veut rapide.
    final name = _trainingName;

    final group = ExerciseGroup(
      id: 'quick_group_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      rounds: _repetitions,
      items: [
        TrainingItem(
          type: ItemType.exercise,
          name: "Work",
          duration: _workDuration,
        ),
        TrainingItem(
          type: ItemType.rest,
          name: "Pause",
          duration: _pauseDuration,
        ),
      ],
    );

    // Séance générée entièrement en mémoire : jamais écrite dans
    // TrainingStorage, donc jamais visible dans la liste des séances.
    return Training(
      id: 'quick_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      groups: [group],
      createdAt: DateTime.now(),
    );
  }

  Duration? get _estimatedDuration =>
      estimatePlannedDuration(_buildQuickTraining());

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);

    // La séance lancée est construite par la même méthode que celle utilisée
    // pour l'estimation, afin que leurs structures restent alignées.
    final quickTraining = _buildQuickTraining();

    await SessionStartPermissionGate(
      permissionService: widget.permissionService,
      settingsStorage: widget.settingsStorage,
    ).prepare(context, quickTraining);

    if (!mounted) return;
    setState(() => _starting = false);

    // Lance directement le moteur d'exécution existant, exactement comme
    // pour une séance classique — aucune logique spécifique ajoutée.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingSessionScreen(
          training: quickTraining,
          trainingChangesPersistence: TrainingChangesPersistence.memoryOnly,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimatedDuration = _estimatedDuration;

    return Scaffold(
      appBar: AppBar(title: const Text("Quick Tabata")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Nom de la séance",
              ),
            ),

            const SizedBox(height: 28),

            QuickTabataDurationSection(
              title: "Work",
              value: _workDuration,
              onChanged: (duration) => setState(() => _workDuration = duration),
            ),

            const SizedBox(height: 28),

            QuickTabataDurationSection(
              title: "Pause",
              value: _pauseDuration,
              onChanged: (duration) =>
                  setState(() => _pauseDuration = duration),
            ),

            const SizedBox(height: 28),

            RoundsEditor(rounds: _repetitions, onChanged: _setRepetitions),

            const SizedBox(height: 24),

            QuickTabataEstimatedDurationCard(duration: estimatedDuration),

            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed: _starting ? null : _start,
              icon: const Icon(Icons.play_arrow),
              label: Text(_starting ? "Préparation…" : "Commencer"),
            ),
          ],
        ),
      ),
    );
  }
}
