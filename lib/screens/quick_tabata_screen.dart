import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/quick_tabata_draft.dart';
import '../services/app_settings_storage.dart';
import '../services/session_notification_permission_service.dart';
import '../services/session_controller.dart';
import '../services/session_start_permission_gate.dart';
import '../utils/snack.dart';
import '../utils/validation_messages.dart';
import '../validation/business_validation.dart';
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
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _setRepetitions(int repetitions) {
    if (BusinessValidation.validateCount(
          repetitions,
          field: BusinessField.groupRounds,
        ) !=
        null) {
      return;
    }
    setState(() => _repetitions = repetitions);
  }

  String get _trainingName =>
      BusinessValidation.normalizeName(_nameController.text);

  QuickTabataDraft get _draft => QuickTabataDraft(
    name: _trainingName,
    workDuration: _workDuration,
    pauseDuration: _pauseDuration,
    rounds: _repetitions,
  );

  Future<void> _start() async {
    if (_starting) return;
    final quickTraining = _draft.build();
    final issues = BusinessValidation.validateTraining(quickTraining);
    if (issues.isNotEmpty) {
      final nameIssue = BusinessValidation.validateName(
        _nameController.text,
        field: BusinessField.quickTabataName,
      );
      setState(() {
        _nameError = nameIssue == null ? null : validationMessage(nameIssue);
      });
      if (nameIssue == null) {
        showSnack(context, validationMessage(issues.first));
      }
      return;
    }
    setState(() => _starting = true);

    // La séance lancée est construite par la même méthode que celle utilisée
    // pour l'estimation, afin que leurs structures restent alignées.
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
    final estimatedDuration = _draft.estimatedDuration;

    return Scaffold(
      appBar: AppBar(title: const Text("Quick Tabata")),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    maxLength: BusinessLimits.maximumNameCharacters,
                    maxLengthEnforcement: MaxLengthEnforcement.none,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "Nom de la séance",
                      errorText: _nameError,
                    ),
                  ),

                  const SizedBox(height: 12),

                  QuickTabataDurationSection(
                    title: "Work",
                    value: _workDuration,
                    onChanged: (duration) =>
                        setState(() => _workDuration = duration),
                  ),

                  const Divider(height: 10, thickness: 1),

                  QuickTabataDurationSection(
                    title: "Pause",
                    value: _pauseDuration,
                    onChanged: (duration) =>
                        setState(() => _pauseDuration = duration),
                  ),

                  const Divider(height: 10, thickness: 1),

                  RoundsEditor(
                    rounds: _repetitions,
                    onChanged: _setRepetitions,
                  ),

                  const SizedBox(height: 12),

                  QuickTabataEstimatedDurationCard(duration: estimatedDuration),

                  const SizedBox(height: 4),

                  FilledButton.icon(
                    onPressed: _starting ? null : _start,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_starting ? "Préparation…" : "Commencer"),
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
