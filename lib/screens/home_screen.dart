import 'package:flutter/material.dart';

import '../controllers/home_controller.dart';
import '../controllers/training_history_controller.dart';
import '../models/training.dart';
import '../services/app_settings_storage.dart';
import '../services/pending_session_recovery_service.dart';
import '../services/training_history_storage.dart';
import '../utils/snack.dart';
import '../utils/validation_messages.dart';
import '../widgets/dialogs/duplicate_training_dialog.dart';
import '../widgets/home_screen_view.dart';
import 'quick_session_screen.dart';
import 'settings_screen.dart';
import 'training_editor.dart';
import 'training_history.dart';
import 'training_session.dart';
import 'training_summary.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.controller,
    required this.recoveryService,
    required this.historyStorage,
    this.onThemeRestored,
    this.settingsStorage,
  });

  final ThemeMode themeMode;
  final Future<ThemeMode> Function() onToggleTheme;
  final HomeController controller;
  final PendingSessionRecoveryResolver recoveryService;
  final TrainingHistoryStore historyStorage;
  final ValueChanged<ThemeMode>? onThemeRestored;
  final AppSettingsStorage? settingsStorage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;
  late final PendingSessionRecoveryResolver _recoveryService;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller..loadTrainings();
    _recoveryService = widget.recoveryService;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _resumePendingSessionIfAny(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resumePendingSessionIfAny() async {
    final recovery = await _recoveryService.resolve();
    if (!mounted) return;

    _controller.applyRecoveryDecision(recovery);
    switch (recovery) {
      case PendingSessionRecoveryBlocked(:final validationIssue?):
        showSnack(
          context,
          'Reprise impossible : ${validationMessage(validationIssue)}',
        );
        return;
      case ResumePendingSession(:final training, :final checkpoint):
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrainingSessionScreen(
              training: training,
              initialCheckpoint: checkpoint,
            ),
          ),
        );
        if (mounted) _controller.loadTrainings();
      case NoPendingSession() || PendingSessionRecoveryBlocked():
        return;
    }
  }

  Future<void> _openEditor({Training? training}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingEditor(training: training),
      ),
    );
    if (saved == true) _controller.loadTrainings();
  }

  void _startTraining(Training training) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingSummaryScreen(training: training),
      ),
    );
  }

  Future<void> _duplicateTraining(Training training) async {
    final name = await showDuplicateTrainingDialog(
      context,
      originalName: training.name,
    );
    if (name == null || !mounted) return;

    final errorMessage = await _controller.duplicateTraining(training, name);
    if (mounted && errorMessage != null) showSnack(context, errorMessage);
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          themeMode: widget.themeMode,
          onToggleTheme: widget.onToggleTheme,
          onThemeRestored: widget.onThemeRestored,
          settingsStorage: widget.settingsStorage,
        ),
      ),
    );
    if (mounted) _controller.loadTrainings();
  }

  void _openDestination(int index) {
    final Widget? destination = switch (index) {
      1 => const QuickSessionScreen(),
      2 => TrainingHistoryScreen(
        controller: TrainingHistoryController(storage: widget.historyStorage),
      ),
      _ => null,
    };
    if (destination != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => HomeScreenView(
        trainings: _controller.trainings,
        expandedTrainingId: _controller.expandedTrainingId,
        status: _controller.status,
        actions: _controller.actions,
        onOpenSettings: _openSettings,
        onRetry: _controller.loadTrainings,
        onToggleExpanded: _controller.toggleExpanded,
        onDuplicate: _duplicateTraining,
        onEdit: (training) => _openEditor(training: training),
        onStart: _startTraining,
        onDestinationSelected: _openDestination,
        onCreate: _openEditor,
      ),
    );
  }
}
