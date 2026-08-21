import 'package:flutter/material.dart';

import '../controllers/pre_session_preparation_controller.dart';
import '../models/exercise_group.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import '../services/app_settings_storage.dart';
import '../services/session_notification_permission_service.dart';
import '../services/session_start_permission_gate.dart';
import '../utils/snack.dart';
import '../utils/validation_messages.dart';
import '../validation/business_validation.dart';
import '../widgets/pre_session_preparation_toggle.dart';
import '../widgets/training_summary_groups_list.dart';
import '../widgets/training_summary_statistics.dart';
import 'pre_session_preparation_flow.dart';
import 'training_session.dart';

/// Écran affiché quand l'utilisateur clique sur "Commencer" depuis
/// l'accueil : informations principales de la séance, puis un bouton
/// pour lancer réellement l'exécution.
class TrainingSummaryScreen extends StatefulWidget {
  final Training training;
  final SessionNotificationPermissionService? permissionService;
  final SessionPermissionPromptStorage? settingsStorage;
  final AppSettingsStorage? countdownStorage;

  const TrainingSummaryScreen({
    super.key,
    required this.training,
    this.permissionService,
    this.settingsStorage,
    this.countdownStorage,
  });

  @override
  State<TrainingSummaryScreen> createState() => _TrainingSummaryScreenState();
}

class _TrainingSummaryScreenState extends State<TrainingSummaryScreen> {
  late final PreSessionPreparationController _preparation;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _preparation =
        PreSessionPreparationController(
            countdownStorage: widget.countdownStorage,
            permissionStorage: widget.settingsStorage,
          )
          ..addListener(_preparationChanged)
          ..load();
  }

  @override
  void dispose() {
    _preparation
      ..removeListener(_preparationChanged)
      ..dispose();
    super.dispose();
  }

  void _preparationChanged() {
    if (mounted) setState(() {});
  }

  int _roundsOf(ExerciseGroup group) => group.executedRounds;

  Future<void> _start() async {
    if (_starting) return;
    final issues = BusinessValidation.validateTraining(widget.training);
    if (issues.isNotEmpty) {
      showSnack(
        context,
        'Impossible de lancer la séance : ${validationMessage(issues.first)}',
      );
      return;
    }
    setState(() => _starting = true);

    await _preparation.load();
    if (!mounted) return;

    await SessionStartPermissionGate(
      permissionService: widget.permissionService,
      settingsStorage: widget.settingsStorage,
      countdownStorage: _preparation.settingsStorage,
    ).prepare(context, widget.training);

    if (!mounted) return;
    setState(() => _starting = false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingSessionScreen(
          training: widget.training,
          preSessionCountdownSeconds: _preparation.effectiveSeconds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final training = widget.training;
    final validationIssues = BusinessValidation.validateTraining(training);
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
    final canStart =
        validationIssues.isEmpty &&
        training.groups.isNotEmpty &&
        totalItems > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          training.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
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
            Text(
              "Prêt ?",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),

            PreSessionPreparationToggle(
              seconds: _preparation.seconds,
              enabled: _preparation.enabled,
              onChanged: _preparation.loaded && !_starting
                  ? preSessionPreparationHandler(context, _preparation)
                  : null,
            ),
            const SizedBox(height: 4),

            Expanded(
              child: TrainingSummaryGroupsList(
                groups: training.groups,
                roundsOf: _roundsOf,
              ),
            ),

            const SizedBox(height: 16),

            if (validationIssues.isNotEmpty) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  'Séance invalide : '
                  '${validationMessage(validationIssues.first)}',
                  key: const Key('training-start-error'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 8),
            ],

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
